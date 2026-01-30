// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:markdown/markdown.dart' as md;

import 'content_block.dart';

/// Result of incremental parsing.
class ParseResult {
  /// Creates a parse result.
  const ParseResult({
    required this.blocks,
    required this.modifiedIndices,
    this.incompleteBlock,
  });

  /// All parsed blocks.
  final List<ContentBlock> blocks;

  /// Indices of blocks that changed since last parse.
  final Set<int> modifiedIndices;

  /// Trailing incomplete block during streaming.
  final IncompleteBlock? incompleteBlock;

  /// Whether any blocks were modified.
  bool get hasChanges => modifiedIndices.isNotEmpty;
}

/// Incremental Markdown parser with caching support.
///
/// Parses Markdown text into content blocks, tracking changes
/// between updates for efficient re-rendering.
class IncrementalMarkdownParser {
  /// Creates an incremental parser with optional configuration.
  IncrementalMarkdownParser({
    this.enableLatex = true,
    List<md.BlockSyntax>? customBlockSyntaxes,
    List<md.InlineSyntax>? customInlineSyntaxes,
  }) {
    _blockSyntaxes = [
      ...?customBlockSyntaxes,
      if (enableLatex) _LatexBlockSyntax(),
    ];
    _inlineSyntaxes = [
      ...?customInlineSyntaxes,
      if (enableLatex) _LatexInlineSyntax(),
    ];
  }

  /// Whether LaTeX parsing is enabled.
  final bool enableLatex;

  late final List<md.BlockSyntax> _blockSyntaxes;
  late final List<md.InlineSyntax> _inlineSyntaxes;

  /// Cache of previously parsed blocks.
  final List<ContentBlock> _cachedBlocks = [];

  /// Set of indices marked as dirty.
  final Set<int> _dirtyIndices = {};

  /// Last parsed text for change detection.
  String _lastText = '';

  /// Gets the current cached blocks.
  List<ContentBlock> get cachedBlocks => List.unmodifiable(_cachedBlocks);

  /// Parses text and returns result with change information.
  ParseResult parse(String text, {bool isStreaming = false}) {
    if (text == _lastText && !isStreaming) {
      return ParseResult(
        blocks: _cachedBlocks,
        modifiedIndices: const {},
      );
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
  void reset() {
    _cachedBlocks.clear();
    _dirtyIndices.clear();
    _lastText = '';
  }

  /// Invalidates cached block at index.
  void invalidate(int index) {
    if (index >= 0 && index < _cachedBlocks.length) {
      _dirtyIndices.add(index);
    }
  }

  /// Invalidates all blocks from index onwards.
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
        final codeMatch = RegExp(r'^(`{3,}|~{3,})(.*)$').firstMatch(line);
        if (codeMatch != null) {
          if (!inCodeBlock) {
            // Start code block
            if (buffer.isNotEmpty) {
              blocks.add(_RawBlock(
                content: buffer.toString(),
                startLine: startLine,
                endLine: i - 1,
              ));
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
            blocks.add(_RawBlock(
              content: buffer.toString(),
              startLine: startLine,
              endLine: i,
            ));
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
              blocks.add(_RawBlock(
                content: buffer.toString(),
                startLine: startLine,
                endLine: i - 1,
              ));
              buffer.clear();
            }
            inLatexBlock = true;
            startLine = i;
            buffer.writeln(line);
            // Check if same line closure
            if (line.trim().length > 2 && line.trim().endsWith(r'$$')) {
              blocks.add(_RawBlock(
                content: buffer.toString(),
                startLine: startLine,
                endLine: i,
              ));
              buffer.clear();
              inLatexBlock = false;
              startLine = i + 1;
            }
            continue;
          } else {
            buffer.writeln(line);
            blocks.add(_RawBlock(
              content: buffer.toString(),
              startLine: startLine,
              endLine: i,
            ));
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
          blocks.add(_RawBlock(
            content: buffer.toString(),
            startLine: startLine,
            endLine: i - 1,
          ));
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
      blocks.add(_RawBlock(
        content: buffer.toString(),
        startLine: startLine,
        endLine: lines.length - 1,
      ));
    }

    return blocks;
  }

  ContentBlock _parseBlock(_RawBlock rawBlock, int index) {
    final type = _detectBlockType(rawBlock);
    final metadata = <String, dynamic>{};

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
    if (RegExp(r'^(`{3,}|~{3,})').hasMatch(content)) {
      return ContentBlockType.codeBlock;
    }

    // LaTeX block
    if (content.startsWith(r'$$')) {
      return ContentBlockType.latexBlock;
    }

    // Heading
    if (RegExp(r'^#{1,6}\s').hasMatch(content)) {
      return ContentBlockType.heading;
    }

    // Horizontal rule
    if (RegExp(r'^(\*{3,}|-{3,}|_{3,})$').hasMatch(content)) {
      return ContentBlockType.horizontalRule;
    }

    // Block quote
    if (content.startsWith('>')) {
      return ContentBlockType.blockquote;
    }

    // Unordered list
    if (RegExp(r'^[\s]*[-*+]\s').hasMatch(content)) {
      return ContentBlockType.unorderedList;
    }

    // Ordered list
    if (RegExp(r'^[\s]*\d+\.\s').hasMatch(content)) {
      return ContentBlockType.orderedList;
    }

    // Table (pipe at start of line)
    if (content.contains('|') && RegExp(r'^\|.*\|$', multiLine: true).hasMatch(content)) {
      return ContentBlockType.table;
    }

    return ContentBlockType.paragraph;
  }

  bool _isIncompleteBlock(String content, ContentBlockType type) {
    content = content.trim();
    switch (type) {
      case ContentBlockType.codeBlock:
        final fenceMatches =
            RegExp(r'^(`{3,}|~{3,})', multiLine: true).allMatches(content);
        return fenceMatches.length.isOdd;
      case ContentBlockType.latexBlock:
        final dollarMatches =
            RegExp(r'^\$\$', multiLine: true).allMatches(content);
        return dollarMatches.length.isOdd;
      default:
        return false;
    }
  }

  String? _getOpeningMarker(_RawBlock rawBlock) {
    final match =
        RegExp(r'^(`{3,}|~{3,}|\$\$)').firstMatch(rawBlock.content.trim());
    return match?.group(1);
  }

  String? _extractCodeLanguage(String content) {
    final match = RegExp(r'^(`{3,}|~{3,})(\w+)?').firstMatch(content.trim());
    return match?.group(2);
  }

  int _extractHeadingLevel(String content) {
    final match = RegExp(r'^(#{1,6})\s').firstMatch(content.trim());
    return match?.group(1)?.length ?? 1;
  }

  int _extractListDepth(String content) {
    final match = RegExp(r'^(\s*)[-*+\d]').firstMatch(content);
    final indent = match?.group(1)?.length ?? 0;
    return indent ~/ 2;
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

/// Custom block syntax for LaTeX blocks ($$...$$).
class _LatexBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\$\$\s*$');

  @override
  md.Node? parse(md.BlockParser parser) {
    final buffer = StringBuffer();
    buffer.writeln(parser.current.content);
    parser.advance();

    while (!parser.isDone) {
      final line = parser.current.content;
      buffer.writeln(line);
      if (line.trim() == r'$$') {
        parser.advance();
        break;
      }
      parser.advance();
    }

    return md.Element('latex_block', [md.Text(buffer.toString())]);
  }
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
