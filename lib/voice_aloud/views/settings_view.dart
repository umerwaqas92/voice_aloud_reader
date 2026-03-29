import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/voice_aloud_settings.dart';
import '../state/providers.dart';
import '../va_tokens.dart';
import '../widgets/animated_page_entrance.dart';
import '../widgets/lucide_svg_icon.dart';
import '../widgets/press_effect.dart';
import '../widgets/voice_picker_sheet.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final settings = settingsAsync.valueOrNull ?? VoiceAloudSettings.defaults;

    return AnimatedPageEntrance(
      child: ColoredBox(
        color: VAColors.obsidian,
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 128),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREFERENCES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                          color: VAColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                          color: VAColors.cream,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'VOICE & PLAYBACK',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                      color: VAColors.muted.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LuxuryCard(
                    child: Column(
                      children: [
                        _ReadingSpeed(
                          speed: settings.speechRate,
                          onChanged:
                              (value) => ref
                                  .read(settingsControllerProvider.notifier)
                                  .setSpeechRate(value),
                        ),
                        const _LuxuryDivider(),
                        _PitchSlider(
                          value: settings.pitch,
                          onChanged:
                              (value) => ref
                                  .read(settingsControllerProvider.notifier)
                                  .setPitch(value),
                        ),
                        const _LuxuryDivider(),
                        _VolumeSlider(
                          value: settings.volume,
                          onChanged:
                              (value) => ref
                                  .read(settingsControllerProvider.notifier)
                                  .setVolume(value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'LANGUAGE & VOICE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                      color: VAColors.muted.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LuxuryCard(
                    child: Column(
                      children: [
                        _SettingsRow(
                          title: 'Language',
                          subtitle:
                              settings.language.trim().isEmpty
                                  ? 'English, Chinese, French...'
                                  : settings.language,
                          onTap:
                              () => _pickLanguage(
                                context,
                                ref,
                                settings.language,
                              ),
                        ),
                        const _InsetDivider(),
                        _SettingsRow(
                          title: 'Selected Voice',
                          subtitle:
                              settings.voiceName.trim().isEmpty
                                  ? 'Aria (Enhanced)'
                                  : settings.voiceName,
                          subtitleColor: VAColors.gold,
                          onTap: () => showVoicePickerSheet(context, ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'APPEARANCE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                      color: VAColors.muted.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LuxuryCard(
                    child: Column(
                      children: [
                        _ToggleRow(
                          title: 'Dark Mode',
                          subtitle: 'Elegant obsidian theme',
                          value: true,
                          onChanged: (enabled) {},
                        ),
                        const _InsetDivider(),
                        _ToggleRow(
                          title: 'Auto-Scroll',
                          subtitle: 'Follow reading progress',
                          value: settings.autoScroll,
                          onChanged:
                              (enabled) => ref
                                  .read(settingsControllerProvider.notifier)
                                  .toggleAutoScroll(enabled),
                        ),
                        const _InsetDivider(),
                        _ToggleRow(
                          title: 'Haptic Feedback',
                          subtitle: 'Subtle vibrations on events',
                          value: settings.keepScreenOn,
                          onChanged:
                              (enabled) => ref
                                  .read(settingsControllerProvider.notifier)
                                  .toggleKeepScreenOn(enabled),
                        ),
                      ],
                    ),
                  ),
                  if (settingsAsync.hasError) ...[
                    const SizedBox(height: 16),
                    Text(
                      settingsAsync.error.toString(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'VoxLux v2.4.1',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.8,
                        color: VAColors.muted.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LuxuryCard extends StatelessWidget {
  const _LuxuryCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VAColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VAColors.gold.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}

class _LuxuryDivider extends StatelessWidget {
  const _LuxuryDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
    );
  }
}

class _InsetDivider extends StatelessWidget {
  const _InsetDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 16),
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: VAColors.cream.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: VAColors.muted),
              ),
            ],
          ),
        ),
        _LuxurySwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _LuxurySwitch extends StatelessWidget {
  const _LuxurySwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? VAColors.gold : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            margin: EdgeInsets.only(left: value ? 3 : 0, right: value ? 0 : 3),
            decoration: BoxDecoration(
              color: value ? VAColors.obsidian : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingSpeed extends StatelessWidget {
  const _ReadingSpeed({required this.speed, required this.onChanged});

  final double speed;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Reading Speed',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: VAColors.cream.withValues(alpha: 0.9),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: VAColors.gold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${speed.toStringAsFixed(1)}x',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: VAColors.gold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: VAColors.gold,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            thumbColor: VAColors.gold,
            overlayColor: VAColors.gold.withValues(alpha: 0.3),
            trackHeight: 3,
          ),
          child: Slider(
            min: 0.5,
            max: 3,
            divisions: 25,
            value: speed.clamp(0.5, 3.0),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0.5x', style: _ScaleLabelStyle()),
            Text('1.0x', style: _ScaleLabelStyle()),
            Text('2.0x', style: _ScaleLabelStyle()),
            Text('3.0x', style: _ScaleLabelStyle()),
          ],
        ),
      ],
    );
  }
}

class _ScaleLabelStyle extends TextStyle {
  const _ScaleLabelStyle()
    : super(fontSize: 11, fontWeight: FontWeight.w600, color: VAColors.muted);
}

class _PitchSlider extends StatelessWidget {
  const _PitchSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Voice Pitch',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: VAColors.cream.withValues(alpha: 0.9),
                ),
              ),
            ),
            Text(
              'Standard',
              style: TextStyle(fontSize: 13, color: VAColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: VAColors.gold,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            thumbColor: VAColors.gold,
            overlayColor: VAColors.gold.withValues(alpha: 0.3),
            trackHeight: 3,
          ),
          child: Slider(
            min: 0,
            max: 1,
            value: value.clamp(0.0, 1.0),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Volume',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: VAColors.cream.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.volume_up, size: 20, color: VAColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: VAColors.gold,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                  thumbColor: VAColors.gold,
                  overlayColor: VAColors.gold.withValues(alpha: 0.3),
                  trackHeight: 3,
                ),
                child: Slider(
                  min: 0,
                  max: 1,
                  value: value.clamp(0.0, 1.0),
                  onChanged: onChanged,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.volume_up, size: 20, color: VAColors.muted),
          ],
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.subtitleColor = VAColors.muted,
  });

  final String title;
  final String subtitle;
  final Color subtitleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: VAColors.cream.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                ],
              ),
            ),
            Transform.rotate(
              angle: math.pi,
              child: Icon(Icons.chevron_left, size: 20, color: VAColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pickLanguage(
  BuildContext context,
  WidgetRef ref,
  String current,
) async {
  final service = ref.read(ttsServiceProvider);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: VAColors.panel,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: FutureBuilder<List<String>>(
            future: service.getLanguages(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <String>[];
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (items.isEmpty) {
                return const Center(child: Text('No languages found'));
              }

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final lang = items[index];
                  final selected = lang == current;
                  return ListTile(
                    title: Text(lang, style: TextStyle(color: VAColors.cream)),
                    trailing:
                        selected
                            ? Icon(Icons.check, color: VAColors.gold)
                            : null,
                    onTap: () async {
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .setLanguage(lang);
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .setVoiceName('');
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  );
                },
              );
            },
          ),
        ),
      );
    },
  );
}
