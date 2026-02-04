// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../core/parser/content_block.dart';
import '../core/parser/ast_models.dart';

/// Represents a single entry in the table of contents.
class TocEntry {
  /// Creates a TOC entry.
  const TocEntry({
    required this.title,
    required this.level,
    required this.blockIndex,
    this.anchor,
    this.children = const [],
  });

  /// The heading text.
  final String title;

  /// Heading level (1-6).
  final int level;

  /// Index of the corresponding content block.
  final int blockIndex;

  /// Optional anchor ID for navigation.
  final String? anchor;

  /// Child entries (for nested TOC structure).
  final List<TocEntry> children;

  /// Creates a copy with optional overrides.
  TocEntry copyWith({
    String? title,
    int? level,
    int? blockIndex,
    String? anchor,
    List<TocEntry>? children,
  }) {
    return TocEntry(
      title: title ?? this.title,
      level: level ?? this.level,
      blockIndex: blockIndex ?? this.blockIndex,
      anchor: anchor ?? this.anchor,
      children: children ?? this.children,
    );
  }

  @override
  String toString() => 'TocEntry(level: $level, title: "$title")';
}

/// Configuration for TOC generation.
class TocConfig {
  /// Creates a TOC configuration.
  const TocConfig({
    this.minLevel = 1,
    this.maxLevel = 6,
    this.includeBlockquoteHeadings = false,
    this.generateAnchors = true,
    this.anchorPrefix = 'heading-',
    this.buildHierarchy = true,
  });

  /// Minimum heading level to include (default: 1).
  final int minLevel;

  /// Maximum heading level to include (default: 6).
  final int maxLevel;

  /// Whether to include headings inside blockquotes.
  final bool includeBlockquoteHeadings;

  /// Whether to generate anchor IDs.
  final bool generateAnchors;

  /// Prefix for generated anchor IDs.
  final String anchorPrefix;

  /// Whether to build a nested hierarchy or flat list.
  final bool buildHierarchy;

  /// Creates a copy with optional overrides.
  TocConfig copyWith({
    int? minLevel,
    int? maxLevel,
    bool? includeBlockquoteHeadings,
    bool? generateAnchors,
    String? anchorPrefix,
    bool? buildHierarchy,
  }) {
    return TocConfig(
      minLevel: minLevel ?? this.minLevel,
      maxLevel: maxLevel ?? this.maxLevel,
      includeBlockquoteHeadings:
          includeBlockquoteHeadings ?? this.includeBlockquoteHeadings,
      generateAnchors: generateAnchors ?? this.generateAnchors,
      anchorPrefix: anchorPrefix ?? this.anchorPrefix,
      buildHierarchy: buildHierarchy ?? this.buildHierarchy,
    );
  }
}

/// Generates table of contents from parsed content blocks.
class TocGenerator {
  /// Creates a TOC generator.
  TocGenerator({this.config = const TocConfig()});

  /// Configuration for TOC generation.
  final TocConfig config;

  /// Generates TOC entries from content blocks.
  List<TocEntry> generate(List<ContentBlock> blocks) {
    final headings = _extractHeadings(blocks);

    if (config.buildHierarchy) {
      return _buildHierarchy(headings);
    }

    return headings;
  }

  /// Generates a flat list of all headings.
  List<TocEntry> generateFlat(List<ContentBlock> blocks) {
    return _extractHeadings(blocks);
  }

  List<TocEntry> _extractHeadings(List<ContentBlock> blocks) {
    final entries = <TocEntry>[];
    int anchorCount = 0;

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];

      if (block.type == ContentBlockType.blockquote &&
          config.includeBlockquoteHeadings) {
        final ast = _getAst(block);
        final children = ast?.children;
        if (children != null && children.isNotEmpty) {
          final nested = _extractHeadings(children);
          for (final entry in nested) {
            final anchor = config.generateAnchors
                ? '${config.anchorPrefix}${anchorCount++}'
                : null;
            entries.add(entry.copyWith(blockIndex: i, anchor: anchor));
          }
        }
        continue;
      }

      if (block.type != ContentBlockType.heading) {
        continue;
      }

      final level = block.headingLevel ?? 1;
      if (level < config.minLevel || level > config.maxLevel) {
        continue;
      }

      final title = _extractHeadingText(block.rawContent);
      final anchor = config.generateAnchors
          ? '${config.anchorPrefix}${anchorCount++}'
          : null;

      entries.add(
        TocEntry(title: title, level: level, blockIndex: i, anchor: anchor),
      );
    }

    return entries;
  }

  AstBlockData? _getAst(ContentBlock block) {
    final ast = block.metadata[kAstDataKey];
    return ast is AstBlockData ? ast : null;
  }

  String _extractHeadingText(String rawContent) {
    // Remove leading # symbols and whitespace
    return rawContent.replaceFirst(RegExp(r'^#{1,6}\s+'), '').trim();
  }

  List<TocEntry> _buildHierarchy(List<TocEntry> flatEntries) {
    if (flatEntries.isEmpty) {
      return [];
    }
    return _rebuildWithChildren(flatEntries);
  }

  List<TocEntry> _rebuildWithChildren(List<TocEntry> flatEntries) {
    if (flatEntries.isEmpty) return [];

    final result = <TocEntry>[];
    int i = 0;

    while (i < flatEntries.length) {
      final (newEntry, nextIndex) = _buildSubtree(flatEntries, i);
      result.add(newEntry);
      i = nextIndex;
    }

    return result;
  }

  (TocEntry, int) _buildSubtree(List<TocEntry> entries, int startIndex) {
    final entry = entries[startIndex];
    final children = <TocEntry>[];
    int i = startIndex + 1;

    while (i < entries.length && entries[i].level > entry.level) {
      final (childEntry, nextIndex) = _buildSubtree(entries, i);
      children.add(childEntry);
      i = nextIndex;
    }

    return (entry.copyWith(children: children), i);
  }
}
