// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:markdown/markdown.dart' as md;

import 'ast_models.dart';
import 'content_block.dart';
import 'custom_syntaxes.dart';
import 'markdown_parser.dart';

/// AST-based Markdown parser for static rendering.
///
/// Parses Markdown into a list of [ContentBlock]s with rich AST metadata.
class AstMarkdownParser implements MarkdownParser {
  /// Creates an AST parser with optional configuration.
  AstMarkdownParser({
    this.enableLatex = true,
    this.enableAutolinks = true,
    List<md.BlockSyntax>? customBlockSyntaxes,
    List<md.InlineSyntax>? customInlineSyntaxes,
    md.ExtensionSet? extensionSet,
  }) {
    _customBlockSyntaxes = List.unmodifiable(customBlockSyntaxes ?? const []);
    _customInlineSyntaxes = List.unmodifiable(customInlineSyntaxes ?? const []);

    final inlineSyntaxes = <md.InlineSyntax>[
      ..._customInlineSyntaxes,
      if (enableLatex) LatexInlineSyntax(),
      if (enableAutolinks) AutoLinkSyntax(),
    ];

    final blockSyntaxes = <md.BlockSyntax>[
      ..._customBlockSyntaxes,
      if (enableLatex) LatexBlockSyntax(),
    ];

    _document = md.Document(
      extensionSet: extensionSet ?? md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
      inlineSyntaxes: inlineSyntaxes.isEmpty ? null : inlineSyntaxes,
      blockSyntaxes: blockSyntaxes.isEmpty ? null : blockSyntaxes,
    );
  }

  /// Whether LaTeX parsing is enabled.
  final bool enableLatex;

  /// Whether auto-link parsing is enabled.
  final bool enableAutolinks;

  late final List<md.BlockSyntax> _customBlockSyntaxes;
  late final List<md.InlineSyntax> _customInlineSyntaxes;
  late final md.Document _document;

  /// Cache of previously parsed blocks.
  final List<ContentBlock> _cachedBlocks = [];

  /// Last parsed text for change detection.
  String _lastText = '';

  @override
  List<ContentBlock> get cachedBlocks => List.unmodifiable(_cachedBlocks);

  @override
  ParseResult parse(String text, {bool isStreaming = false}) {
    if (text == _lastText && !isStreaming) {
      return ParseResult(blocks: _cachedBlocks, modifiedIndices: const {});
    }

    final nodes = _document.parseLines(text.split('\n'));
    final blocks = _buildBlocks(nodes);

    final modifiedIndices = <int>{};
    final maxLen = blocks.length > _cachedBlocks.length
        ? blocks.length
        : _cachedBlocks.length;
    for (int i = 0; i < maxLen; i++) {
      if (i >= blocks.length || i >= _cachedBlocks.length) {
        modifiedIndices.add(i);
        continue;
      }
      if (_cachedBlocks[i].contentHash != blocks[i].contentHash) {
        modifiedIndices.add(i);
      }
    }

    _cachedBlocks
      ..clear()
      ..addAll(blocks);
    _lastText = text;

    return ParseResult(blocks: _cachedBlocks, modifiedIndices: modifiedIndices);
  }

  @override
  void reset() {
    _cachedBlocks.clear();
    _lastText = '';
  }

  @override
  void invalidate(int index) {
    if (index >= 0 && index < _cachedBlocks.length) {
      // No partial invalidation for AST; clear to force rebuild.
      _lastText = '';
    }
  }

  @override
  void invalidateFrom(int startIndex) {
    if (startIndex < _cachedBlocks.length) {
      _lastText = '';
    }
  }

  List<ContentBlock> _buildBlocks(List<md.Node> nodes) {
    final blocks = <ContentBlock>[];
    for (final node in nodes) {
      blocks.addAll(_nodeToBlocks(node));
    }
    return blocks;
  }

