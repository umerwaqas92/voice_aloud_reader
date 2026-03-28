import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'va_tokens.dart';
import 'models/document.dart';
import 'views/library_view.dart';
import 'views/read_view.dart';
import 'views/scan_view.dart';
import 'views/settings_view.dart';
import 'state/providers.dart';
import 'widgets/animated_page_entrance.dart';
import 'widgets/blur_panel.dart';
import 'widgets/lazy_indexed_stack.dart';
import 'widgets/lucide_svg_icon.dart';
import 'widgets/phone_overlays.dart';
import 'widgets/press_effect.dart';
import 'voice_aloud_tab.dart';

class VoiceAloudAppPage extends ConsumerStatefulWidget {
  const VoiceAloudAppPage({
    super.key,
    this.initialTab = VoiceAloudTab.read,
    this.initialIsPlaying = false,
    this.initialSpeed = 1.5,
    this.initialShowFontMenu = false,
  });

  final VoiceAloudTab initialTab;
  final bool initialIsPlaying;
  final double initialSpeed;
  final bool initialShowFontMenu;

  @override
  ConsumerState<VoiceAloudAppPage> createState() => _VoiceAloudAppPageState();
}

class _VoiceAloudAppPageState extends ConsumerState<VoiceAloudAppPage> {
  late bool _showFontMenu;

  @override
  void initState() {
    super.initState();
    _showFontMenu = widget.initialShowFontMenu;
    Future(() {
      ref.read(appControllerProvider.notifier).setTab(widget.initialTab);
    });
  }

