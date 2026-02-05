// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

import '../core/parser/content_block.dart';
import '../core/parser/ast_models.dart';
import '../core/parser/custom_syntaxes.dart';
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
      'table': TableNodeBuilder(
        inlineSpanBuilder: _buildInlineSpan,
        selectableText: renderOptions.selectableText,
      ),
      ...?customBuilders,
    };

    final inlineSyntaxes = <md.InlineSyntax>[];
    if (renderOptions.customInlineSyntaxes != null) {
      inlineSyntaxes.addAll(renderOptions.customInlineSyntaxes!);
    }
    if (renderOptions.enableLatex) {
      inlineSyntaxes.add(LatexInlineSyntax());
    }
    if (renderOptions.enableAutolinks) {
      inlineSyntaxes.add(AutoLinkSyntax());
    }

    _document = md.Document(
      extensionSet:
          renderOptions.extensionSet ?? md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
      inlineSyntaxes: inlineSyntaxes.isEmpty ? null : inlineSyntaxes,
    );
  }

  /// Theme for styling.
  final MarkdownTheme? theme;

  /// Render options.
  final RenderOptions renderOptions;

  late final Map<String, ElementBuilder> _builders;

  /// Document for markdown parsing.
  late final md.Document _document;

  /// Builds a widget for a content block.
  Widget buildBlock(BuildContext context, ContentBlock block) {
    // Get base theme from context (which provides default styles from Flutter's ThemeData)
    final baseTheme = MarkdownThemeProvider.of(context);
    // Merge user's theme on top of base theme (user overrides take precedence)
    final effectiveTheme = theme != null ? baseTheme.merge(theme!) : baseTheme;

    return switch (block.type) {
      ContentBlockType.paragraph => _buildParagraph(
        context,
        block,
        effectiveTheme,
      ),
      ContentBlockType.heading => _buildHeading(context, block, effectiveTheme),
      ContentBlockType.codeBlock => _buildCodeBlock(
        context,
        block,
        effectiveTheme,
      ),
      ContentBlockType.blockquote => _buildBlockquote(
        context,
        block,
        effectiveTheme,
      ),
      ContentBlockType.unorderedList => _buildUnorderedList(
        context,
        block,
        effectiveTheme,
      ),
      ContentBlockType.orderedList => _buildOrderedList(
        context,
        block,
        effectiveTheme,
      ),
      ContentBlockType.listItem => _buildListItem(
        context,
        block,
        effectiveTheme,
      ),
      ContentBlockType.table =>
        renderOptions.enableTables
            ? _buildTable(context, block, effectiveTheme)
            : _buildParagraph(context, block, effectiveTheme),
      ContentBlockType.horizontalRule => _buildHorizontalRule(
        context,
        effectiveTheme,
      ),
      ContentBlockType.latexBlock => _buildLatexBlock(
        context,
        block,
        effectiveTheme,
      ),
      ContentBlockType.image => _buildImage(context, block, effectiveTheme),
      ContentBlockType.thematicBreak => _buildHorizontalRule(
        context,
        effectiveTheme,
      ),
      ContentBlockType.htmlBlock => _buildCustomOrHtmlBlock(
        context,
        block,
        effectiveTheme,
      ),
    };
  }

  Widget _buildCustomOrHtmlBlock(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    final tag = block.metadata['tag'];
    final content = block.metadata['text'] is String
        ? block.metadata['text'] as String
        : null;
    final attributes = block.metadata['attributes'] is Map
        ? block.metadata['attributes'] as Map
        : null;

    if (tag is String && _builders.containsKey(tag)) {
      final builder = _builders[tag]!;
      final attrs = <String, String>{};
      if (attributes != null) {
        for (final entry in attributes.entries) {
          if (entry.key is String && entry.value is String) {
            attrs[entry.key as String] = entry.value as String;
          }
        }
      }
      return builder.buildWithAttributes(
        context,
        content ?? block.rawContent,
        theme,
        attrs,
      );
    }

    return _buildParagraph(context, block, theme);
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
    final inlineSpan = _buildInlineSpanFromBlock(
      context,
      block,
      theme,
      fallbackText: text,
      baseStyle: theme.textStyle,
    );

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
    final text = block.rawContent
        .replaceFirst(RegExp(r'^#{1,6}\s+'), '')
        .trim();
    final style = theme.headingStyle(level);
    final inlineSpan = _buildInlineSpanFromBlock(
      context,
      block,
      theme,
      fallbackText: text,
      baseStyle: style ?? theme.textStyle,
    );

    return Padding(
      padding: EdgeInsets.only(
        top: theme.headingSpacing ?? 24,
        bottom: (theme.headingSpacing ?? 24) / 2,
      ),
      child: renderOptions.selectableText
          ? SelectableText.rich(inlineSpan)
          : RichText(text: inlineSpan),
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
      showLineNumbers: renderOptions.enableCodeHighlight,
      showLanguageLabel: renderOptions.enableCodeHighlight,
      showCopyButton: renderOptions.enableCodeHighlight,
      maxHeight: renderOptions.codeBlockMaxHeight,
    );
  }

  Widget _buildBlockquote(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    final ast = _getAst(block);
    final children = ast?.children;
    final inlineSpan = children == null || children.isEmpty
        ? _buildInlineSpan(
            context,
            block.rawContent
                .split('\n')
                .map((line) => line.replaceFirst(RegExp(r'^>\s?'), ''))
                .join('\n')
                .trim(),
            theme,
            baseStyle: theme.blockquoteStyle ?? theme.textStyle,
          )
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: theme.blockSpacing ?? 16),
      padding:
          theme.blockquotePadding ??
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
      child: children != null && children.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.asMap().entries.map((entry) {
                final isLast = entry.key == children.length - 1;
                final child = entry.value;
                return _buildBlockquoteChild(
                  context,
                  child,
                  theme,
                  isLast: isLast,
                );
              }).toList(),
            )
          : (renderOptions.selectableText
                ? SelectableText.rich(inlineSpan!)
                : RichText(text: inlineSpan!)),
    );
  }

  Widget _buildBlockquoteChild(
    BuildContext context,
    ContentBlock child,
    MarkdownTheme theme, {
    required bool isLast,
  }) {
    if (child.type == ContentBlockType.paragraph) {
      final inlineSpan = _buildInlineSpanFromBlock(
        context,
        child,
        theme,
        fallbackText: child.rawContent.trim(),
        baseStyle: theme.blockquoteStyle ?? theme.textStyle,
      );
      return Padding(
        padding: EdgeInsets.only(
          bottom: isLast ? 0 : (theme.paragraphSpacing ?? 16),
        ),
        child: renderOptions.selectableText
            ? SelectableText.rich(inlineSpan)
            : RichText(text: inlineSpan),
      );
    }

    final widget = buildBlock(context, child);
    if (!isLast || widget is! Padding || widget.padding is! EdgeInsets) {
      return widget;
    }
    final padding = widget.padding as EdgeInsets;
    return Padding(padding: padding.copyWith(bottom: 0), child: widget.child);
  }

  Widget _buildUnorderedList(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme,
  ) {
    final ast = _getAst(block);
    if (ast?.listData != null) {
      return _buildAstList(context, ast!.listData!, theme);
    }
    final items = _parseListItems(
      block.rawContent,
      ordered: false,
      enableTaskLists: renderOptions.enableTaskLists,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: theme.blockSpacing ?? 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          final inlineSpan = _buildInlineSpan(
            context,
            item.text,
            theme,
            baseStyle: theme.textStyle,
          );
          return Padding(
            padding: EdgeInsets.only(left: theme.listIndent ?? 24, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isTask) ...[
                  _buildTaskCheckbox(item.isChecked, theme),
                  const SizedBox(width: 4),
                ] else
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
    final ast = _getAst(block);
    if (ast?.listData != null) {
      return _buildAstList(context, ast!.listData!, theme);
    }
    final items = _parseListItems(
      block.rawContent,
      ordered: true,
      enableTaskLists: renderOptions.enableTaskLists,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: theme.blockSpacing ?? 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final inlineSpan = _buildInlineSpan(
            context,
            entry.value.text,
            theme,
            baseStyle: theme.textStyle,
          );
          return Padding(
            padding: EdgeInsets.only(left: theme.listIndent ?? 24, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${entry.key + 1}. ',
                    style: theme.listBulletStyle,
                  ),
                ),
                if (entry.value.isTask) ...[
                  _buildTaskCheckbox(entry.value.isChecked, theme),
                  const SizedBox(width: 4),
                ],
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
    final text = block.rawContent.replaceFirst(
      RegExp(r'^[\s]*[-*+\d.]+\s+'),
      '',
    );
    final inlineSpan = _buildInlineSpan(
      context,
      text,
      theme,
      baseStyle: theme.textStyle,
    );
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
    final ast = _getAst(block);
    if (ast?.tableData != null) {
      return _buildAstTable(context, ast!.tableData!, theme);
    }
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
    final ast = _getAst(block);
    String alt = ast?.imageAlt ?? '';
    String src = ast?.imageSrc ?? '';

    if (src.isEmpty) {
      final match = RegExp(
        r'!\[([^\]]*)\]\(([^)]+)\)',
      ).firstMatch(block.rawContent);
      if (match == null) {
        return const SizedBox.shrink();
      }
      alt = match.group(1) ?? '';
      src = match.group(2) ?? '';
    }

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

    if (renderOptions.maxImageWidth != null ||
        renderOptions.maxImageHeight != null) {
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
    MarkdownTheme theme, {
    TextStyle? baseStyle,
  }) {
    // Sanitize text to prevent UTF-16 encoding errors during streaming
    final safeText = _sanitizeUtf16(text);
    if (!_needsMarkdownParsing(safeText)) {
      return TextSpan(style: baseStyle ?? theme.textStyle, text: safeText);
    }
    final nodes = _document.parseInline(safeText);
    return TextSpan(
      style: baseStyle ?? theme.textStyle,
      children: _buildInlineChildren(context, nodes, theme),
    );
  }

  TextSpan _buildInlineSpanFromBlock(
    BuildContext context,
    ContentBlock block,
    MarkdownTheme theme, {
    required String fallbackText,
    TextStyle? baseStyle,
  }) {
    final ast = _getAst(block);
    final nodes = ast?.inlineNodes;
    if (nodes == null || nodes.isEmpty) {
      return _buildInlineSpan(
        context,
        fallbackText,
        theme,
        baseStyle: baseStyle,
      );
    }
    return _buildInlineSpanFromNodes(
      context,
      nodes,
      theme,
      baseStyle: baseStyle,
    );
  }

  TextSpan _buildInlineSpanFromNodes(
    BuildContext context,
    List<md.Node> nodes,
    MarkdownTheme theme, {
    TextStyle? baseStyle,
  }) {
    return TextSpan(
      style: baseStyle ?? theme.textStyle,
      children: _buildInlineChildren(context, nodes, theme),
    );
  }

  bool _needsMarkdownParsing(String text) {
    if (text.isEmpty) return false;

    if (renderOptions.enableAutolinks &&
        (text.contains('http://') ||
            text.contains('https://') ||
            text.contains('www.'))) {
      return true;
    }

    if (renderOptions.enableLatex && text.contains(r'$')) {
      return true;
    }

    if (renderOptions.enableStrikethrough && text.contains('~')) {
      return true;
    }

    const markers = ['*', '_', '`', '[', ']', '!', '<', '>'];
    for (final marker in markers) {
      if (text.contains(marker)) {
        return true;
      }
    }

    return false;
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

  bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
  bool _isLowSurrogate(int codeUnit) =>
      codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;

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
      case 'br':
        return [const TextSpan(text: '\n')];
      case 'strong':
        return [
          TextSpan(
            style: const TextStyle(fontWeight: FontWeight.bold),
            children: _buildInlineChildren(
              context,
              element.children ?? [],
              theme,
            ),
          ),
        ];
      case 'em':
        return [
          TextSpan(
            style: const TextStyle(fontStyle: FontStyle.italic),
            children: _buildInlineChildren(
              context,
              element.children ?? [],
              theme,
            ),
          ),
        ];
      case 'code':
        if (!renderOptions.enableCodeHighlight) {
          return [TextSpan(text: _sanitizeUtf16(element.textContent))];
        }
        return [
          TextSpan(
            text: _sanitizeUtf16(element.textContent),
            style: theme.codeStyle,
          ),
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
                      href ?? '',
                      element.attributes['title'],
                    ))
                : null,
          ),
        ];
      case 'del':
        if (renderOptions.enableStrikethrough) {
          return [
            TextSpan(
              style: const TextStyle(decoration: TextDecoration.lineThrough),
              children: _buildInlineChildren(
                context,
                element.children ?? [],
                theme,
              ),
            ),
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
            ),
          ];
        }
        return [TextSpan(text: _sanitizeUtf16(element.textContent))];
      case 'img':
      case 'image':
        return _buildInlineImage(context, element, theme);
      default:
        final customBuilder = _builders[element.tag];
        if (customBuilder != null) {
          return [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: customBuilder.buildWithAttributes(
                context,
                element.textContent,
                theme,
                element.attributes,
              ),
            ),
          ];
        }
        return _buildInlineChildren(context, element.children ?? [], theme);
    }
  }

  List<_ListItemData> _parseListItems(
    String content, {
    required bool ordered,
    required bool enableTaskLists,
  }) {
    final pattern = ordered
        ? RegExp(r'^\s*\d+\.\s+', multiLine: true)
        : RegExp(r'^\s*[-*+]\s+', multiLine: true);
    final taskPattern = ordered
        ? RegExp(r'^\s*\d+\.\s+\[( |x|X)\]\s+')
        : RegExp(r'^\s*[-*+]\s+\[( |x|X)\]\s+');

    return content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          String working = line.trimRight();
          bool? checked;
          if (enableTaskLists) {
            final taskMatch = taskPattern.firstMatch(working);
            if (taskMatch != null) {
              checked = taskMatch.group(1)!.toLowerCase() == 'x';
              working = working.replaceFirst(taskPattern, '');
            } else {
              working = working.replaceFirst(pattern, '');
            }
          } else {
            working = working.replaceFirst(pattern, '');
          }
          return _ListItemData(text: working.trim(), isChecked: checked);
        })
        .where((item) => item.text.isNotEmpty)
        .toList();
  }

  Widget _buildTaskCheckbox(bool? isChecked, MarkdownTheme theme) {
    final color = theme.textStyle?.color ?? Colors.grey;
    final textStyle = theme.textStyle ??
        theme.listBulletStyle ??
        const TextStyle(fontSize: 14, height: 1.2);
    final fontSize = textStyle.fontSize ?? 14;
    final lineHeight = fontSize * (textStyle.height ?? 1.2);
    final iconSize = fontSize + 3;
    final topPadding = ((lineHeight - iconSize) / 2)
        .clamp(0.0, lineHeight) as double;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Icon(
        isChecked == true ? Icons.check_box : Icons.check_box_outline_blank,
        size: iconSize,
        color: color.withValues(alpha: 0.7),
      ),
    );
  }

  AstBlockData? _getAst(ContentBlock block) {
    final ast = block.metadata[kAstDataKey];
    return ast is AstBlockData ? ast : null;
  }

  Widget _buildAstList(
    BuildContext context,
    AstListData listData,
    MarkdownTheme theme,
  ) {
    final indent = theme.listIndent ?? 24;
    final start = listData.start ?? 1;
    final items = listData.items;

    return Padding(
      padding: EdgeInsets.only(bottom: theme.blockSpacing ?? 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildAstListItem(
            context,
            item,
            theme,
            ordered: listData.ordered,
            index: start + index,
            depth: 0,
            indent: indent,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAstListItem(
    BuildContext context,
    AstListItem item,
    MarkdownTheme theme, {
    required bool ordered,
    required int index,
    required int depth,
    required double indent,
  }) {
    final inlineSpan = _buildInlineSpanFromNodes(
      context,
      item.inlineNodes,
      theme,
      baseStyle: theme.textStyle,
    );

    final showTask = renderOptions.enableTaskLists && item.checked != null;
    final row = Padding(
      padding: EdgeInsets.only(left: indent * (depth + 1), bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ordered)
            SizedBox(
              width: 24,
              child: Text('$index. ', style: theme.listBulletStyle),
            ),
          if (showTask) ...[
            _buildTaskCheckbox(item.checked, theme),
            const SizedBox(width: 4),
          ] else if (!ordered)
            Text('• ', style: theme.listBulletStyle),
          Expanded(
            child: renderOptions.selectableText
                ? SelectableText.rich(inlineSpan)
                : RichText(text: inlineSpan),
          ),
        ],
      ),
    );

    if (item.children.isEmpty) {
      return row;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: item.children
                .map((child) => buildBlock(context, child))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAstTable(
    BuildContext context,
    AstTableData tableData,
    MarkdownTheme theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: theme.blockSpacing ?? 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(
            color: theme.tableBorderColor ?? Colors.grey,
            borderRadius: BorderRadius.circular(4),
          ),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            TableRow(
              decoration: BoxDecoration(color: theme.tableHeaderColor),
              children: tableData.headers.asMap().entries.map((entry) {
                final alignment = entry.key < tableData.alignments.length
                    ? tableData.alignments[entry.key]
                    : AstTableAlignment.left;
                return _buildAstTableCell(
                  context,
                  entry.value,
                  theme,
                  isHeader: true,
                  alignment: alignment,
                );
              }).toList(),
            ),
            ...tableData.rows.map((row) {
              return TableRow(
                children: row.asMap().entries.map((entry) {
                  final alignment = entry.key < tableData.alignments.length
                      ? tableData.alignments[entry.key]
                      : AstTableAlignment.left;
                  return _buildAstTableCell(
                    context,
                    entry.value,
                    theme,
                    alignment: alignment,
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAstTableCell(
    BuildContext context,
    List<md.Node> nodes,
    MarkdownTheme theme, {
    bool isHeader = false,
    AstTableAlignment alignment = AstTableAlignment.left,
  }) {
    final style = isHeader
        ? theme.tableStyle?.copyWith(fontWeight: FontWeight.bold)
        : theme.tableStyle;
    final inlineSpan = _buildInlineSpanFromNodes(
      context,
      nodes,
      theme,
      baseStyle: style,
    );
    final textAlign = switch (alignment) {
      AstTableAlignment.center => TextAlign.center,
      AstTableAlignment.right => TextAlign.right,
      AstTableAlignment.left => TextAlign.left,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: renderOptions.selectableText
          ? SelectableText.rich(inlineSpan, textAlign: textAlign)
          : RichText(text: inlineSpan, textAlign: textAlign),
    );
  }

  List<InlineSpan> _buildInlineImage(
    BuildContext context,
    md.Element element,
    MarkdownTheme theme,
  ) {
    final src = element.attributes['src'] ?? '';
    final alt = element.attributes['alt'] ?? '';

    if (!renderOptions.enableImageLoading || src.isEmpty) {
      return [TextSpan(text: '[Image: $alt]')];
    }

    Widget image = Image.network(
      src,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text('[Failed to load: $alt]'),
    );

    if (renderOptions.maxImageWidth != null ||
        renderOptions.maxImageHeight != null) {
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

    return [WidgetSpan(alignment: PlaceholderAlignment.middle, child: image)];
  }
}

/// Base class for custom element builders.
abstract class ElementBuilder {
  /// Builds a widget for the element.
  Widget build(BuildContext context, String content, MarkdownTheme theme);

  /// Builds a widget with element attributes.
  ///
  /// Defaults to [build] if not overridden.
  Widget buildWithAttributes(
    BuildContext context,
    String content,
    MarkdownTheme theme,
    Map<String, String> attributes,
  ) {
    return build(context, content, theme);
  }
}

/// Custom inline syntax for LaTeX ($...$).
class _ListItemData {
  const _ListItemData({required this.text, this.isChecked});

  final String text;
  final bool? isChecked;

  bool get isTask => isChecked != null;
}
