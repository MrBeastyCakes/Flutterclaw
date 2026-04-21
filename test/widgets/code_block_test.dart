import 'package:flutter_test/flutter_test.dart';
import 'package:flutterclaw/widgets/code_block.dart';
import 'package:flutter/material.dart';

void main() {
  group('CodeBlock', () {
    testWidgets('renders code and copy button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CodeBlock(code: 'print("hello")', language: 'python'),
          ),
        ),
      );
      expect(find.text('PYTHON'), findsOneWidget);
      expect(find.text('print("hello")'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('renders without language', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CodeBlock(code: 'plain text'),
          ),
        ),
      );
      expect(find.text('CODE'), findsOneWidget);
    });
  });
}