  void _setActiveTab(VoiceAloudTab tab) {
    final prev = ref.read(appControllerProvider).activeTab;
    ref.read(appControllerProvider.notifier).setTab(tab);
    if (tab != VoiceAloudTab.read) {
      setState(() => _showFontMenu = false);
    }
    if (prev == VoiceAloudTab.read && tab != VoiceAloudTab.read) {
      ref.read(playbackControllerProvider.notifier).stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final docs = ref.watch(documentsControllerProvider).valueOrNull ?? const [];
    final playback = ref.watch(playbackControllerProvider);

    final activeDocId = appState.activeDocumentId;
    final activeDoc =
        activeDocId == null
            ? null
            : docs.cast<Document?>().firstWhere(
              (d) => d?.id == activeDocId,
              orElse: () => null,
            );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [VAColors.obsidian, VAColors.voidColor, VAColors.deep],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder:
                      (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.02),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                  child: KeyedSubtree(
                    key: ValueKey(appState.activeTab),
                    child: LazyIndexedStack(
                      index: appState.activeTab.index,
                      children: [
                        (_) => const LibraryView(),
                        (_) => ReadView(
                          isPlaying: playback.isPlaying,
                          showFontMenu: _showFontMenu,
                          onTogglePlaying: () async {
                            if (activeDoc == null) return;
                            await ref
                                .read(playbackControllerProvider.notifier)
                                .toggle(activeDoc);
                          },
                          onToggleFontMenu:
                              () => setState(
                                () => _showFontMenu = !_showFontMenu,
                              ),
                        ),
                        (_) => const ScanView(),
                        (_) => const SettingsView(),
                      ],
                    ),
                  ),
                ),
              ),
              if (appState.activeTab != VoiceAloudTab.scan)
                _LuxuryBottomNavBar(
                  activeTab: appState.activeTab,
                  onChanged: _setActiveTab,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LuxuryBottomNavBar extends StatelessWidget {
  const _LuxuryBottomNavBar({required this.activeTab, required this.onChanged});

  final VoiceAloudTab activeTab;
  final ValueChanged<VoiceAloudTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VAColors.voidColor.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: VAColors.gold.withValues(alpha: 0.15),
            width: 1,
          ),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LuxuryNavItem(
                iconName: 'book',
                label: 'Library',
                isActive: activeTab == VoiceAloudTab.library,
                onTap: () => onChanged(VoiceAloudTab.library),
              ),
              _LuxuryNavItem(
                iconName: 'file-text',
                label: 'Read',
                isActive: activeTab == VoiceAloudTab.read,
                onTap: () => onChanged(VoiceAloudTab.read),
              ),
              _LuxuryNavItem(
                iconName: 'camera',
                label: 'Scan',
                isActive: activeTab == VoiceAloudTab.scan,
                onTap: () => onChanged(VoiceAloudTab.scan),
              ),
              _LuxuryNavItem(
                iconName: 'settings',
                label: 'Settings',
                isActive: activeTab == VoiceAloudTab.settings,
                onTap: () => onChanged(VoiceAloudTab.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LuxuryNavItem extends StatelessWidget {
  const _LuxuryNavItem({
    required this.iconName,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String iconName;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? VAColors.gold : VAColors.muted;
    final stroke = isActive ? 2.5 : 2.0;

    return PressEffect(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 8 : 0,
              height: 8,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: VAColors.gold,
                shape: BoxShape.circle,
                boxShadow:
                    isActive
                        ? [
                          BoxShadow(
                            color: VAColors.gold.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ]
                        : null,
              ),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isActive ? 1.1 : 1.0,
              child: LucideSvgIcon(
                iconName,
                size: 22,
                color: color,
                strokeWidth: stroke,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color:
                    isActive
                        ? VAColors.gold
                        : VAColors.muted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceAloudMockupPage extends StatelessWidget {
  const VoiceAloudMockupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VAColors.outerBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: const VoiceAloudPhoneFrame(),
          ),
        ),
      ),
    );
  }
}

class VoiceAloudPhoneFrame extends ConsumerStatefulWidget {
  const VoiceAloudPhoneFrame({
    super.key,
    this.initialTab = VoiceAloudTab.read,
    this.initialIsPlaying = false,
    this.initialSpeed = 1.5,
    this.initialShowFontMenu = false,
  });

  final VoiceAloudTab initialTab;
  final bool initialIsPlaying;
  final double initialSpeed;
  final bool initialShowFontMenu;

  @override
  ConsumerState<VoiceAloudPhoneFrame> createState() =>
      _VoiceAloudPhoneFrameState();
}

class _VoiceAloudPhoneFrameState extends ConsumerState<VoiceAloudPhoneFrame> {
  late bool _showFontMenu;

  @override
  void initState() {
    super.initState();
    _showFontMenu = widget.initialShowFontMenu;
    Future(() {
      ref.read(appControllerProvider.notifier).setTab(widget.initialTab);
      ref.read(appControllerProvider.notifier).setActiveDocument('demo_1');
    });
  }

  void _setActiveTab(VoiceAloudTab tab) {
    final prev = ref.read(appControllerProvider).activeTab;
    ref.read(appControllerProvider.notifier).setTab(tab);
    if (tab != VoiceAloudTab.read) {
      setState(() => _showFontMenu = false);
    }
    if (prev == VoiceAloudTab.read && tab != VoiceAloudTab.read) {
      ref.read(playbackControllerProvider.notifier).stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final docs = ref.watch(documentsControllerProvider).valueOrNull ?? const [];
    final playback = ref.watch(playbackControllerProvider);

    final activeDocId = appState.activeDocumentId;
    final activeDoc =
        activeDocId == null
            ? null
            : docs.cast<Document?>().firstWhere(
              (d) => d?.id == activeDocId,
              orElse: () => null,
            );

    return SizedBox(
      width: VASizes.phoneWidth,
      height: VASizes.phoneHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: VAColors.obsidian,
          borderRadius: BorderRadius.circular(VASizes.phoneRadius),
          border: Border.all(
            color: VAColors.phoneBorder,
            width: VASizes.phoneBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.9),
              blurRadius: 120,
              offset: const Offset(0, 40),
            ),
            BoxShadow(
              color: VAColors.gold.withValues(alpha: 0.1),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VASizes.phoneRadius),
          child: Stack(
            children: [
              _LuxuryBackground(),
              Column(
                children: [
                  Expanded(
                    child: Container(
                      color: VAColors.obsidian,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder:
                            (child, animation) => FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.02),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                        child: KeyedSubtree(
                          key: ValueKey(appState.activeTab),
                          child: LazyIndexedStack(
                            index: appState.activeTab.index,
                            children: [
                              (_) => const LibraryView(),
                              (_) => ReadView(
                                isPlaying: playback.isPlaying,
                                showFontMenu: _showFontMenu,
                                onTogglePlaying: () async {
                                  if (activeDoc == null) return;
                                  await ref
                                      .read(playbackControllerProvider.notifier)
                                      .toggle(activeDoc);
                                },
                                onToggleFontMenu:
                                    () => setState(
                                      () => _showFontMenu = !_showFontMenu,
                                    ),
                              ),
                              (_) => const ScanView(),
                              (_) => const SettingsView(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (appState.activeTab != VoiceAloudTab.scan)
                    _LuxuryBottomNavBar(
                      activeTab: appState.activeTab,
                      onChanged: _setActiveTab,
                    ),
                ],
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FakeIosStatusBar(),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FakeDynamicIsland(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LuxuryBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: VAColors.gold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -30,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                color: const Color(0xFF4A3080).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