  List<ContentBlock> _nodeToBlocks(md.Node node) {
    if (node is md.Text) {
      return [
        _buildParagraph([node], rawContent: node.text),
      ];
    }
    if (node is! md.Element) {
      return [];
    }

    final tag = node.tag;
    switch (tag) {
      case 'p':
        return [
          _buildParagraph(
            node.children ?? const [],
            rawContent: node.textContent,
          ),
        ];
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        return [
          _buildHeading(
            _headingLevel(tag),
            node.children ?? const [],
            rawContent: node.textContent,
          ),
        ];
      case 'pre':
        return [_buildCodeBlock(node)];
      case 'blockquote':
        return [_buildBlockquote(node)];
      case 'ul':
      case 'ol':
        return [_buildList(node, ordered: tag == 'ol')];
      case 'table':
        return [_buildTable(node)];
      case 'hr':
        return [
          _buildSimpleBlock(ContentBlockType.horizontalRule, rawContent: '---'),
        ];
      case 'img':
        return [_buildImage(node)];
      case 'latex_block':
        return [_buildLatexBlock(node)];
      default:
        if (!_isBuiltInTag(tag)) {
          return [_buildCustomBlock(node)];
        }
        // Fallback: treat unknown built-in elements as paragraph.
        return [
          _buildParagraph(
            node.children ?? const [],
            rawContent: node.textContent,
          ),
        ];
    }
  }

  ContentBlock _buildParagraph(
    List<md.Node> inlineNodes, {
    required String rawContent,
  }) {
    final ast = AstBlockData(inlineNodes: inlineNodes);
    return _contentBlock(
      type: ContentBlockType.paragraph,
      rawContent: rawContent,
      ast: ast,
    );
  }

  ContentBlock _buildHeading(
    int level,
    List<md.Node> inlineNodes, {
    required String rawContent,
  }) {
    final ast = AstBlockData(inlineNodes: inlineNodes);
    return _contentBlock(
      type: ContentBlockType.heading,
      rawContent: rawContent,
      headingLevel: level,
      ast: ast,
    );
  }

  ContentBlock _buildCodeBlock(md.Element preElement) {
    md.Element? codeElement;
    for (final child in preElement.children ?? const []) {
      if (child is md.Element && child.tag == 'code') {
        codeElement = child;
        break;
      }
    }

    final codeText = codeElement?.textContent ?? preElement.textContent;
    final langClass = codeElement?.attributes['class'];
    String? language;
    if (langClass != null && langClass.startsWith('language-')) {
      language = langClass.substring('language-'.length);
    }

    return _contentBlock(
      type: ContentBlockType.codeBlock,
      rawContent: codeText,
      language: language,
    );
  }

  ContentBlock _buildBlockquote(md.Element element) {
    final children = _buildBlocks(element.children ?? const []);
    final ast = AstBlockData(children: children);
    return _contentBlock(
      type: ContentBlockType.blockquote,
      rawContent: element.textContent,
      ast: ast,
    );
  }

  ContentBlock _buildList(md.Element element, {required bool ordered}) {
    final items = <AstListItem>[];
    for (final child in element.children ?? const []) {
      if (child is md.Element && child.tag == 'li') {
        items.add(_parseListItem(child));
      }
    }

    final listData = AstListData(
      ordered: ordered,
      start: _parseListStart(element),
      items: items,
    );

    final rawText = items
        .map((item) => _inlineText(item.inlineNodes))
        .where((text) => text.isNotEmpty)
        .join('\n');

    return _contentBlock(
      type: ordered
          ? ContentBlockType.orderedList
          : ContentBlockType.unorderedList,
      rawContent: rawText,
      ast: AstBlockData(listData: listData),
    );
  }

  AstListItem _parseListItem(md.Element li) {
    final children = li.children ?? const [];
    List<md.Node> inlineNodes = [];
    final nestedBlocks = <ContentBlock>[];

    for (final child in children) {
      if (child is md.Element && _isBlockTag(child.tag)) {
        if (inlineNodes.isEmpty && child.tag == 'p') {
          inlineNodes = child.children ?? const [];
        } else {
          nestedBlocks.addAll(_nodeToBlocks(child));
        }
      } else {
        inlineNodes.add(child);
      }
    }

    final (normalizedNodes, checked) = _stripTaskMarker(inlineNodes);

    return AstListItem(
      inlineNodes: normalizedNodes,
      checked: checked,
      children: nestedBlocks,
    );
  }

  (List<md.Node>, bool?) _stripTaskMarker(List<md.Node> nodes) {
    if (nodes.isEmpty) return (nodes, null);

    final normalized = List<md.Node>.from(nodes);
    bool? checked;

    final first = normalized.first;
    if (first is md.Element && first.tag == 'input') {
      final isChecked = first.attributes['checked'];
      checked = isChecked == 'checked' || isChecked == 'true';
      normalized.removeAt(0);
      _trimLeadingText(normalized);
      return (normalized, checked);
    }

    if (first is md.Text) {
      final match = RegExp(r'^\s*\[( |x|X)\]\s+').firstMatch(first.text);
      if (match != null) {
        checked = match.group(1)!.toLowerCase() == 'x';
        final trimmed = first.text.replaceFirst(match.group(0)!, '');
        normalized[0] = md.Text(trimmed);
      }
    }

    return (normalized, checked);
  }

