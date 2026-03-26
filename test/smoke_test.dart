import 'package:flutter_test/flutter_test.dart';

import 'package:voxly/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const VoxlyApp());
    await tester.pumpAndSettle();
    expect(find.text('Library'), findsWidgets);
  });
}
