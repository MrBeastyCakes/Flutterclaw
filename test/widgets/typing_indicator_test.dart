import 'package:flutter_test/flutter_test.dart';
import 'package:flutterclaw/widgets/typing_indicator.dart';
import 'package:flutter/material.dart';

void main() {
  group('TypingIndicator', () {
    testWidgets('renders thinking text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator()),
        ),
      );
      // Don't pumpAndSettle — animation runs forever
      expect(find.text('OpenClaw is thinking'), findsOneWidget);
    });
  });
}