  void _trimLeadingText(List<md.Node> nodes) {
    if (nodes.isEmpty) return;
    final first = nodes.first;
    if (first is md.Text && first.text.isNotEmpty) {
      nodes[0] = md.Text(first.text.replaceFirst(RegExp(r'^\s+'), ''));
    }
  }

  ContentBlock _buildTable(md.Element table) {
    final tableData = _parseTable(table);
    if (tableData == null) {
      return _contentBlock(
        type: ContentBlockType.table,
        rawContent: table.textContent,
      );
    }

    return _contentBlock(
      type: ContentBlockType.table,
      rawContent: table.textContent,
      ast: AstBlockData(tableData: tableData),
    );
  }

  AstTableData? _parseTable(md.Element table) {
    final headerRows = <md.Element>[];
    final bodyRows = <md.Element>[];

    for (final child in table.children ?? const []) {
      if (child is! md.Element) continue;
      if (child.tag == 'thead') {
        headerRows.addAll(_findRows(child));
      } else if (child.tag == 'tbody') {
        bodyRows.addAll(_findRows(child));
      } else if (child.tag == 'tr') {
        bodyRows.add(child);
      }
    }

    md.Element? headerRow = headerRows.isNotEmpty ? headerRows.first : null;
    if (headerRow == null && bodyRows.isNotEmpty) {
      final firstRow = bodyRows.first;
      if (_rowHasHeaderCells(firstRow)) {
        headerRow = firstRow;
        bodyRows.removeAt(0);
      }
    }

    if (headerRow == null && bodyRows.isEmpty) {
      return null;
    }

    if (headerRow == null && bodyRows.isNotEmpty) {
      headerRow = bodyRows.removeAt(0);
    }

    final headers = _parseRowCells(headerRow!, header: true);
    final alignments = _parseAlignments(headerRow);
    final rows = <List<List<md.Node>>>[];

    for (final row in bodyRows) {
      rows.add(_parseRowCells(row, header: false));
    }

    return AstTableData(headers: headers, alignments: alignments, rows: rows);
  }

  List<md.Element> _findRows(md.Element element) {
    return (element.children ?? const [])
        .whereType<md.Element>()
        .where((e) => e.tag == 'tr')
        .toList();
  }

  bool _rowHasHeaderCells(md.Element row) {
    return (row.children ?? const []).whereType<md.Element>().any(
      (e) => e.tag == 'th',
    );
  }

  List<List<md.Node>> _parseRowCells(md.Element row, {required bool header}) {
    final cellTag = header ? 'th' : 'td';
    final cells = <List<md.Node>>[];
    for (final child in row.children ?? const []) {
      if (child is md.Element &&
          (child.tag == cellTag || child.tag == 'td' || child.tag == 'th')) {
        cells.add(child.children ?? [md.Text(child.textContent)]);
      }
    }
    return cells;
  }

  List<AstTableAlignment> _parseAlignments(md.Element row) {
    final alignments = <AstTableAlignment>[];
    for (final child in row.children ?? const []) {
      if (child is! md.Element) continue;
      if (child.tag != 'th' && child.tag != 'td') continue;
      final alignAttr = child.attributes['align'];
      switch (alignAttr) {
        case 'center':
          alignments.add(AstTableAlignment.center);
          break;
        case 'right':
          alignments.add(AstTableAlignment.right);
          break;
        default:
          alignments.add(AstTableAlignment.left);
      }
    }
    return alignments;
  }

  ContentBlock _buildImage(md.Element element) {
    final src = element.attributes['src'] ?? '';
    final alt = element.attributes['alt'] ?? '';
    final ast = AstBlockData(imageAlt: alt, imageSrc: src);
    final raw = src.isNotEmpty ? '![$alt]($src)' : element.textContent;
    return _contentBlock(
      type: ContentBlockType.image,
      rawContent: raw,
      ast: ast,
    );
  }

  ContentBlock _buildLatexBlock(md.Element element) {
    return _contentBlock(
      type: ContentBlockType.latexBlock,
      rawContent: element.textContent,
    );
  }

  ContentBlock _buildCustomBlock(md.Element element) {
    final ast = AstBlockData(
      attributes: Map<String, String>.from(element.attributes),
    );
    return _contentBlock(
      type: ContentBlockType.htmlBlock,
      rawContent: element.textContent,
      metadata: {
        'tag': element.tag,
        'text': element.textContent,
        'attributes': Map<String, String>.from(element.attributes),
      },
      ast: ast,
    );
  }

