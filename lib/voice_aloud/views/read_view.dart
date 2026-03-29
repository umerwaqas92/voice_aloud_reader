import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../models/voice_aloud_settings.dart';
import '../state/providers.dart';
import '../va_tokens.dart';
import '../voice_aloud_tab.dart';
import '../widgets/animated_page_entrance.dart';
import '../widgets/blur_panel.dart';
import '../widgets/lucide_svg_icon.dart';
import '../widgets/voice_picker_sheet.dart';

class ReadView extends ConsumerWidget {
  const ReadView({
    super.key,
    required this.isPlaying,
    required this.showFontMenu,
    required this.onTogglePlaying,
    required this.onToggleFontMenu,
  });

  final bool isPlaying;
  final bool showFontMenu;
  final VoidCallback onTogglePlaying;
  final VoidCallback onToggleFontMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);
    final docs = ref.watch(documentsControllerProvider).valueOrNull ?? const [];
    final settings =
        ref.watch(settingsControllerProvider).valueOrNull ??
        VoiceAloudSettings.defaults;
    final playback = ref.watch(playbackControllerProvider);

    final doc = _findById(docs, appState.activeDocumentId);
    final offset =
        doc == null
            ? 0
            : (playback.documentId == doc.id
                ? playback.currentOffset
                : doc.lastReadOffset);

    final theme = settings.themeMode;
    final bgColor = VAColors.obsidian;
    final textColor = VAColors.cream.withValues(alpha: 0.85);
    final titleColor = VAColors.cream;
    final mutedColor = VAColors.muted;

    return AnimatedPageEntrance(
      child: ColoredBox(
        color: bgColor,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        _LuxuryCircleButton(
                          icon: LucideSvgIcon(
                            'chevron-left',
                            size: 24,
                            color: mutedColor,
                          ),
                          onTap: () async {
                            await ref
                                .read(playbackControllerProvider.notifier)
                                .stop();
                            ref
                                .read(appControllerProvider.notifier)
                                .setTab(VoiceAloudTab.library);
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              doc?.title ?? 'Read',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                                color: titleColor,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _LuxuryCircleButton(
                              icon: LucideSvgIcon(
                                'type',
                                size: 20,
                                color:
                                    showFontMenu ? VAColors.gold : mutedColor,
                              ),
                              backgroundColor:
                                  showFontMenu
                                      ? VAColors.gold.withValues(alpha: 0.15)
                                      : Colors.transparent,
                              onTap: onToggleFontMenu,
                            ),
                            const SizedBox(width: 4),
                            _LuxuryCircleButton(
                              icon: LucideSvgIcon(
                                'volume-2',
                                size: 20,
                                color: mutedColor,
                              ),
                              onTap: () => showVoicePickerSheet(context, ref),
                            ),
                            const SizedBox(width: 4),
                            _LuxuryCircleButton(
                              icon: LucideSvgIcon(
                                'list',
                                size: 20,
                                color: mutedColor,
                              ),
                              onTap:
                                  doc == null
                                      ? null
                                      : () => _showOutlineSheet(
                                        context,
                                        ref,
                                        doc,
                                        settings,
                                      ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (doc != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PROGRESS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.8,
                                  color: mutedColor,
                                ),
                              ),
                              Text(
                                '${_calculateProgress(doc, offset)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: VAColors.gold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _LuxuryProgressBar(
                            progress: _calculateProgress(doc, offset) / 100,
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child:
                            doc == null
                                ? const _NoDocumentSelected()
                                : _ReaderBody(
                                  document: doc,
                                  fontSize: settings.fontSize,
                                  titleColor: titleColor,
                                  textColor: textColor,
                                  isPlaying:
                                      playback.isPlaying &&
                                      playback.documentId == doc.id,
                                  highlightEnabled:
                                      settings.highlightSpokenText,
                                  autoScroll: settings.autoScroll,
                                  highlightStart:
                                      playback.documentId == doc.id
                                          ? playback.highlightStart
                                          : null,
                                  highlightEnd:
                                      playback.documentId == doc.id
                                          ? playback.highlightEnd
                                          : null,
                                  onParagraphTap:
                                      (startOffset) async => ref
                                          .read(
                                            playbackControllerProvider.notifier,
                                          )
                                          .seekTo(doc, startOffset),
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 80,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: showFontMenu ? 1 : 0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: showFontMenu ? 1 : 0.96,
                  child: IgnorePointer(
                    ignoring: !showFontMenu,
                    child: _FontMenu(
                      settings: settings,
                      onFontSizeChanged:
                          (size) => ref
                              .read(settingsControllerProvider.notifier)
                              .setFontSize(size),
                      onThemeChanged:
                          (mode) => ref
                              .read(settingsControllerProvider.notifier)
                              .setThemeMode(mode),
                    ),
                  ),
                ),
              ),
            ),
            if (doc != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _LuxuryBottomPlayer(
                  document: doc,
                  isPlaying: isPlaying,
                  currentOffset: offset,
                  speechRate: settings.speechRate,
                  onSpeedTap: () async {
                    const presets = <double>[0.8, 1.0, 1.2, 1.5, 2.0];
                    final current = settings.speechRate;
                    final exactIndex = presets.indexWhere(
                      (v) => (v - current).abs() < 0.01,
                    );
                    if (exactIndex != -1) {
                      final nextRate =
                          presets[(exactIndex + 1) % presets.length];
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .setSpeechRate(nextRate);
                      await ref
                          .read(playbackControllerProvider.notifier)
                          .applySettingsAndResume();
                      return;
                    }
                    final nextIndex = presets.indexWhere((v) => v > current);
                    final nextRate =
                        nextIndex == -1 ? presets.first : presets[nextIndex];
                    await ref
                        .read(settingsControllerProvider.notifier)
                        .setSpeechRate(nextRate);
                    await ref
                        .read(playbackControllerProvider.notifier)
                        .applySettingsAndResume();
                  },
                  voiceName: settings.voiceName,
                  onOpenVoicePicker: () => showVoicePickerSheet(context, ref),
                  onTogglePlaying: onTogglePlaying,
                  onSeek:
                      (fraction) async => ref
                          .read(playbackControllerProvider.notifier)
                          .seekTo(doc, (doc.content.length * fraction).round()),
                  onSkip:
                      (seconds) async => _skipBySeconds(
                        ref,
                        doc,
                        offset,
                        settings.speechRate,
                        seconds,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _calculateProgress(Document doc, int offset) {
    if (doc.content.isEmpty) return 0;
    return ((offset / doc.content.length) * 100).round().clamp(0, 100);
  }
}

class _NoDocumentSelected extends StatelessWidget {
  const _NoDocumentSelected();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Select a document from Library',
        style: TextStyle(fontWeight: FontWeight.w600, color: VAColors.muted),
      ),
    );
  }
}

class _ReaderBody extends StatelessWidget {
  const _ReaderBody({
    required this.document,
    required this.fontSize,
    required this.titleColor,
    required this.textColor,
    required this.isPlaying,
    required this.highlightEnabled,
    required this.autoScroll,
    required this.highlightStart,
    required this.highlightEnd,
    required this.onParagraphTap,
  });

  final Document document;
  final double fontSize;
  final Color titleColor;
  final Color textColor;
  final bool isPlaying;
  final bool highlightEnabled;
  final bool autoScroll;
  final int? highlightStart;
  final int? highlightEnd;
  final ValueChanged<int> onParagraphTap;

  @override
  Widget build(BuildContext context) {
    final paragraphs = _splitParagraphs(document.content);
    return _ReaderScrollView(
      documentId: document.id,
      title: document.title,
      paragraphs: paragraphs,
      fontSize: fontSize,
      titleColor: titleColor,
      textColor: textColor,
      isPlaying: isPlaying,
      highlightEnabled: highlightEnabled,
      autoScroll: autoScroll,
      highlightStart: highlightStart,
      highlightEnd: highlightEnd,
      onParagraphTap: onParagraphTap,
    );
  }
}

class _ReaderScrollView extends StatefulWidget {
  const _ReaderScrollView({
    required this.documentId,
    required this.title,
    required this.paragraphs,
    required this.fontSize,
    required this.titleColor,
    required this.textColor,
    required this.isPlaying,
    required this.highlightEnabled,
    required this.autoScroll,
    required this.highlightStart,
    required this.highlightEnd,
    required this.onParagraphTap,
  });

  final String documentId;
  final String title;
  final List<_Paragraph> paragraphs;
  final double fontSize;
  final Color titleColor;
  final Color textColor;
  final bool isPlaying;
  final bool highlightEnabled;
  final bool autoScroll;
  final int? highlightStart;
  final int? highlightEnd;
  final ValueChanged<int> onParagraphTap;

  @override
  State<_ReaderScrollView> createState() => _ReaderScrollViewState();
}

class _ReaderScrollViewState extends State<_ReaderScrollView> {
  final _scrollController = ScrollController();
  late List<GlobalKey> _paragraphKeys;

  int? _lastAutoScrolledParagraphStart;
  int? _lastHighlightStart;

  @override
  void initState() {
    super.initState();
    _paragraphKeys = List<GlobalKey>.generate(
      widget.paragraphs.length,
      (_) => GlobalKey(),
    );
  }

  @override
  void didUpdateWidget(covariant _ReaderScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.paragraphs.length != oldWidget.paragraphs.length ||
        widget.documentId != oldWidget.documentId) {
      _paragraphKeys = List<GlobalKey>.generate(
        widget.paragraphs.length,
        (_) => GlobalKey(),
      );
      _lastAutoScrolledParagraphStart = null;
      _lastHighlightStart = null;
    }

    final highlightStart = widget.highlightStart;
    final shouldAutoScroll =
        widget.autoScroll &&
        widget.highlightEnabled &&
        widget.isPlaying &&
        highlightStart != null;

    if (!shouldAutoScroll) return;
    if (highlightStart == _lastHighlightStart) return;
    _lastHighlightStart = highlightStart;

    final idx = _paragraphIndexForOffset(highlightStart);
    if (idx == null) return;

    final paragraphStart = widget.paragraphs[idx].startOffset;
    if (paragraphStart == _lastAutoScrolledParagraphStart) return;
    _lastAutoScrolledParagraphStart = paragraphStart;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _paragraphKeys[idx].currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.2,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  int? _paragraphIndexForOffset(int offset) {
    for (var i = 0; i < widget.paragraphs.length; i++) {
      final p = widget.paragraphs[i];
      final start = p.startOffset;
      final end = start + p.text.length;
      if (offset >= start && offset < end) return i;
    }
    return null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 200),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            widget.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 3.5,
              color: VAColors.gold,
            ),
          ),
          const SizedBox(height: 32),
          for (final entry in widget.paragraphs.indexed) ...[
            KeyedSubtree(
              key: _paragraphKeys[entry.$1],
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onParagraphTap(entry.$2.startOffset),
                child: _LuxuryDropCapParagraph(
                  text: entry.$2.text,
                  paragraphStartOffset: entry.$2.startOffset,
                  highlightEnabled: widget.highlightEnabled,
                  highlightStart: widget.highlightStart,
                  highlightEnd: widget.highlightEnd,
                  withDropCap: entry.$1 == 0,
                  fontSize: widget.fontSize,
                  textColor: widget.textColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LuxuryCircleButton extends StatelessWidget {
  const _LuxuryCircleButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor = Colors.transparent,
  });

  final Widget icon;
  final VoidCallback? onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Center(child: icon),
      ),
    );
  }
}

