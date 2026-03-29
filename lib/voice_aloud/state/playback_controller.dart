import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/document.dart';
import '../models/voice_aloud_settings.dart';
import '../runtime_flags.dart';
import '../services/tts_service.dart';
import 'playback_state.dart';
import 'dependencies.dart';
import 'documents_controller.dart';
import 'settings_controller.dart';

final playbackControllerProvider =
    StateNotifierProvider<PlaybackController, PlaybackState>((ref) {
      final tts = ref.watch(ttsServiceProvider);
      return PlaybackController(ref, tts);
    });

class PlaybackController extends StateNotifier<PlaybackState> {
  PlaybackController(this.ref, this._tts) : super(PlaybackState.stopped) {
    _tts.setProgressHandler(_onProgress);
    _tts.setCompletionHandler(_onComplete);
    _tts.setErrorHandler(_onError);
  }

  final Ref ref;
  final TtsService _tts;

  int _lastPersistedOffset = 0;
  DateTime _lastPersistAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _debouncedSeek;

  @override
  void dispose() {
    _debouncedSeek?.cancel();
    super.dispose();
  }

  Future<void> stop() async {
    _debouncedSeek?.cancel();
    await _tts.stop();
    _setScreenOn(false);
    state = state.copyWith(
      isPlaying: false,
      highlightStart: null,
      highlightEnd: null,
      lastError: null,
    );
  }

  Future<void> toggle(Document doc) async {
    if (state.isPlaying && state.documentId == doc.id) {
      await stop();
      return;
    }
    await play(doc, startOffset: _effectiveOffsetFor(doc));
  }

  Future<void> play(
    Document doc, {
    required int startOffset,
    bool applySettings = true,
    bool stopBefore = true,
  }) async {
    final bounded = startOffset.clamp(0, doc.content.length);
    if (doc.content.isEmpty) {
      state = state.copyWith(lastError: 'Document is empty');
      return;
    }

    _debouncedSeek?.cancel();
    if (stopBefore) {
      await _tts.stop();
    }

    final settings =
        ref.read(settingsControllerProvider).valueOrNull ??
        VoiceAloudSettings.defaults;
    if (applySettings) {
      await _applySettings(settings);
      // Small settle to avoid audible glitch when switching voices quickly.
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    final text = doc.content.substring(bounded);
    _lastPersistedOffset = bounded;
    _lastPersistAt = DateTime.now();

    state = state.copyWith(
      isPlaying: true,
      documentId: doc.id,
      baseOffset: bounded,
      currentOffset: bounded,
      highlightStart: null,
      highlightEnd: null,
      lastError: null,
    );

    _setScreenOn(settings.keepScreenOn);
    unawaited(_tts.speak(text));
  }

  Future<void> seekTo(Document doc, int absoluteOffset) async {
    final bounded = absoluteOffset.clamp(0, doc.content.length);
    state = state.copyWith(currentOffset: bounded, lastError: null);
    await ref
        .read(documentsControllerProvider.notifier)
        .updateReadOffset(doc.id, bounded);

    if (!state.isPlaying || state.documentId != doc.id) return;

    _debouncedSeek?.cancel();
    _debouncedSeek = Timer(const Duration(milliseconds: 250), () async {
      await play(doc, startOffset: bounded);
    });
  }

  int _effectiveOffsetFor(Document doc) {
    if (state.documentId == doc.id) return state.currentOffset;
    return doc.lastReadOffset;
  }

  Future<void> _applySettings(VoiceAloudSettings settings) async {
    await _tts.setSpeechRate(settings.speechRate);
    await _tts.setPitch(settings.pitch);
    await _tts.setVolume(settings.volume);
    await _tts.setLanguage(settings.language);
    await _tts.setVoiceByName(
      settings.voiceName,
      voiceLocale: settings.voiceLocale,
    );
  }

  /// Re-applies the latest settings to the active playback (if any) and keeps
  /// the listener at the current offset.
  Future<void> reapplySettingsIfPlaying() async {
    if (!state.isPlaying || state.documentId == null) return;
    final doc =
        ref
            .read(documentsControllerProvider.notifier)
            .getById(state.documentId!);
    if (doc == null) return;

    final settings =
        ref.read(settingsControllerProvider).valueOrNull ??
        VoiceAloudSettings.defaults;
    await _applySettings(settings);
    await play(doc, startOffset: state.currentOffset);
  }

  void _onProgress(String text, int start, int end, String word) {
    if (state.documentId == null) return;
    final absStart = state.baseOffset + start;
    final absEnd = state.baseOffset + end;
    state = state.copyWith(
      currentOffset: absEnd,
      highlightStart: absStart,
      highlightEnd: absEnd,
      lastError: null,
    );

    final now = DateTime.now();
    final shouldPersist =
        (absEnd - _lastPersistedOffset).abs() >= 80 ||
        now.difference(_lastPersistAt).inMilliseconds >= 900;
    if (!shouldPersist) return;

    _lastPersistedOffset = absEnd;
    _lastPersistAt = now;

    final docId = state.documentId;
    if (docId == null) return;
    unawaited(
      ref
          .read(documentsControllerProvider.notifier)
          .updateReadOffset(docId, absEnd),
    );
  }

  void _onComplete() {
    _setScreenOn(false);
    state = state.copyWith(
      isPlaying: false,
      highlightStart: null,
      highlightEnd: null,
      lastError: null,
    );
  }

  void _onError(String message) {
    _setScreenOn(false);
    state = state.copyWith(isPlaying: false, lastError: message);
  }

  void _setScreenOn(bool enabled) {
    if (isInTest) return;
    unawaited(WakelockPlus.toggle(enable: enabled));
  }

  /// Applies latest settings (including voice) and, if currently playing,
  /// restarts from the same offset with minimal delay.
  Future<void> applyVoiceAndResume() async {
    final settings =
        ref.read(settingsControllerProvider).valueOrNull ??
        VoiceAloudSettings.defaults;

    final isPlayingNow = state.isPlaying && state.documentId != null;
    final docId = state.documentId;
    final currentOffset = state.currentOffset;

    _debouncedSeek?.cancel();
    await _tts.stop();
    await _applySettings(settings);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    if (!isPlayingNow || docId == null) return;
    final doc =
        ref
            .read(documentsControllerProvider.notifier)
            .getById(docId);
    if (doc == null) return;

    await play(
      doc,
      startOffset: currentOffset,
      applySettings: false,
      stopBefore: false,
    );
  }
}
