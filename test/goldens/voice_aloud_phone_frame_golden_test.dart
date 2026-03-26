import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:voxly/voice_aloud/voice_aloud_mockup_page.dart';
import 'package:voxly/voice_aloud/voice_aloud_tab.dart';

const _phone400x800 = Device(
  name: 'phone_400x800',
  size: Size(400, 800),
  devicePixelRatio: 1.0,
);

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      home: child,
    ),
  );
}

void main() {
  testGoldens('Library tab', (tester) async {
    final builder =
        DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [_phone400x800])
          ..addScenario(
            widget: _wrap(
              const VoiceAloudPhoneFrame(initialTab: VoiceAloudTab.library),
            ),
            name: 'library',
          );

    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'voice_aloud_library');
  });

  testGoldens('Read tab', (tester) async {
    final builder =
        DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [_phone400x800])
          ..addScenario(
            widget: _wrap(
              const VoiceAloudPhoneFrame(initialTab: VoiceAloudTab.read),
            ),
            name: 'read',
          );

    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'voice_aloud_read');
  });

  testGoldens('Read tab (font menu open)', (tester) async {
    final builder =
        DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [_phone400x800])
          ..addScenario(
            widget: _wrap(
              const VoiceAloudPhoneFrame(
                initialTab: VoiceAloudTab.read,
                initialShowFontMenu: true,
              ),
            ),
            name: 'read_font_menu',
          );

    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'voice_aloud_read_font_menu');
  });

  testGoldens('Scan tab', (tester) async {
    final builder =
        DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [_phone400x800])
          ..addScenario(
            widget: _wrap(
              const VoiceAloudPhoneFrame(initialTab: VoiceAloudTab.scan),
            ),
            name: 'scan',
          );

    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'voice_aloud_scan');
  });

  testGoldens('Settings tab', (tester) async {
    final builder =
        DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [_phone400x800])
          ..addScenario(
            widget: _wrap(
              const VoiceAloudPhoneFrame(initialTab: VoiceAloudTab.settings),
            ),
            name: 'settings',
          );

    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'voice_aloud_settings');
  });
}
