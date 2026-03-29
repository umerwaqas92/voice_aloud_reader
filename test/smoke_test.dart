import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_aloud_reader/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const VoiceAloudReaderApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
