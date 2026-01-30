// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

import '../core/parser/content_block.dart';
import '../style/markdown_theme.dart';
import '../config/render_options.dart';
import 'element_builders/formula_builder.dart';
import 'element_builders/code_builder.dart';
import 'element_builders/table_builder.dart';

/// Builds widgets from parsed content blocks.
///
/// Converts markdown AST nodes into Flutter widgets
/// using the provided theme and configuration.
class ContentBuilder {
  /// Creates a content builder.
  ContentBuilder({
    this.theme,
    this.renderOptions = const RenderOptions(),
    Map<String, ElementBuilder>? customBuilders,
  }) {
    _builders = {
      'latex_inline': FormulaBuilder(isBlock: false),
      'latex_block': FormulaBuilder(isBlock: true),
      'code': CodeBlockBuilder(),
      'table': TableNodeBuilder(),
      ...?customBuilders,
    };
  }

  /// Theme for styling.
  final MarkdownTheme? theme;

  /// Render options.
  final RenderOptions renderOptions;

  late final Map<String, ElementBuilder> _builders;

  /// Document for markdown parsing.
  md.Document get _document => md.Document(
        extensionSet: md.ExtensionSet.gitHubFlavored,
        encodeHtml: false,
        inlineSyntaxes: renderOptions.enableLatex 
            ? [_LatexInlineSyntax()]
            : null,
      );

  /// Builds a widget for a content block.
  Widget buildBlock(BuildContext context, ContentBlock block) {
    // Get base theme from context (which provides default styles from Flutter's ThemeData)
    final baseTheme = MarkdownThemeProvider.of(context);
    // Merge user's theme on top of base theme (user overrides take precedence)
    final effectiveTheme = theme != null 
        ? baseTheme.merge(theme!) 
        : baseTheme;

    return switch (block.type) {
      ContentBlockType.paragraph => _buildParagraph(context, block, effectiveTheme),
      ContentBlockType.heading => _buildHeading(context, block, effectiveTheme),
      ContentBlockType.codeBlock => _buildCodeBlock(context, block, effectiveTheme),
      ContentBlockType.blockquote => _buildBlockquote(context, block, effectiveTheme),
      ContentBlockType.unorderedList => _buildUnorderedList(context, block, effectiveTheme),
      ContentBlockType.orderedList => _buildOrderedList(context, block, effectiveTheme),
      ContentBlockType.listItem => _buildListItem(context, block, effectiveTheme),
      ContentBlockType.table => _buildTable(context, block, effectiveTheme),
      ContentBlockType.horizontalRule => _buildHorizontalRule(context, effectiveTheme),
      ContentBlockType.latexBlock => _buildLatexBlock(context, block, effectiveTheme),
      ContentBlockType.image => _buildImage(context, block, effectiveTheme),
      ContentBlockType.thematicBreak => _buildHorizontalRule(context, effectiveTheme),
      ContentBlockType.htmlBlock => _buildParagraph(context, block, effectiveTheme),
    };
  }

  /// Builds a list of widgets from content blocks.
  List<Widget> buildBlocks(BuildContext context, List<ContentBlock> blocks) {
    return blocks.map((block) => buildBlock(context, block)).toList();
  }

  Widget _buildParagraph(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    final text = block.rawContent.trim();
    final inlineSpan = _buildInlineSpan(context, text, theme);

    return Padding(
      padding: EdgeInsets.only(bottom: theme.paragraphSpacing ?? 16),
      child: renderOptions.selectableText
          ? SelectableText.rich(inlineSpan)
          : RichText(text: inlineSpan),
    );
  }

  Widget _buildHeading(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    final level = block.headingLevel ?? 1;
    final text = block.rawContent.replaceFirst(RegExp(r'^#{1,6}\s+'), '').trim();
    final style = theme.headingStyle(level);
    final inlineSpan = _buildInlineSpan(context, text, theme);
    // Apply heading style as base style
    final styledSpan = TextSpan(
      style: style,
      children: [inlineSpan],
    );

    return Padding(
      padding: EdgeInsets.only(
        top: theme.headingSpacing ?? 24,
        bottom: (theme.headingSpacing ?? 24) / 2,
      ),
      child: renderOptions.selectableText
          ? SelectableText.rich(styledSpan)
          : RichText(text: styledSpan),
    );
  }

