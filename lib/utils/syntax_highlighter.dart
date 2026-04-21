import 'package:flutter/material.dart';

/// Language-agnostic syntax highlighter using regex-based tokenization.
/// Supports: dart, json, yaml, markdown, python, javascript, typescript, shell, plaintext.
class SyntaxHighlighter {
  final String source;
  final String language;

  const SyntaxHighlighter(this.source, {this.language = 'plaintext'});

  static const _languages = {
    'dart',
    'json',
    'yaml',
    'markdown',
    'python',
    'javascript',
    'typescript',
    'shell',
    'bash',
    'plaintext',
  };

  List<TextSpan> buildSpans(BuildContext context) {
    final theme = _themeFor(context);
    final rules = _rulesFor(language);

    final spans = <TextSpan>[];
    int index = 0;

    while (index < source.length) {
      TextSpan? bestSpan;
      int bestEnd = index;

      for (final rule in rules) {
        final match = rule.pattern.matchAsPrefix(source, index);
        if (match != null && match.end > bestEnd) {
          bestEnd = match.end;
          bestSpan = TextSpan(
            text: match.group(0),
            style: TextStyle(color: rule.color(theme)),
          );
        }
      }

      if (bestSpan != null) {
        spans.add(bestSpan);
        index = bestEnd;
      } else {
        spans.add(TextSpan(text: source[index]));
        index++;
      }
    }

    return spans;
  }

  static _SyntaxTheme _themeFor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const _SyntaxTheme.dark() : const _SyntaxTheme.light();
  }

  List<_HighlightRule> _rulesFor(String lang) {
    switch (lang.toLowerCase()) {
      case 'json':
      case 'yaml':
        return _jsonYamlRules;
      case 'python':
        return _pythonRules;
      case 'javascript':
      case 'typescript':
      case 'dart':
        return _dartRules;
      case 'shell':
      case 'bash':
        return _shellRules;
      case 'markdown':
        return _markdownRules;
      default:
        return [];
    }
  }

  // ------------------------------------------------------------------
  //  Regex-based highlight rules
  // ------------------------------------------------------------------

  static final _commentRE = RegExp(r'//.*|/\*.*?\*/|\#.*', multiLine: true);
  static final _stringRE = RegExp(r"'(?:[^'\\]|\\.)*'|\"(?:[^\"\\]|\\.)*\"");
  static final _numberRE = RegExp(r'\b\d+(\.\d+)?\b');
  static final _keywordRE = RegExp(
    r'\b(?:abstract|as|assert|async|await|break|case|catch|class|const|continue|covariant|default|deferred|do|dynamic|else|enum|export|extends|extension|external|factory|false|final|finally|for|Function|get|hide|if|implements|import|in|interface|is|late|library|mixin|null|on|operator|part|required|rethrow|return|set|show|static|super|switch|sync|this|throw|true|try|typedef|var|void|while|with|yield)\b',
  );

  static final _jsonKeyRE = RegExp(r'"(?:[^"\\]|\\.)*"(?=\s*:)');
  static final _jsonBoolNullRE = RegExp(r'\b(?:true|false|null)\b');

  List<_HighlightRule> get _dartRules => [
    _HighlightRule(_commentRE, (t) => t.comment),
    _HighlightRule(_stringRE, (t) => t.string),
    _HighlightRule(_numberRE, (t) => t.number),
    _HighlightRule(_keywordRE, (t) => t.keyword),
  ];

  List<_HighlightRule> get _jsonYamlRules => [
    _HighlightRule(_commentRE, (t) => t.comment),
    _HighlightRule(_jsonKeyRE, (t) => t.keyword),
    _HighlightRule(_stringRE, (t) => t.string),
    _HighlightRule(_numberRE, (t) => t.number),
    _HighlightRule(_jsonBoolNullRE, (t) => t.keyword),
  ];

  List<_HighlightRule> get _pythonRules => [
    _HighlightRule(RegExp(r'\#.*'), (t) => t.comment),
    _HighlightRule(_stringRE, (t) => t.string),
    _HighlightRule(_numberRE, (t) => t.number),
    _HighlightRule(
      RegExp(
        r'\b(?:and|as|assert|break|class|continue|def|del|elif|else|except|False|finally|for|from|global|if|import|in|is|lambda|None|nonlocal|not|or|pass|raise|return|True|try|while|with|yield)\b',
      ),
      (t) => t.keyword,
    ),
  ];

  List<_HighlightRule> get _shellRules => [
    _HighlightRule(RegExp(r'\#.*'), (t) => t.comment),
    _HighlightRule(_stringRE, (t) => t.string),
    _HighlightRule(
      RegExp(
        r'\b(?:cd|ls|cat|echo|grep|sed|awk|chmod|chown|curl|wget|ssh|scp|rm|cp|mv|mkdir|touch|sudo|if|then|else|fi|for|do|done|while|case|esac|function|return|exit|export|source)\b',
      ),
      (t) => t.keyword,
    ),
  ];

  List<_HighlightRule> get _markdownRules => [
    _HighlightRule(RegExp(r'^#{1,6}\s+.*$', multiLine: true), (t) => t.keyword),
    _HighlightRule(RegExp(r'\*\*.*?\*\*'), (t) => t.string),
    _HighlightRule(RegExp(r'\*.*?\*'), (t) => t.string),
    _HighlightRule(RegExp(r'`[^`]+`'), (t) => t.number),
    _HighlightRule(RegExp(r'!?\[.*?\]\(.*?\)'), (t) => t.comment),
  ];
}

class _HighlightRule {
  final RegExp pattern;
  final Color Function(_SyntaxTheme) color;
  const _HighlightRule(this.pattern, this.color);
}

class _SyntaxTheme {
  final Color keyword;
  final Color string;
  final Color number;
  final Color comment;

  const _SyntaxTheme({
    required this.keyword,
    required this.string,
    required this.number,
    required this.comment,
  });

  const _SyntaxTheme.light()
      : keyword = const Color(0xFF0066CC),
        string = const Color(0xFF008000),
        number = const Color(0xFF6600CC),
        comment = const Color(0xFF808080);

  const _SyntaxTheme.dark()
      : keyword = const Color(0xFF66D9EF),
        string = const Color(0xFFA6E22E),
        number = const Color(0xFFAE81FF),
        comment = const Color(0xFF75715E);
}
