// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Type of content block in parsed Markdown.
enum ContentBlockType {
  /// Plain paragraph text.
  paragraph,

  /// Heading (h1-h6).
  heading,

  /// Code block with optional language.
  codeBlock,

  /// Block quote.
  blockquote,

  /// Unordered list.
  unorderedList,

  /// Ordered list.
  orderedList,

  /// List item.
  listItem,

  /// Table.
  table,

  /// Horizontal rule.
  horizontalRule,

  /// LaTeX block formula ($$...$$).
  latexBlock,

  /// Image.
  image,

  /// Thematic break.
  thematicBreak,

  /// Raw HTML block.
  htmlBlock,
}

/// Represents a parsed content block from Markdown source.
///
/// Each block contains the type, raw source, parsed AST nodes,
/// and a content hash for caching purposes.
@immutable
class ContentBlock {
  /// Creates a content block.
  const ContentBlock({
    required this.type,
    required this.rawContent,
    required this.contentHash,
    this.startLine = 0,
    this.endLine = 0,
    this.language,
    this.headingLevel,
    this.listDepth,
    this.metadata = const {},
  });

  /// The type of this block.
  final ContentBlockType type;

  /// Raw source text of this block.
  final String rawContent;

  /// Hash of the content for change detection.
  final int contentHash;

  /// Starting line number in source (0-indexed).
  final int startLine;

  /// Ending line number in source (0-indexed).
  final int endLine;

  /// Programming language for code blocks.
  final String? language;

  /// Heading level (1-6) for heading blocks.
  final int? headingLevel;

  /// Nesting depth for list items.
  final int? listDepth;

  /// Additional metadata for extensibility.
  final Map<String, dynamic> metadata;

  /// Number of lines in this block.
  int get lineCount => endLine - startLine + 1;

  /// Creates a copy with optional field overrides.
  ContentBlock copyWith({
    ContentBlockType? type,
    String? rawContent,
    int? contentHash,
    int? startLine,
    int? endLine,
    String? language,
    int? headingLevel,
    int? listDepth,
    Map<String, dynamic>? metadata,
  }) {
    return ContentBlock(
      type: type ?? this.type,
      rawContent: rawContent ?? this.rawContent,
      contentHash: contentHash ?? this.contentHash,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      language: language ?? this.language,
      headingLevel: headingLevel ?? this.headingLevel,
      listDepth: listDepth ?? this.listDepth,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentBlock &&
          runtimeType == other.runtimeType &&
          contentHash == other.contentHash &&
          startLine == other.startLine;

  @override
  int get hashCode => Object.hash(contentHash, startLine);

  @override
  String toString() =>
      'ContentBlock(type: $type, lines: $startLine-$endLine, hash: $contentHash)';
}

/// Represents an incomplete block during streaming.
///
/// Used to track blocks that are still being received
/// and may not be fully formed yet.
@immutable
class IncompleteBlock {
  /// Creates an incomplete block.
  const IncompleteBlock({
    required this.partialContent,
    required this.expectedType,
    this.openingMarker,
  });

  /// Content received so far.
  final String partialContent;

  /// Expected block type based on opening marker.
  final ContentBlockType expectedType;

  /// Opening marker (e.g., "```" for code blocks).
  final String? openingMarker;

  /// Whether this block appears to be complete.
  bool get isLikelyComplete {
    switch (expectedType) {
      case ContentBlockType.codeBlock:
        // Code block needs closing ```
        if (openingMarker == null) return true;
        final lines = partialContent.split('\n');
        return lines.length > 1 &&
            lines.last.trim().startsWith(openingMarker!.trim().substring(0, 3));
      case ContentBlockType.latexBlock:
        // LaTeX block needs closing $$
        return partialContent.trim().endsWith(r'$$');
      default:
        return true;
    }
  }
}
