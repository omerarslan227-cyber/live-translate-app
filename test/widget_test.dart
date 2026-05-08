import 'package:flutter_test/flutter_test.dart';

import 'package:live_translate_app/main.dart';

void main() {
  testWidgets('BridgeCall home screen opens', (WidgetTester tester) async {
    await tester.pumpWidget(const LiveTranslateApp());
    await tester.pumpAndSettle();

    expect(find.text('BridgeCall'), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsOneWidget);
  });
}
