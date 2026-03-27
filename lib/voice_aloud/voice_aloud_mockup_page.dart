import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'va_tokens.dart';
import 'models/document.dart';
import 'views/library_view.dart';
import 'views/read_view.dart';
import 'views/scan_view.dart';
import 'views/settings_view.dart';
import 'state/providers.dart';
import 'widgets/blur_panel.dart';
import 'widgets/lazy_indexed_stack.dart';
import 'widgets/lucide_svg_icon.dart';
import 'widgets/phone_overlays.dart';
import 'voice_aloud_tab.dart';

class VoiceAloudAppPage extends ConsumerStatefulWidget {
  const VoiceAloudAppPage({
    super.key,
    this.initialTab = VoiceAloudTab.library,
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
      body: Column(
        children: [
          Expanded(
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
                      () => setState(() => _showFontMenu = !_showFontMenu),
                ),
                (_) => const ScanView(),
                (_) => const SettingsView(),
              ],
            ),
          ),
          if (appState.activeTab != VoiceAloudTab.scan)
            _BottomNavBar(
              activeTab: appState.activeTab,
              onChanged: _setActiveTab,
            ),
        ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(VASizes.phoneRadius),
          border: Border.all(
            color: VAColors.phoneBorder,
            width: VASizes.phoneBorderWidth,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 40,
              offset: Offset(0, 24),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VASizes.phoneRadius),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ColoredBox(
                      color: Colors.white,
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
                  if (appState.activeTab != VoiceAloudTab.scan)
                    _BottomNavBar(
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

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.activeTab, required this.onChanged});

  final VoiceAloudTab activeTab;
  final ValueChanged<VoiceAloudTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlurPanel(
      borderRadius: BorderRadius.zero,
      sigma: 18,
      color: Colors.white.withValues(alpha: 0.9),
      border: const Border(top: BorderSide(color: VAColors.gray100, width: 1)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              iconName: 'book',
              label: 'Library',
              isActive: activeTab == VoiceAloudTab.library,
              onTap: () => onChanged(VoiceAloudTab.library),
            ),
            _NavItem(
              iconName: 'file-text',
              label: 'Read',
              isActive: activeTab == VoiceAloudTab.read,
              onTap: () => onChanged(VoiceAloudTab.read),
            ),
            _NavItem(
              iconName: 'camera',
              label: 'Scan',
              isActive: activeTab == VoiceAloudTab.scan,
              onTap: () => onChanged(VoiceAloudTab.scan),
            ),
            _NavItem(
              iconName: 'settings',
              label: 'Settings',
              isActive: activeTab == VoiceAloudTab.settings,
              onTap: () => onChanged(VoiceAloudTab.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
    final color = isActive ? VAColors.blue600 : VAColors.gray400;
    final stroke = isActive ? 2.5 : 2.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isActive ? 1.1 : 1.0,
              child: LucideSvgIcon(
                iconName,
                size: 24,
                color: color,
                strokeWidth: stroke,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
