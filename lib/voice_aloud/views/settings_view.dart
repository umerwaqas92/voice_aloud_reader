import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/voice_aloud_settings.dart';
import '../state/providers.dart';
import '../va_tokens.dart';
import '../widgets/animated_page_entrance.dart';
import '../widgets/lucide_svg_icon.dart';
import '../widgets/press_effect.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final settings = settingsAsync.valueOrNull ?? VoiceAloudSettings.defaults;

    return AnimatedPageEntrance(
      child: ColoredBox(
        color: VAColors.gray50,
        child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 128),
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: VAColors.gray900,
                  ),
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Voice & Playback',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: VAColors.gray400,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  child: Column(
                    children: [
                      _ReadingSpeed(
                        speed: settings.speechRate,
                        onChanged:
                            (value) => ref
                                .read(settingsControllerProvider.notifier)
                                .setSpeechRate(value),
                      ),
                      const _Divider(),
                      _PitchSlider(
                        value: settings.pitch,
                        onChanged:
                            (value) => ref
                                .read(settingsControllerProvider.notifier)
                                .setPitch(value),
                      ),
                      const _Divider(),
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Reader',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: VAColors.gray400,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  child: Column(
                    children: [
                      _ToggleRow(
                        title: 'Highlight spoken word',
                        subtitle: 'Highlights the word being read aloud',
                        value: settings.highlightSpokenText,
                        onChanged:
                            (enabled) => ref
                                .read(settingsControllerProvider.notifier)
                                .toggleHighlight(enabled),
                      ),
                      const _Divider(),
                      _ToggleRow(
                        title: 'Auto-scroll while reading',
                        subtitle: 'Keeps the spoken text visible',
                        value: settings.autoScroll,
                        onChanged:
                            (enabled) => ref
                                .read(settingsControllerProvider.notifier)
                                .toggleAutoScroll(enabled),
                      ),
                      const _Divider(),
                      _ToggleRow(
                        title: 'Keep screen on',
                        subtitle: 'Prevents screen from sleeping while playing',
                        value: settings.keepScreenOn,
                        onChanged:
                            (enabled) => ref
                                .read(settingsControllerProvider.notifier)
                                .toggleKeepScreenOn(enabled),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Language & Voice (40+ Supported)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: VAColors.gray400,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x80F3F4F6)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _SettingsRow(
                        title: 'Language',
                        subtitle:
                            settings.language.trim().isEmpty
                                ? 'English, Chinese, French...'
                                : settings.language,
                        onTap:
                            () =>
                                _pickLanguage(context, ref, settings.language),
                      ),
                      const _InsetDivider(),
                      _SettingsRow(
                        title: 'Selected Voice',
                        subtitle:
                            settings.voiceName.trim().isEmpty
                                ? 'Samantha (Enhanced)'
                                : settings.voiceName,
                        subtitleColor: VAColors.blue600,
                        onTap:
                            () => _pickVoice(context, ref, settings.language),
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
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x80F3F4F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: SizedBox(
        height: 1,
        width: double.infinity,
        child: ColoredBox(color: VAColors.gray100),
      ),
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
      color: VAColors.gray100,
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
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: VAColors.gray800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: VAColors.gray500),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: VAColors.blue600,
          activeTrackColor: VAColors.blue100,
          onChanged: onChanged,
        ),
      ],
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
            const Expanded(
              child: Text(
                'Reading Speed',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            _Stepper(
              valueLabel: '${speed.toStringAsFixed(1)}x',
              onDecrement: () => onChanged((speed - 0.1).clamp(0.5, 3.0)),
              onIncrement: () => onChanged((speed + 0.1).clamp(0.5, 3.0)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: VAColors.blue600,
            inactiveTrackColor: VAColors.gray100,
            thumbColor: VAColors.blue600,
            overlayColor: VAColors.blue100.withValues(alpha: 0.3),
            trackHeight: 6,
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
        const Row(
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
    : super(fontSize: 12, fontWeight: FontWeight.w600, color: VAColors.gray400);
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
            const Expanded(
              child: Text(
                'Voice Pitch',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            _Stepper(
              valueLabel: value.toStringAsFixed(2),
              onDecrement: () => onChanged((value - 0.05).clamp(0.0, 1.0)),
              onIncrement: () => onChanged((value + 0.05).clamp(0.0, 1.0)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: VAColors.blue600,
            inactiveTrackColor: VAColors.gray100,
            thumbColor: VAColors.blue600,
            overlayColor: VAColors.blue100.withValues(alpha: 0.3),
            trackHeight: 6,
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
        const Text(
          'Volume',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const LucideSvgIcon('volume-2', size: 24, color: Color(0xFFCBD5E1)),
            const SizedBox(width: 16),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: VAColors.blue600,
                  inactiveTrackColor: VAColors.gray100,
                  thumbColor: VAColors.blue600,
                  overlayColor: VAColors.blue100.withValues(alpha: 0.3),
                  trackHeight: 6,
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
            _Stepper(
              valueLabel: value.toStringAsFixed(2),
              onDecrement: () => onChanged((value - 0.05).clamp(0.0, 1.0)),
              onIncrement: () => onChanged((value + 0.05).clamp(0.0, 1.0)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.valueLabel,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String valueLabel;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniIconButton(
          iconName: 'minus',
          onTap: onDecrement,
        ),
        const SizedBox(width: 8),
        Text(
          valueLabel,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        _MiniIconButton(
          iconName: 'plus',
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({required this.iconName, required this.onTap});

  final String iconName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressEffect(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Center(
          child: LucideSvgIcon(
            iconName,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.subtitleColor = VAColors.gray500,
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: VAColors.gray800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                ],
              ),
            ),
            Transform.rotate(
              angle: math.pi,
              child: const LucideSvgIcon(
                'chevron-left',
                size: 20,
                color: VAColors.gray300,
              ),
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
                    title: Text(lang),
                    trailing: selected ? const Icon(Icons.check) : null,
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

Future<void> _pickVoice(
  BuildContext context,
  WidgetRef ref,
  String language,
) async {
  final service = ref.read(ttsServiceProvider);

  await showModalBottomSheet<void>(
    context: context,
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
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: service.getVoices(),
            builder: (context, snapshot) {
              final voices = snapshot.data ?? const <Map<String, dynamic>>[];
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final filtered =
                  language.trim().isEmpty
                      ? voices
                      : voices.where((v) {
                        final locale =
                            (v['locale'] ?? v['Locale'] ?? '').toString();
                        return locale.startsWith(language);
                      }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No voices found'));
              }

              String nameOf(Map<String, dynamic> v) =>
                  (v['name'] ?? v['Name'] ?? '').toString().trim();

              final names =
                  filtered
                      .map(nameOf)
                      .where((n) => n.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();

              return ListView.builder(
                itemCount: names.length,
                itemBuilder: (context, index) {
                  final name = names[index];
                  return ListTile(
                    title: Text(name),
                    onTap: () async {
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .setVoiceName(name);
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
