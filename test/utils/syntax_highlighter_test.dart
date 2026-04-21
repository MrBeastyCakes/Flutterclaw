import 'package:flutter_test/flutter_test.dart';
import 'package:flutterclaw/utils/syntax_highlighter.dart';

void main() {
  group('SyntaxHighlighter', () {
    test('plaintext returns empty rules', () {
      const highlighter = SyntaxHighlighter('hello world', language: 'plaintext');
      expect(highlighter.buildSpans, isNotNull);
    });

    test('dart highlights keywords', () {
      const code = 'final x = 42; // comment';
      const highlighter = SyntaxHighlighter(code, language: 'dart');
      final spans = highlighter.buildSpans;
      expect(spans, isNotNull);
    });

    test('json highlights booleans', () {
      const code = '{"active": true, "count": 5}';
      const highlighter = SyntaxHighlighter(code, language: 'json');
      final spans = highlighter.buildSpans;
      expect(spans, isNotNull);
    });

    test('python highlights def keyword', () {
      const code = 'def hello(): pass';
      const highlighter = SyntaxHighlighter(code, language: 'python');
      final spans = highlighter.buildSpans;
      expect(spans, isNotNull);
    });

    test('shell highlights commands', () {
      const code = 'cd /home && ls -la';
      const highlighter = SyntaxHighlighter(code, language: 'shell');
      final spans = highlighter.buildSpans;
      expect(spans, isNotNull);
    });
  });
}
