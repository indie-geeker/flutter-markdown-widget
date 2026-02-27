// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:markdown/markdown.dart' as md;

import 'content_block.dart';
import 'markdown_parser.dart';

/// Incremental Markdown parser with caching support.
///
/// Parses Markdown text into content blocks, tracking changes
/// between updates for efficient re-rendering.
class IncrementalMarkdownParser implements MarkdownParser {
  static final RegExp _codeFenceStart = RegExp(r'^(`{3,}|~{3,})(.*)$');
  static final RegExp _codeFenceMarker = RegExp(r'^(`{3,}|~{3,})');
  static final RegExp _latexBlockLine = RegExp(r'^\$\$');
  static final RegExp _heading = RegExp(r'^#{1,6}\s');
  static final RegExp _horizontalRule = RegExp(r'^(\*{3,}|-{3,}|_{3,})$');
  static final RegExp _blockquote = RegExp(r'^>');
  static final RegExp _unorderedList = RegExp(r'^[\s]*[-*+]\s');
  static final RegExp _orderedList = RegExp(r'^[\s]*\d+\.\s');
  static final RegExp _imageLine = RegExp(r'^!\[[^\]]*\]\([^)]+\)$');
  static final RegExp _codeLanguage = RegExp(r'^(`{3,}|~{3,})(\w+)?');
  static final RegExp _codeFenceMatches = RegExp(
    r'^(`{3,}|~{3,})',
    multiLine: true,
  );
  static final RegExp _latexFenceMatches = RegExp(r'^\$\$', multiLine: true);
  static final RegExp _headingPrefix = RegExp(r'^(#{1,6})\s');
  static final RegExp _listDepth = RegExp(r'^(\s*)[-*+\d]');
  static final RegExp _openingMarker = RegExp(r'^(`{3,}|~{3,}|\$\$)');

  /// Creates an incremental parser with optional configuration.
  IncrementalMarkdownParser({
    this.enableLatex = true,
    List<md.BlockSyntax>? customBlockSyntaxes,
    List<md.InlineSyntax>? customInlineSyntaxes,
  }) {
    _customBlockSyntaxes = List.unmodifiable(customBlockSyntaxes ?? const []);
    _customInlineSyntaxes = List.unmodifiable(customInlineSyntaxes ?? const []);
    if (_customBlockSyntaxes.isNotEmpty || _customInlineSyntaxes.isNotEmpty) {
      _customDocument = md.Document(
        extensionSet: md.ExtensionSet.gitHubFlavored,
        encodeHtml: false,
        blockSyntaxes: _customBlockSyntaxes.isEmpty
            ? null
            : _customBlockSyntaxes,
        inlineSyntaxes: _customInlineSyntaxes.isEmpty
            ? null
            : _customInlineSyntaxes,
      );
    }
  }

  /// Whether LaTeX parsing is enabled.
  final bool enableLatex;

  late final List<md.BlockSyntax> _customBlockSyntaxes;
  late final List<md.InlineSyntax> _customInlineSyntaxes;
  md.Document? _customDocument;

  /// Cache of previously parsed blocks.
  final List<ContentBlock> _cachedBlocks = [];

  /// Set of indices marked as dirty.
  final Set<int> _dirtyIndices = {};

  /// Last parsed text for change detection.
  String _lastText = '';

  /// Gets the current cached blocks.
  @override
  List<ContentBlock> get cachedBlocks => List.unmodifiable(_cachedBlocks);

  /// Parses text and returns result with change information.
  @override
  ParseResult parse(String text, {bool isStreaming = false}) {
    if (text == _lastText && !isStreaming) {
      return ParseResult(blocks: _cachedBlocks, modifiedIndices: const {});
    }

    final rawBlocks = _splitIntoRawBlocks(text);
    final modifiedIndices = <int>{};
    IncompleteBlock? incomplete;

    // Check for incomplete trailing block in streaming mode
    if (isStreaming && rawBlocks.isNotEmpty) {
      final lastRaw = rawBlocks.last;
      final expectedType = _detectBlockType(lastRaw);
      if (_isIncompleteBlock(lastRaw.content, expectedType)) {
        incomplete = IncompleteBlock(
          partialContent: lastRaw.content,
          expectedType: expectedType,
          openingMarker: _getOpeningMarker(lastRaw),
        );
        // Remove incomplete block from processing
        rawBlocks.removeLast();
      }
    }

    // Process blocks and detect changes
    for (int i = 0; i < rawBlocks.length; i++) {
      final rawBlock = rawBlocks[i];
      final hash = rawBlock.content.hashCode;

      if (i >= _cachedBlocks.length || _cachedBlocks[i].contentHash != hash) {
        modifiedIndices.add(i);
        _dirtyIndices.add(i);
      }
    }

    // Rebuild dirty blocks
    final newBlocks = <ContentBlock>[];
    for (int i = 0; i < rawBlocks.length; i++) {
      if (_dirtyIndices.contains(i) ||
          i >= _cachedBlocks.length ||
          modifiedIndices.contains(i)) {
        newBlocks.add(_parseBlock(rawBlocks[i], i));
      } else {
        newBlocks.add(_cachedBlocks[i]);
      }
    }

    _cachedBlocks
      ..clear()
      ..addAll(newBlocks);
    _dirtyIndices.clear();
    _lastText = text;

    return ParseResult(
      blocks: _cachedBlocks,
      modifiedIndices: modifiedIndices,
      incompleteBlock: incomplete,
    );
  }

