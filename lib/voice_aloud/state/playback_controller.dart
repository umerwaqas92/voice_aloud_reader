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

  static const int _maxChunkSize = 5000;
  static const int _minChunkSize = 1000;

  final Ref ref;
  final TtsService _tts;

  String? _currentDocumentId;
  List<_TextChunk> _chunks = [];
  int _currentChunkIndex = 0;
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
    if (state.wasCompleted && state.completedDocumentId == doc.id) {
      await play(doc, startOffset: 0);
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

    VoiceAloudSettings settings;
    try {
      settings = await ref.read(settingsControllerProvider.future);
    } catch (_) {
      settings =
          ref.read(settingsControllerProvider).valueOrNull ??
          VoiceAloudSettings.defaults;
    }
    if (applySettings) {
      await _applySettings(settings);
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    _currentDocumentId = doc.id;
    _chunks = _splitIntoChunks(doc.content);
    _currentChunkIndex = 0;

    if (bounded > 0) {
      for (var i = 0; i < _chunks.length; i++) {
        final chunk = _chunks[i];
        final chunkEnd = chunk.startOffset + chunk.text.length;
        if (bounded < chunkEnd) {
          _currentChunkIndex = i;
          final chunkText = doc.content.substring(bounded, chunkEnd);
          _chunks[i] = _TextChunk(text: chunkText, startOffset: bounded);
          break;
        }
      }
    }

    _lastPersistedOffset = bounded;
    _lastPersistAt = DateTime.now();

    state = state.copyWith(
      isPlaying: true,
      documentId: doc.id,
      baseOffset: bounded,
      currentOffset: bounded,
      highlightStart: null,
      highlightEnd: null,
      wasCompleted: false,
      completedDocumentId: null,
      lastError: null,
    );

    _setScreenOn(settings.keepScreenOn);
    unawaited(_playCurrentChunk());
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
    final locale = settings.voiceLocale.trim();
    final language = locale.isNotEmpty ? locale : settings.language;
    await _tts.setLanguage(language);
    if (settings.voiceName.trim().isNotEmpty) {
      await _tts.setVoiceByName(settings.voiceName, voiceLocale: locale);
    }
  }

  /// Re-applies the latest settings to the active playback (if any) and keeps
  /// the listener at the current offset.
  Future<void> reapplySettingsIfPlaying() async {
    if (!state.isPlaying || state.documentId == null) return;
    final doc = ref
        .read(documentsControllerProvider.notifier)
        .getById(state.documentId!);
    if (doc == null) return;

    final settings =
        ref.read(settingsControllerProvider).valueOrNull ??
        VoiceAloudSettings.defaults;
    await _applySettings(settings);
    await play(doc, startOffset: state.currentOffset);
  }

  void _onError(String message) {
    _setScreenOn(false);
    state = state.copyWith(isPlaying: false, lastError: message);
  }

  void _setScreenOn(bool enabled) {
    if (isInTest) return;
    unawaited(WakelockPlus.toggle(enable: enabled));
  }

  /// Applies latest settings and, if currently playing, resumes from current
  /// offset with the new voice/language settings.
  Future<void> applySettingsAndResume() async {
    final settings =
        ref.read(settingsControllerProvider).valueOrNull ??
        VoiceAloudSettings.defaults;

    final isPlayingNow = state.isPlaying && state.documentId != null;
    final docId = state.documentId;
    final currentOffset = state.currentOffset;

    _debouncedSeek?.cancel();
    await _tts.stop();

    if (isPlayingNow && docId != null) {
      final doc = ref.read(documentsControllerProvider.notifier).getById(docId);
      if (doc != null) {
        await _applySettings(settings);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await play(
          doc,
          startOffset: currentOffset,
          applySettings: false,
          stopBefore: false,
        );
      }
    } else {
      await _applySettings(settings);
    }
  }

  List<_TextChunk> _splitIntoChunks(String content) {
    if (content.length <= _maxChunkSize) {
      return [_TextChunk(text: content, startOffset: 0)];
    }

    final chunks = <_TextChunk>[];
    var remaining = content;
    var currentOffset = 0;

    while (remaining.isNotEmpty) {
      var chunkEnd = remaining.length;

      if (remaining.length > _minChunkSize) {
        chunkEnd = _findBestSplitPoint(remaining, _maxChunkSize);
      }

      final chunkText = remaining.substring(0, chunkEnd);
      chunks.add(_TextChunk(text: chunkText, startOffset: currentOffset));

      currentOffset += chunkEnd;
      remaining = remaining.substring(chunkEnd);
    }

    return chunks;
  }

  int _findBestSplitPoint(String text, int maxPos) {
    final candidates = ['\n\n', '\n', '. ', '! ', '? ', ', ', ' '];
    var bestPos = maxPos;

    for (final sep in candidates) {
      final lastSep = text.lastIndexOf(sep, maxPos - 1);
      if (lastSep > _minChunkSize) {
        bestPos = lastSep + sep.length;
        break;
      }
    }

    return bestPos;
  }

  Future<void> _playCurrentChunk() async {
    if (_chunks.isEmpty || _currentChunkIndex >= _chunks.length) {
      _onComplete();
      return;
    }

    final chunk = _chunks[_currentChunkIndex];
    _lastPersistedOffset = chunk.startOffset;
    _lastPersistAt = DateTime.now();

    await _tts.speak(chunk.text);
  }

  void _onProgress(String text, int start, int end, String word) {
    if (state.documentId == null || _currentDocumentId != state.documentId) {
      return;
    }

    final chunk =
        _chunks.isNotEmpty && _currentChunkIndex < _chunks.length
            ? _chunks[_currentChunkIndex]
            : null;
    final baseOffset = chunk?.startOffset ?? 0;

    final absStart = baseOffset + start;
    final absEnd = baseOffset + end;
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
    if (_chunks.isEmpty) {
      _finishPlayback();
      return;
    }

    if (_currentChunkIndex < _chunks.length - 1) {
      _currentChunkIndex++;
      unawaited(_playCurrentChunk());
    } else {
      _finishPlayback();
    }
  }

  void _finishPlayback() {
    _setScreenOn(false);
    _chunks = [];
    _currentChunkIndex = 0;
    _currentDocumentId = null;
    state = state.copyWith(
      isPlaying: false,
      highlightStart: null,
      highlightEnd: null,
      wasCompleted: true,
      completedDocumentId: state.documentId,
      lastError: null,
    );
  }
}

class _TextChunk {
  final String text;
  final int startOffset;

  const _TextChunk({required this.text, required this.startOffset});
}
