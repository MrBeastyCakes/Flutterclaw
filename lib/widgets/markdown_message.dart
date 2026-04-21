import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'code_block.dart';
import '../utils/animations.dart';

/// Renders assistant messages with full Markdown support,
/// custom code blocks, and smooth transitions.
class MarkdownMessage extends StatelessWidget {
  final String content;

  const MarkdownMessage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeSlideIn(
      child: MarkdownBody(
        data: content,
        selectable: true,
        styleSheet: _buildStyleSheet(context, isDark),
        builders: {
          'code': _CodeElementBuilder(),
          'pre': _PreElementBuilder(),
        },
        onTapLink: (text, href, title) {
          // Handled by selectable text already, but could launch URL here.
        },
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context, bool isDark) {
    final base = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return MarkdownStyleSheet(
      p: base.bodyLarge?.copyWith(fontSize: 16, height: 1.6),
      h1: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
      h2: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      h3: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      h4: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      strong: const TextStyle(fontWeight: FontWeight.w600),
      em: const TextStyle(fontStyle: FontStyle.italic),
      blockquote: TextStyle(
        color: cs.onSurfaceVariant,
        fontStyle: FontStyle.italic,
        height: 1.5,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: cs.primary, width: 4),
        ),
        color: cs.surfaceContainerHighest.withOpacity(0.5),
      ),
      blockquotePadding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      listBullet: base.bodyLarge?.copyWith(fontSize: 16),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
        color: cs.onSurface,
      ),
      codeblockPadding: EdgeInsets.zero,
      codeblockDecoration: const BoxDecoration(),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
        ),
      ),
      tableHead: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
      tableBody: base.bodyMedium?.copyWith(color: cs.onSurface),
      tableBorder: TableBorder.all(
        color: cs.outlineVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      a: TextStyle(
        color: cs.primary,
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ------------------------------------------------------------------
// Custom Markdown builders
// ------------------------------------------------------------------

class _CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget visitText(text, TextStyle? preferredStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: preferredStyle?.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.text,
        style: preferredStyle?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}

class _PreElementBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(element, preferredStyle) {
    String? language;
    String code = element.textContent;

    // Extract language from fenced code block
    final classAttr = element.attributes['class'];
    if (classAttr != null && classAttr.startsWith('language-')) {
      language = classAttr.substring(9);
    }

    // Clean up trailing newline added by markdown parser
    code = code.replaceAll(RegExp(r'\n$'), '');

    return CodeBlock(code: code, language: language);
  }
}