  /// Clears all cached state.
  @override
  void reset() {
    _cachedBlocks.clear();
    _dirtyIndices.clear();
    _lastText = '';
  }

  /// Invalidates cached block at index.
  @override
  void invalidate(int index) {
    if (index >= 0 && index < _cachedBlocks.length) {
      _dirtyIndices.add(index);
    }
  }

  /// Invalidates all blocks from index onwards.
  @override
  void invalidateFrom(int startIndex) {
    for (int i = startIndex; i < _cachedBlocks.length; i++) {
      _dirtyIndices.add(i);
    }
  }

  List<_RawBlock> _splitIntoRawBlocks(String text) {
    final blocks = <_RawBlock>[];
    final lines = text.split('\n');
    final buffer = StringBuffer();
    int startLine = 0;
    bool inCodeBlock = false;
    bool inLatexBlock = false;
    String? codeBlockMarker;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Handle code block boundaries
      if (!inLatexBlock) {
        final codeMatch = _codeFenceStart.firstMatch(line);
        if (codeMatch != null) {
          if (!inCodeBlock) {
            // Start code block
            if (buffer.isNotEmpty) {
              blocks.add(
                _RawBlock(
                  content: buffer.toString(),
                  startLine: startLine,
                  endLine: i - 1,
                ),
              );
              buffer.clear();
            }
            inCodeBlock = true;
            codeBlockMarker = codeMatch.group(1);
            startLine = i;
            buffer.writeln(line);
            continue;
          } else if (line.trim().startsWith(codeBlockMarker!.substring(0, 3))) {
            // End code block
            buffer.writeln(line);
            blocks.add(
              _RawBlock(
                content: buffer.toString(),
                startLine: startLine,
                endLine: i,
              ),
            );
            buffer.clear();
            inCodeBlock = false;
            codeBlockMarker = null;
            startLine = i + 1;
            continue;
          }
        }
      }

      // Handle LaTeX block boundaries
      if (!inCodeBlock) {
        if (line.trim().startsWith(r'$$')) {
          if (!inLatexBlock) {
            if (buffer.isNotEmpty) {
              blocks.add(
                _RawBlock(
                  content: buffer.toString(),
                  startLine: startLine,
                  endLine: i - 1,
                ),
              );
              buffer.clear();
            }
            inLatexBlock = true;
            startLine = i;
            buffer.writeln(line);
            // Check if same line closure
            if (line.trim().length > 2 && line.trim().endsWith(r'$$')) {
              blocks.add(
                _RawBlock(
                  content: buffer.toString(),
                  startLine: startLine,
                  endLine: i,
                ),
              );
              buffer.clear();
              inLatexBlock = false;
              startLine = i + 1;
            }
            continue;
          } else {
            buffer.writeln(line);
            blocks.add(
              _RawBlock(
                content: buffer.toString(),
                startLine: startLine,
                endLine: i,
              ),
            );
            buffer.clear();
            inLatexBlock = false;
            startLine = i + 1;
            continue;
          }
        }
      }

      // Normal content
      if (inCodeBlock || inLatexBlock) {
        buffer.writeln(line);
      } else {
        // Split on blank lines for paragraphs
        if (line.trim().isEmpty && buffer.isNotEmpty) {
          blocks.add(
            _RawBlock(
              content: buffer.toString(),
              startLine: startLine,
              endLine: i - 1,
            ),
          );
          buffer.clear();
          startLine = i + 1;
        } else if (line.isNotEmpty || buffer.isNotEmpty) {
          buffer.writeln(line);
        } else {
          startLine = i + 1;
        }
      }
    }

    // Handle remaining content
    if (buffer.isNotEmpty) {
      blocks.add(
        _RawBlock(
          content: buffer.toString(),
          startLine: startLine,
          endLine: lines.length - 1,
        ),
      );
    }