  Widget _buildCodeBlock(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    final builder = _builders['code'] as CodeBlockBuilder;
    return builder.buildWithOptions(
      context,
      block.rawContent,
      block.language,
      theme,
      onCopy: renderOptions.onCodeCopy != null
          ? (code) => renderOptions.onCodeCopy!(code, block.language)
          : null,
    );
  }

  Widget _buildBlockquote(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    final text = block.rawContent
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^>\s?'), ''))
        .join('\n')
        .trim();
    final inlineSpan = _buildInlineSpan(context, text, theme);
    // Apply blockquote style as base style
    final styledSpan = TextSpan(
      style: theme.blockquoteStyle,
      children: [inlineSpan],
    );

    return Container(
      margin: EdgeInsets.only(bottom: theme.blockSpacing ?? 16),
      padding: theme.blockquotePadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.blockquoteBorderColor ?? Colors.grey,
            width: 4,
          ),
        ),
        color: theme.blockquoteBackground,
      ),
      child: renderOptions.selectableText
          ? SelectableText.rich(styledSpan)
          : RichText(text: styledSpan),
    );
  }

  Widget _buildUnorderedList(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    final items = _parseListItems(block.rawContent, ordered: false);
    return Padding(
      padding: EdgeInsets.only(bottom: theme.blockSpacing ?? 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          final inlineSpan = _buildInlineSpan(context, item, theme);
          return Padding(
            padding: EdgeInsets.only(
              left: theme.listIndent ?? 24,
              bottom: 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: theme.listBulletStyle),
                Expanded(
                  child: renderOptions.selectableText
                      ? SelectableText.rich(inlineSpan)
                      : RichText(text: inlineSpan),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderedList(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    final items = _parseListItems(block.rawContent, ordered: true);
    return Padding(
      padding: EdgeInsets.only(bottom: theme.blockSpacing ?? 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final inlineSpan = _buildInlineSpan(context, entry.value, theme);
          return Padding(
            padding: EdgeInsets.only(
              left: theme.listIndent ?? 24,
              bottom: 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text('${entry.key + 1}. ', style: theme.listBulletStyle),
                ),
                Expanded(
                  child: renderOptions.selectableText
                      ? SelectableText.rich(inlineSpan)
                      : RichText(text: inlineSpan),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    final text = block.rawContent.replaceFirst(RegExp(r'^[\s]*[-*+\d.]+\s+'), '');
    final inlineSpan = _buildInlineSpan(context, text, theme);
    return Padding(
      padding: EdgeInsets.only(left: theme.listIndent ?? 24, bottom: 4),
      child: renderOptions.selectableText
          ? SelectableText.rich(inlineSpan)
          : RichText(text: inlineSpan),
    );
  }

  Widget _buildTable(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    final builder = _builders['table'] as TableNodeBuilder;
    return builder.build(context, block.rawContent, theme);
  }

  Widget _buildHorizontalRule(BuildContext context, MarkdownTheme theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.blockSpacing ?? 16),
      child: Divider(
        height: 1,
        color: theme.horizontalRuleColor ?? Colors.grey,
      ),
    );
  }

  Widget _buildLatexBlock(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    if (!renderOptions.enableLatex) {
      return _buildCodeBlock(context, block, theme);
    }
    final builder = _builders['latex_block'] as FormulaBuilder;
    return builder.build(context, block.rawContent, theme);
  }

  Widget _buildImage(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    final match = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)').firstMatch(block.rawContent);
    if (match == null) {
      return const SizedBox.shrink();
    }

    final alt = match.group(1) ?? '';
    final src = match.group(2) ?? '';

    if (!renderOptions.enableImageLoading) {
      return Padding(
        padding: EdgeInsets.only(bottom: theme.blockSpacing ?? 16),
        child: Text('[Image: $alt]', style: theme.textStyle),
      );
    }

    Widget image = Image.network(
      src,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text('[Failed to load: $alt]'),
    );

    if (renderOptions.maxImageWidth != null || renderOptions.maxImageHeight != null) {
      image = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: renderOptions.maxImageWidth ?? double.infinity,
          maxHeight: renderOptions.maxImageHeight ?? double.infinity,
        ),
        child: image,
      );
    }

    if (renderOptions.onImageTap != null) {
      image = GestureDetector(
        onTap: () => renderOptions.onImageTap!(src, alt),
        child: image,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: theme.blockSpacing ?? 16),
      child: image,
    );
  }

  TextSpan _buildInlineSpan(
    BuildContext context,
    String text,
    MarkdownTheme theme,
  ) {
    // Sanitize text to prevent UTF-16 encoding errors during streaming
    final safeText = _sanitizeUtf16(text);
    final nodes = _document.parseInline(safeText);
    return TextSpan(
      style: theme.textStyle,
      children: _buildInlineChildren(context, nodes, theme),
    );
  }

  /// Sanitizes a string to ensure it's well-formed UTF-16.
  ///
  /// Removes incomplete surrogate pairs that can occur during streaming
  /// when multi-byte characters (like emoji) are split across chunks.
  String _sanitizeUtf16(String text) {
    if (text.isEmpty) return text;
    
    final runes = text.runes.toList();
    if (runes.isEmpty) return '';
    
    // Check if the last character is a high surrogate without a low surrogate
    final lastCodeUnit = text.codeUnitAt(text.length - 1);
    if (_isHighSurrogate(lastCodeUnit)) {
      // Remove the incomplete surrogate
      return text.substring(0, text.length - 1);
    }
    
    // Check if the first character is a lone low surrogate
    final firstCodeUnit = text.codeUnitAt(0);
    if (_isLowSurrogate(firstCodeUnit)) {
      return text.substring(1);
    }
    
    return text;
  }

  bool _isHighSurrogate(int codeUnit) => codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
  bool _isLowSurrogate(int codeUnit) => codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;

  List<InlineSpan> _buildInlineChildren(
    BuildContext context,
    List<md.Node> nodes,
    MarkdownTheme theme,
  ) {
    final spans = <InlineSpan>[];

    for (final node in nodes) {
      if (node is md.Text) {
        spans.add(TextSpan(text: _sanitizeUtf16(node.text)));
      } else if (node is md.Element) {
        spans.addAll(_buildInlineElement(context, node, theme));
      }
    }

    return spans;
  }

  List<InlineSpan> _buildInlineElement(
    BuildContext context,
    md.Element element,
    MarkdownTheme theme,
  ) {
    switch (element.tag) {
      case 'strong':
        return [
          TextSpan(
            style: const TextStyle(fontWeight: FontWeight.bold),
            children: _buildInlineChildren(context, element.children ?? [], theme),
          )
        ];
      case 'em':
        return [
          TextSpan(
            style: const TextStyle(fontStyle: FontStyle.italic),
            children: _buildInlineChildren(context, element.children ?? [], theme),
          )
        ];
      case 'code':
        return [
          TextSpan(
            text: _sanitizeUtf16(element.textContent),
            style: theme.codeStyle,
          )
        ];
      case 'a':
        final href = element.attributes['href'];
        return [
          TextSpan(
            text: _sanitizeUtf16(element.textContent),
            style: theme.linkStyle,
            recognizer: renderOptions.onLinkTap != null
                ? (TapGestureRecognizer()
                  ..onTap = () => renderOptions.onLinkTap!(
                      href ?? '', element.attributes['title']))
                : null,
          )
        ];
      case 'del':
        if (renderOptions.enableStrikethrough) {
          return [
            TextSpan(
              style: const TextStyle(decoration: TextDecoration.lineThrough),
              children: _buildInlineChildren(context, element.children ?? [], theme),
            )
          ];
        }
        return _buildInlineChildren(context, element.children ?? [], theme);
      case 'latex_inline':
        if (renderOptions.enableLatex) {
          final builder = _builders['latex_inline'] as FormulaBuilder;
          return [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: builder.build(context, element.textContent, theme),
            )
          ];
        }
        return [TextSpan(text: _sanitizeUtf16(element.textContent))];
      default:
        return _buildInlineChildren(context, element.children ?? [], theme);
    }
  }

  List<String> _parseListItems(String content, {required bool ordered}) {
    final pattern = ordered
        ? RegExp(r'^\s*\d+\.\s+', multiLine: true)
        : RegExp(r'^\s*[-*+]\s+', multiLine: true);

    return content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.replaceFirst(pattern, '').trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

/// Base class for custom element builders.
abstract class ElementBuilder {
  /// Builds a widget for the element.
  Widget build(BuildContext context, String content, MarkdownTheme theme);
}

/// Custom inline syntax for LaTeX ($...$).
class _LatexInlineSyntax extends md.InlineSyntax {
  _LatexInlineSyntax() : super(r'\$([^\$]+)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final latex = match[1]!;
    parser.addNode(md.Element.text('latex_inline', latex));
    return true;
  }
}