class _LuxuryProgressBar extends StatelessWidget {
  const _LuxuryProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: VAColors.gold,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _FontMenu extends StatelessWidget {
  const _FontMenu({
    required this.settings,
    required this.onFontSizeChanged,
    required this.onThemeChanged,
  });

  final VoiceAloudSettings settings;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<ReaderThemeMode> onThemeChanged;

  static const _small = 16.0;
  static const _large = 18.0;

  @override
  Widget build(BuildContext context) {
    final selectedSize = settings.fontSize;
    final theme = settings.themeMode;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VAColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VAColors.gold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FONT SIZE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: VAColors.muted,
                ),
              ),
              Row(
                children: [
                  _FontSizeButton(
                    text: 'A',
                    fontSize: 14,
                    selected:
                        (selectedSize - _small).abs() <
                        (selectedSize - _large).abs(),
                    onTap: () => onFontSizeChanged(_small),
                  ),
                  const SizedBox(width: 8),
                  _FontSizeButton(
                    text: 'A',
                    fontSize: 18,
                    selected:
                        (selectedSize - _large).abs() <=
                        (selectedSize - _small).abs(),
                    onTap: () => onFontSizeChanged(_large),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'THEME',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: VAColors.muted,
                ),
              ),
              Row(
                children: [
                  _ThemeButton(
                    color: VAColors.obsidian,
                    isSelected: theme == ReaderThemeMode.dark,
                    onTap: () => onThemeChanged(ReaderThemeMode.dark),
                  ),
                  const SizedBox(width: 8),
                  _ThemeButton(
                    color: const Color(0xFF1C1712),
                    isSelected: theme == ReaderThemeMode.light,
                    onTap: () => onThemeChanged(ReaderThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _ThemeButton(
                    color: VAColors.cream,
                    isSelected: theme == ReaderThemeMode.sepia,
                    onTap: () => onThemeChanged(ReaderThemeMode.sepia),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FontSizeButton extends StatelessWidget {
  const _FontSizeButton({
    required this.text,
    required this.fontSize,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final double fontSize;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color:
              selected
                  ? VAColors.gold.withValues(alpha: 0.15)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:
              selected
                  ? Border.all(color: VAColors.gold.withValues(alpha: 0.3))
                  : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color:
                  selected
                      ? VAColors.goldBright
                      : VAColors.cream.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isSelected
                    ? VAColors.gold
                    : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child:
            isSelected
                ? Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: VAColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
                : null,
      ),
    );
  }
}

class _LuxuryBottomPlayer extends StatelessWidget {
  const _LuxuryBottomPlayer({
    required this.document,
    required this.isPlaying,
    required this.currentOffset,
    required this.speechRate,
    required this.onSpeedTap,
    required this.voiceName,
    required this.onOpenVoicePicker,
    required this.onTogglePlaying,
    required this.onSkip,
    required this.onSeek,
  });

  final Document document;
  final bool isPlaying;
  final int currentOffset;
  final double speechRate;
  final VoidCallback onSpeedTap;
  final String voiceName;
  final VoidCallback onOpenVoicePicker;
  final VoidCallback onTogglePlaying;
  final ValueChanged<int> onSkip;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final progress =
        document.content.isEmpty
            ? 0.0
            : (currentOffset / document.content.length).clamp(0.0, 1.0);

    final totalSeconds = _estimateTotalSeconds(document.content, speechRate);
    final elapsedSeconds = (totalSeconds * progress).round();

    return Container(
      decoration: BoxDecoration(
        color: VAColors.voidColor.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: VAColors.gold.withValues(alpha: 0.15)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 60,
            offset: const Offset(0, -20),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LuxuryWaveform(isPlaying: isPlaying),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      _mmss(elapsedSeconds),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: VAColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final box = context.findRenderObject() as RenderBox;
                        final width = box.size.width - 80;
                        final localX = details.localPosition.dx.clamp(
                          0.0,
                          width,
                        );
                        onSeek(localX / width);
                      },
                      child: _LuxuryProgressBar(progress: progress),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 32,
                    child: Text(
                      _mmss(totalSeconds),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: VAColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SpeedButton(
                    speechRate: speechRate,
                    onTap: onSpeedTap,
                  ),
                  const SizedBox(width: 16),
                  _SkipButton(
                    iconName: 'skip-back',
                    label: '15s',
                    onTap: () => onSkip(-15),
                  ),
                  const SizedBox(width: 20),
                  _LuxuryPlayButton(
                    isPlaying: isPlaying,
                    onTap: onTogglePlaying,
                  ),
                  const SizedBox(width: 20),
                  _SkipButton(
                    iconName: 'skip-forward',
                    label: '15s',
                    onTap: () => onSkip(15),
                  ),
                  const SizedBox(width: 16),
                  _VoiceButton(
                    voiceName: voiceName,
                    onTap: onOpenVoicePicker,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LuxuryWaveform extends StatefulWidget {
  const _LuxuryWaveform({required this.isPlaying});

  final bool isPlaying;

  @override
  State<_LuxuryWaveform> createState() => _LuxuryWaveformState();
}

class _LuxuryWaveformState extends State<_LuxuryWaveform>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _LuxuryWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heights = [
      0.4,
      0.7,
      0.9,
      0.55,
      1.0,
      0.75,
      0.45,
      0.85,
      0.6,
      0.3,
      0.8,
      0.5,
      0.65,
      0.4,
      0.25,
    ];

    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(15, (index) {
          final baseHeight = heights[index] * 32;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = (_controller.value + index * 0.066) % 1.0;
              final wave =
                  widget.isPlaying
                      ? baseHeight *
                          (0.5 +
                              0.5 *
                                  (progress < 0.5
                                      ? progress * 2
                                      : 2 - progress * 2))
                      : baseHeight * 0.5;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 3,
                height: wave,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: VAColors.gold.withValues(alpha: 0.15 + index * 0.03),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow:
                      widget.isPlaying
                          ? [
                            BoxShadow(
                              color: VAColors.gold.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ]
                          : null,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.speechRate, required this.onTap});

  final double speechRate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: VAColors.gold.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: VAColors.gold.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, size: 13, color: VAColors.gold),
              const SizedBox(width: 4),
              Text(
                '${speechRate.toStringAsFixed(1)}x',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: VAColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({required this.voiceName, required this.onTap});

  final String voiceName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = voiceName.trim().isEmpty ? 'Voice' : voiceName.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: VAColors.gold.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: VAColors.gold.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LucideSvgIcon(
                'volume-2',
                size: 14,
                color: VAColors.gold,
                strokeWidth: 2,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 88),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: VAColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.iconName,
    required this.label,
    required this.onTap,
  });

  final String iconName;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LucideSvgIcon(
            iconName,
            size: 28,
            color: VAColors.cream,
            strokeWidth: 1.8,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: VAColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LuxuryPlayButton extends StatefulWidget {
  const _LuxuryPlayButton({required this.isPlaying, required this.onTap});

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  State<_LuxuryPlayButton> createState() => _LuxuryPlayButtonState();
}

class _LuxuryPlayButtonState extends State<_LuxuryPlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isPlaying) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _LuxuryPlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: VAColors.gold,
              shape: BoxShape.circle,
              boxShadow:
                  widget.isPlaying
                      ? [
                        BoxShadow(
                          color: VAColors.gold.withValues(
                            alpha: _pulseAnimation.value,
                          ),
                          blurRadius: 20 + (_pulseAnimation.value * 10),
                          spreadRadius: _pulseAnimation.value * 5,
                        ),
                      ]
                      : [
                        BoxShadow(
                          color: VAColors.gold.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child:
                    widget.isPlaying
                        ? Icon(
                          Icons.pause,
                          key: const ValueKey('pause'),
                          size: 26,
                          color: VAColors.obsidian,
                        )
                        : Icon(
                          Icons.play_arrow,
                          key: const ValueKey('play'),
                          size: 26,
                          color: VAColors.obsidian,
                        ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LuxuryDropCapParagraph extends StatelessWidget {
  const _LuxuryDropCapParagraph({
    required this.text,
    required this.paragraphStartOffset,
    required this.highlightEnabled,
    required this.highlightStart,
    required this.highlightEnd,
    required this.fontSize,
    required this.textColor,
    this.withDropCap = false,
  });

  final String text;
  final int paragraphStartOffset;
  final bool highlightEnabled;
  final int? highlightStart;
  final int? highlightEnd;
  final bool withDropCap;
  final double fontSize;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final paragraphStyle = TextStyle(
      fontSize: fontSize,
      height: 1.9,
      color: textColor,
    );

    if (!withDropCap || text.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          text,
          textAlign: TextAlign.justify,
          style: paragraphStyle.copyWith(
            color: textColor.withValues(alpha: 0.75),
          ),
        ),
      );
    }

    final first = text.substring(0, 1);
    final rest = text.substring(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(0, -4),
            child: Text(
              first,
              style: paragraphStyle.copyWith(
                fontSize: fontSize * 2.8,
                height: 0.8,
                fontWeight: FontWeight.w600,
                color: VAColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rest,
              textAlign: TextAlign.justify,
              style: paragraphStyle.copyWith(
                color: textColor.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Document? _findById(List<Document> docs, String? id) {
  if (id == null) return null;
  for (final d in docs) {
    if (d.id == id) return d;
  }
  return null;
}

class _Paragraph {
  const _Paragraph({required this.startOffset, required this.text});

  final int startOffset;
  final String text;
}

List<_Paragraph> _splitParagraphs(String content) {
  final normalized = content.replaceAll('\r\n', '\n');
  final parts = normalized.split(RegExp(r'\n\s*\n'));
  var offset = 0;

  final result = <_Paragraph>[];
  for (final raw in parts) {
    final text = raw.trim();
    final start = normalized.indexOf(raw, offset);
    if (text.isNotEmpty) {
      result.add(_Paragraph(startOffset: math.max(0, start), text: text));
    }
    offset = math.max(offset, start + raw.length);
  }
  return result;
}

int _estimateTotalSeconds(String content, double speechRate) {
  final words = content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final wordCount = words.length;
  if (wordCount == 0) return 0;

  final wpm = (160.0 * speechRate.clamp(0.5, 3.0)).clamp(80.0, 520.0);
  final total = (wordCount / (wpm / 60.0)).round();
  return total.clamp(1, 24 * 60 * 60);
}

String _mmss(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).clamp(0, 999);
  final seconds = (totalSeconds % 60).clamp(0, 59);
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

Future<void> _skipBySeconds(
  WidgetRef ref,
  Document doc,
  int currentOffset,
  double speechRate,
  int deltaSeconds,
) async {
  final totalSeconds = _estimateTotalSeconds(doc.content, speechRate);
  final len = doc.content.length;
  if (len == 0) return;

  final deltaChars =
      totalSeconds == 0
          ? (deltaSeconds.isNegative ? -600 : 600)
          : ((deltaSeconds / totalSeconds) * len).round();
  final next = (currentOffset + deltaChars).clamp(0, len).toInt();
  await ref.read(playbackControllerProvider.notifier).seekTo(doc, next);
}

Future<void> _showOutlineSheet(
  BuildContext context,
  WidgetRef ref,
  Document doc,
  VoiceAloudSettings settings,
) async {
  final paragraphs = _splitParagraphs(doc.content);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: VAColors.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: ListView.builder(
          itemCount: paragraphs.length,
          itemBuilder: (context, index) {
            final p = paragraphs[index];
            final snippet = p.text.replaceAll('\n', ' ').trim();
            final title =
                snippet.length <= 60 ? snippet : '${snippet.substring(0, 60)}…';
            return ListTile(
              title: Text(title, style: TextStyle(color: VAColors.cream)),
              onTap: () async {
                await ref
                    .read(playbackControllerProvider.notifier)
                    .seekTo(doc, p.startOffset);
                if (context.mounted) Navigator.of(context).pop();
              },
            );
          },
        ),
      );
    },
  );
}