    return blocks;
  }

  ContentBlock _parseBlock(_RawBlock rawBlock, int index) {
    var type = _detectBlockType(rawBlock);
    final metadata = <String, dynamic>{};

    if (type == ContentBlockType.paragraph && _customDocument != null) {
      final customInfo = _tryParseCustomBlock(rawBlock);
      if (customInfo != null) {
        type = ContentBlockType.htmlBlock;
        metadata['tag'] = customInfo.tag;
        metadata['text'] = customInfo.textContent;
        metadata['attributes'] = customInfo.attributes;
      }
    }

    String? language;
    int? headingLevel;
    int? listDepth;

    switch (type) {
      case ContentBlockType.codeBlock:
        language = _extractCodeLanguage(rawBlock.content);
        break;
      case ContentBlockType.heading:
        headingLevel = _extractHeadingLevel(rawBlock.content);
        break;
      case ContentBlockType.unorderedList:
      case ContentBlockType.orderedList:
      case ContentBlockType.listItem:
        listDepth = _extractListDepth(rawBlock.content);
        break;
      default:
        break;
    }

    return ContentBlock(
      type: type,
      rawContent: rawBlock.content,
      contentHash: rawBlock.content.hashCode,
      startLine: rawBlock.startLine,
      endLine: rawBlock.endLine,
      language: language,
      headingLevel: headingLevel,
      listDepth: listDepth,
      metadata: metadata,
    );
  }

  ContentBlockType _detectBlockType(_RawBlock rawBlock) {
    final content = rawBlock.content.trim();

    // Code block
    if (_codeFenceMarker.hasMatch(content)) {
      return ContentBlockType.codeBlock;
    }

    // LaTeX block
    if (_latexBlockLine.hasMatch(content)) {
      return ContentBlockType.latexBlock;
    }

    // Heading
    if (_heading.hasMatch(content)) {
      return ContentBlockType.heading;
    }

    // Horizontal rule
    if (_horizontalRule.hasMatch(content)) {
      return ContentBlockType.horizontalRule;
    }

    // Block quote
    if (_blockquote.hasMatch(content)) {
      return ContentBlockType.blockquote;
    }

    // Image (standalone line)
    if (_imageLine.hasMatch(content)) {
      return ContentBlockType.image;
    }

    // Unordered list
    if (_unorderedList.hasMatch(content)) {
      return ContentBlockType.unorderedList;
    }

    // Ordered list
    if (_orderedList.hasMatch(content)) {
      return ContentBlockType.orderedList;
    }

    // Table (GFM): requires header + alignment row.
    if (_looksLikeGfmTable(content)) {
      return ContentBlockType.table;
    }

    return ContentBlockType.paragraph;
  }

  _CustomBlockInfo? _tryParseCustomBlock(_RawBlock rawBlock) {
    if (_customDocument == null || _customBlockSyntaxes.isEmpty) return null;
    final lines = rawBlock.content.split('\n');
    final nodes = _customDocument!.parseLines(lines);
    if (nodes.length != 1) return null;
    final node = nodes.first;
    if (node is! md.Element) return null;
    final tag = node.tag;
    if (_isBuiltInTag(tag)) return null;

    return _CustomBlockInfo(
      tag: tag,
      textContent: node.textContent,
      attributes: Map<String, String>.from(node.attributes),
    );
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
    };
    return builtInTags.contains(tag);
  }

  bool _isIncompleteBlock(String content, ContentBlockType type) {
    content = content.trim();
    switch (type) {
      case ContentBlockType.codeBlock:
        final fenceMatches = _codeFenceMatches.allMatches(content);
        return fenceMatches.length.isOdd;
      case ContentBlockType.latexBlock:
        final dollarMatches = _latexFenceMatches.allMatches(content);
        return dollarMatches.length.isOdd;
      default:
        return false;
    }
  }

  String? _getOpeningMarker(_RawBlock rawBlock) {
    final match = _openingMarker.firstMatch(rawBlock.content.trim());
    return match?.group(1);
  }

  String? _extractCodeLanguage(String content) {
    final match = _codeLanguage.firstMatch(content.trim());
    return match?.group(2);
  }

  int _extractHeadingLevel(String content) {
    final match = _headingPrefix.firstMatch(content.trim());
    return match?.group(1)?.length ?? 1;
  }

  int _extractListDepth(String content) {
    final match = _listDepth.firstMatch(content);
    final indent = match?.group(1)?.length ?? 0;
    return indent ~/ 2;
  }

  bool _looksLikeGfmTable(String content) {
    final lines = content
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) return false;

    final header = lines[0];
    final alignment = lines[1];

    if (!_looksLikeTableRow(header)) return false;
    if (!_isAlignmentRow(alignment)) return false;

    return true;
  }

  bool _looksLikeTableRow(String row) {
    final cells = _splitTableCells(row);
    return cells.length >= 2;
  }

  bool _isAlignmentRow(String row) {
    final cells = _splitTableCells(row);
    if (cells.length < 2) return false;
    return cells.every((cell) {
      final trimmed = cell.trim();
      return RegExp(r'^:?-{3,}:?$').hasMatch(trimmed);
    });
  }

  List<String> _splitTableCells(String row) {
    var cleaned = row.trim();
    if (cleaned.startsWith('|')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.endsWith('|')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }

    return cleaned.split('|').map((cell) => cell.trim()).toList();
  }
}

/// Raw block before type detection.
class _RawBlock {
  const _RawBlock({
    required this.content,
    required this.startLine,
    required this.endLine,
  });

  final String content;
  final int startLine;
  final int endLine;
}

class _CustomBlockInfo {
  const _CustomBlockInfo({
    required this.tag,
    required this.textContent,
    required this.attributes,
  });

  final String tag;
  final String textContent;
  final Map<String, String> attributes;
}