  ContentBlock _buildSimpleBlock(
    ContentBlockType type, {
    required String rawContent,
  }) {
    return _contentBlock(type: type, rawContent: rawContent);
  }

  ContentBlock _contentBlock({
    required ContentBlockType type,
    required String rawContent,
    int? headingLevel,
    String? language,
    AstBlockData? ast,
    Map<String, dynamic>? metadata,
  }) {
    final meta = <String, dynamic>{
      if (metadata != null) ...metadata,
      if (ast != null) kAstDataKey: ast,
    };

    final signature = _signatureForBlock(
      type: type,
      rawContent: rawContent,
      headingLevel: headingLevel,
      language: language,
      ast: ast,
    );

    return ContentBlock(
      type: type,
      rawContent: rawContent,
      contentHash: signature.hashCode,
      headingLevel: headingLevel,
      language: language,
      metadata: meta,
    );
  }

  String _signatureForBlock({
    required ContentBlockType type,
    required String rawContent,
    int? headingLevel,
    String? language,
    AstBlockData? ast,
  }) {
    final buffer = StringBuffer()
      ..write(type.name)
      ..write('|')
      ..write(headingLevel ?? '')
      ..write('|')
      ..write(language ?? '')
      ..write('|')
      ..write(rawContent);

    if (ast != null) {
      if (ast.inlineNodes != null) {
        buffer
          ..write('|inline:')
          ..write(_inlineSignature(ast.inlineNodes!));
      }
      if (ast.listData != null) {
        buffer
          ..write('|list:')
          ..write(_listSignature(ast.listData!));
      }
      if (ast.tableData != null) {
        buffer
          ..write('|table:')
          ..write(_tableSignature(ast.tableData!));
      }
      if (ast.children != null) {
        buffer
          ..write('|children:')
          ..write(
            ast.children!
                .map((child) => child.contentHash.toString())
                .join(','),
          );
      }
      if (ast.imageSrc != null || ast.imageAlt != null) {
        buffer
          ..write('|image:')
          ..write(ast.imageAlt ?? '')
          ..write('|')
          ..write(ast.imageSrc ?? '');
      }
    }

    return buffer.toString();
  }

  String _inlineSignature(List<md.Node> nodes) {
    return nodes.map(_nodeSignature).join();
  }

  String _nodeSignature(md.Node node) {
    if (node is md.Text) {
      return 't:${node.text}';
    }
    if (node is md.Element) {
      final attrs = node.attributes.entries
          .map((e) => '${e.key}=${e.value}')
          .join(',');
      final children = (node.children ?? const []).map(_nodeSignature).join();
      return 'e:${node.tag}[$attrs]{$children}';
    }
    return node.toString();
  }

  String _listSignature(AstListData listData) {
    final items = listData.items
        .map((item) {
          final inlineSig = _inlineSignature(item.inlineNodes);
          final childSig = item.children.map((b) => b.contentHash).join(',');
          return '${item.checked}|$inlineSig|$childSig';
        })
        .join(';');
    return '${listData.ordered}:${listData.start ?? ''}:$items';
  }

  String _tableSignature(AstTableData tableData) {
    final headerSig = tableData.headers.map(_inlineSignature).join('|');
    final rowSig = tableData.rows
        .map((row) => row.map(_inlineSignature).join('|'))
        .join(';');
    return '${tableData.alignments.map((a) => a.name).join(',')}|$headerSig|$rowSig';
  }

  int _headingLevel(String tag) {
    final level = tag.replaceFirst('h', '');
    return int.tryParse(level) ?? 1;
  }

  int? _parseListStart(md.Element element) {
    final start = element.attributes['start'];
    if (start == null) return null;
    return int.tryParse(start);
  }

  String _inlineText(List<md.Node> nodes) {
    return nodes.map((n) => n.textContent).join();
  }

  bool _isBuiltInTag(String tag) {
    const builtInTags = {
      'p',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'pre',
      'code',
      'blockquote',
      'ul',
      'ol',
      'li',
      'table',
      'thead',
      'tbody',
      'tr',
      'td',
      'th',
      'hr',
      'img',
      'latex_block',
    };
    return builtInTags.contains(tag);
  }

  bool _isBlockTag(String tag) {
    return _isBuiltInTag(tag) &&
        tag != 'code' &&
        tag != 'img' &&
        tag != 'latex_inline';
  }
}
