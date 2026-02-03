// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

/// Parser interface for markdown content.
abstract class MarkdownParser {
  /// Parses text and returns result with change information.
  ParseResult parse(String text, {bool isStreaming = false});

  /// Clears all cached state.
  void reset();

  /// Invalidates cached block at index.
  void invalidate(int index);

  /// Invalidates all blocks from index onwards.
  void invalidateFrom(int startIndex);

  /// Gets the current cached blocks.
  List<ContentBlock> get cachedBlocks;
}
