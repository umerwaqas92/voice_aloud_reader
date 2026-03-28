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
    final bgColor = switch (theme) {
      ReaderThemeMode.light => VAColors.readBackground,
      ReaderThemeMode.sepia => const Color(0xFFF4ECD8),
      ReaderThemeMode.dark => VAColors.gray900,
    };
    final textColor =
        theme == ReaderThemeMode.dark ? VAColors.gray100 : VAColors.gray800;
    final titleColor =
        theme == ReaderThemeMode.dark ? VAColors.gray50 : VAColors.gray900;
    final iconColor =
        theme == ReaderThemeMode.dark ? VAColors.gray100 : VAColors.gray600;

    return AnimatedPageEntrance(
      child: ColoredBox(
        color: bgColor,
        child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: LucideSvgIcon(
                          'chevron-left',
                          size: 24,
                          color: iconColor,
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
                          _CircleIconButton(
                            icon: LucideSvgIcon(
                              'type',
                              size: 20,
                              color:
                                  showFontMenu ? VAColors.blue600 : iconColor,
                            ),
                            backgroundColor:
                                showFontMenu
                                    ? VAColors.blue100
                                    : Colors.transparent,
                            onTap: onToggleFontMenu,
                          ),
                          const SizedBox(width: 4),
                          _CircleIconButton(
                            icon: LucideSvgIcon(
                              'list',
                              size: 20,
                              color: iconColor,
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
                                highlightEnabled: settings.highlightSpokenText,
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
            top: 64,
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
              child: _BottomPlayer(
                document: doc,
                isPlaying: isPlaying,
                currentOffset: offset,
                speechRate: settings.speechRate,
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
    ));
  }
}

class _NoDocumentSelected extends StatelessWidget {
  const _NoDocumentSelected();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Select a document from Library',
        style: TextStyle(fontWeight: FontWeight.w600, color: VAColors.gray500),
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 192),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            widget.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
              color: widget.titleColor,
            ),
          ),
          const SizedBox(height: 32),
          for (final entry in widget.paragraphs.indexed) ...[
            KeyedSubtree(
              key: _paragraphKeys[entry.$1],
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onParagraphTap(entry.$2.startOffset),
                child: _DropCapParagraph(
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
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
        ),
        child: Center(child: icon),
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
      width: 288,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VAColors.gray100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Font Size',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: VAColors.gray500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: VAColors.gray50,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    _FontSizeDot(
                      text: 'A',
                      fontSize: 14,
                      selected:
                          (selectedSize - _small).abs() <
                          (selectedSize - _large).abs(),
                      onTap: () => onFontSizeChanged(_small),
                    ),
                    _FontSizeDot(
                      text: 'A',
                      fontSize: 18,
                      selected:
                          (selectedSize - _large).abs() <=
                          (selectedSize - _small).abs(),
                      onTap: () => onFontSizeChanged(_large),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Theme',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: VAColors.gray500,
                ),
              ),
              Row(
                children: [
                  _ThemeDot(
                    color: Colors.white,
                    border: Border.all(
                      color:
                          theme == ReaderThemeMode.light
                              ? VAColors.blue500
                              : VAColors.gray300,
                      width: theme == ReaderThemeMode.light ? 2 : 1,
                    ),
                    onTap: () => onThemeChanged(ReaderThemeMode.light),
                  ),
                  const SizedBox(width: 12),
                  _ThemeDot(
                    color: const Color(0xFFF4ECD8),
                    border: Border.all(
                      color:
                          theme == ReaderThemeMode.sepia
                              ? VAColors.blue500
                              : VAColors.gray300,
                      width: theme == ReaderThemeMode.sepia ? 2 : 1,
                    ),
                    onTap: () => onThemeChanged(ReaderThemeMode.sepia),
                  ),
                  const SizedBox(width: 12),
                  _ThemeDot(
                    color: VAColors.gray900,
                    border: Border.all(
                      color:
                          theme == ReaderThemeMode.dark
                              ? VAColors.blue500
                              : VAColors.gray900,
                      width: theme == ReaderThemeMode.dark ? 2 : 1,
                    ),
                    onTap: () => onThemeChanged(ReaderThemeMode.dark),
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

class _FontSizeDot extends StatelessWidget {
  const _FontSizeDot({
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
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow:
              selected
                  ? const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: VAColors.gray800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeDot extends StatelessWidget {
  const _ThemeDot({
    required this.color,
    required this.border,
    required this.onTap,
  });

  final Color color;
  final BoxBorder border;
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
          border: border,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomPlayer extends StatelessWidget {
  const _BottomPlayer({
    required this.document,
    required this.isPlaying,
    required this.currentOffset,
    required this.speechRate,
    required this.onTogglePlaying,
    required this.onSkip,
    required this.onSeek,
  });

  final Document document;
  final bool isPlaying;
  final int currentOffset;
  final double speechRate;
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

    return BlurPanel(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(VASizes.bottomPanelRadius),
        topRight: Radius.circular(VASizes.bottomPanelRadius),
      ),
      sigma: 20,
      color: Colors.white.withValues(alpha: 0.8),
      border: const Border(top: BorderSide(color: Colors.white, width: 1)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 40,
          offset: Offset(0, -10),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    _mmss(elapsedSeconds),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VAColors.gray400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          final width = constraints.maxWidth;
                          final localX = details.localPosition.dx.clamp(
                            0.0,
                            width,
                          );
                          onSeek(localX / width);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 6,
                            color: VAColors.gray200,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: VAColors.blue600,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 40,
                  child: Text(
                    _mmss(totalSeconds),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VAColors.gray400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SkipButton(iconName: 'skip-back', onTap: () => onSkip(-15)),
                const SizedBox(width: 32),
                GestureDetector(
                  onTap: onTogglePlaying,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: VAColors.blue600,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D2563EB),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Transform.translate(
                        offset: isPlaying ? Offset.zero : const Offset(2, 0),
                        child: LucideSvgIcon(
                          isPlaying ? 'pause_filled' : 'play_filled',
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                _SkipButton(iconName: 'skip-forward', onTap: () => onSkip(15)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.iconName, required this.onTap});

  final String iconName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LucideSvgIcon(
              iconName,
              size: 32,
              color: VAColors.gray800,
              strokeWidth: 1.5,
            ),
            const SizedBox(height: 2),
            const Text(
              '15',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: VAColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropCapParagraph extends StatelessWidget {
  const _DropCapParagraph({
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
      height: 1.65,
      color: textColor,
    );
    final highlightStyle = paragraphStyle.copyWith(
      backgroundColor: VAColors.yellow300.withValues(alpha: 0.65),
      color: VAColors.gray900,
      fontWeight: FontWeight.w700,
    );

    (int, int)? highlightRange() {
      if (!highlightEnabled) return null;
      final start = highlightStart;
      final end = highlightEnd;
      if (start == null || end == null) return null;

      final relStart =
          (start - paragraphStartOffset).clamp(0, text.length).toInt();
      final relEnd = (end - paragraphStartOffset).clamp(0, text.length).toInt();
      if (relStart >= relEnd) return null;
      return (relStart, relEnd);
    }

    List<InlineSpan> buildSpans(String chunk, (int, int)? range) {
      if (range == null) return [TextSpan(text: chunk)];
      final (s, e) = range;
      if (s <= 0 && e >= chunk.length) {
        return [TextSpan(text: chunk, style: highlightStyle)];
      }

      final spans = <InlineSpan>[];
      if (s > 0) spans.add(TextSpan(text: chunk.substring(0, s)));
      spans.add(TextSpan(text: chunk.substring(s, e), style: highlightStyle));
      if (e < chunk.length) spans.add(TextSpan(text: chunk.substring(e)));
      return spans;
    }

    if (!withDropCap || text.isEmpty) {
      final range = highlightRange();
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text.rich(
          TextSpan(
            children: [
              const WidgetSpan(child: SizedBox(width: 32)),
              ...buildSpans(text, range),
            ],
          ),
          textAlign: TextAlign.justify,
          style: paragraphStyle,
        ),
      );
    }

    final first = text.substring(0, 1);
    final rest = text.substring(1);
    final range = highlightRange();
    final firstHighlighted =
        range != null && range.$1 <= 0 && range.$2 >= 1 && first.isNotEmpty;
    final restRange =
        range == null
            ? null
            : (
              (range.$1 - 1).clamp(0, rest.length).toInt(),
              (range.$2 - 1).clamp(0, rest.length).toInt(),
            );
    final effectiveRestRange =
        restRange == null || restRange.$1 >= restRange.$2 ? null : restRange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(0, -4),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                first,
                style:
                    (() {
                      final dropCapStyle = paragraphStyle.copyWith(
                        fontSize: fontSize * 2.67,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      );
                      if (!firstHighlighted) return dropCapStyle;
                      return dropCapStyle.copyWith(
                        backgroundColor: highlightStyle.backgroundColor,
                        color: highlightStyle.color,
                      );
                    })(),
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const WidgetSpan(child: SizedBox(width: 32)),
                  ...buildSpans(rest, effectiveRestRange),
                ],
              ),
              textAlign: TextAlign.justify,
              style: paragraphStyle,
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
              title: Text(title),
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
