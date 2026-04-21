import 'package:flutter_test/flutter_test.dart';
import 'package:flutterclaw/widgets/markdown_message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/material.dart';

void main() {
  group('MarkdownMessage', () {
    testWidgets('renders plain text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownMessage(content: 'Hello **world**'),
          ),
        ),
      );
      // MarkdownBody is rendered inside FadeSlideIn
      expect(find.byType(MarkdownBody), findsOneWidget);
    });

    testWidgets('renders fenced code block', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownMessage(content: 'Some text before\n\n```dart\nvoid main() {}\n```\n\nAfter'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MarkdownBody), findsOneWidget);
    });
  });
}
