// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../parser/content_block.dart';

/// Estimator for block widget dimensions.
///
/// Provides height estimates for virtual scrolling
/// before widgets are actually rendered.
class BlockDimensionEstimator {
  /// Creates an estimator with optional base configuration.
  BlockDimensionEstimator({
    this.baseFontSize = 16.0,
    this.lineHeight = 1.5,
    this.horizontalPadding = 16.0,
    this.verticalPadding = 8.0,
    this.maxWidth = 800.0,
  });

  /// Base font size for text calculations.
  final double baseFontSize;

  /// Line height multiplier.
  final double lineHeight;

  /// Horizontal padding per side.
  final double horizontalPadding;

  /// Vertical padding per side.
  final double verticalPadding;

  /// Maximum content width for text wrapping calculations.
  final double maxWidth;

  /// Cache of measured actual heights.
  final Map<int, double> _measuredHeights = {};

  /// Estimates height for a content block.
  double estimateHeight(ContentBlock block, {double? availableWidth}) {
    // Return measured height if available
    if (_measuredHeights.containsKey(block.contentHash)) {
      return _measuredHeights[block.contentHash]!;
    }

    final width = availableWidth ?? maxWidth;
    return switch (block.type) {
      ContentBlockType.paragraph => _estimateParagraphHeight(block, width),
      ContentBlockType.heading => _estimateHeadingHeight(block),
      ContentBlockType.codeBlock => _estimateCodeBlockHeight(block),
      ContentBlockType.blockquote => _estimateBlockquoteHeight(block, width),
      ContentBlockType.unorderedList ||
      ContentBlockType.orderedList => _estimateListHeight(block, width),
      ContentBlockType.listItem => _estimateListItemHeight(block, width),
      ContentBlockType.table => _estimateTableHeight(block),
      ContentBlockType.horizontalRule => _estimateHorizontalRuleHeight(),
      ContentBlockType.latexBlock => _estimateLatexBlockHeight(block),
      ContentBlockType.image => _estimateImageHeight(block),
      ContentBlockType.thematicBreak => _estimateHorizontalRuleHeight(),
      ContentBlockType.htmlBlock => _estimateParagraphHeight(block, width),
    };
  }

  /// Records actual measured height for a block.
  void recordActualHeight(int contentHash, double height) {
    _measuredHeights[contentHash] = height;
  }

  /// Clears measured height cache.
  void clearMeasurements() {
    _measuredHeights.clear();
  }

  /// Invalidates measurement for specific block.
  void invalidateMeasurement(int contentHash) {
    _measuredHeights.remove(contentHash);
  }

  double _estimateParagraphHeight(ContentBlock block, double width) {
    final text = block.rawContent.trim();
    final charPerLine = (width - horizontalPadding * 2) / (baseFontSize * 0.6);
    final estimatedLines = (text.length / charPerLine).ceil();
    final lineCount = text.split('\n').length;
    final totalLines = estimatedLines > lineCount ? estimatedLines : lineCount;

    return (totalLines * baseFontSize * lineHeight) + (verticalPadding * 2);
  }

  double _estimateHeadingHeight(ContentBlock block) {
    final level = block.headingLevel ?? 1;
    final fontSizeMultiplier = switch (level) {
      1 => 2.0,
      2 => 1.75,
      3 => 1.5,
      4 => 1.25,
      5 => 1.1,
      6 => 1.0,
      _ => 1.0,
    };

    return (baseFontSize * fontSizeMultiplier * lineHeight) +
        (verticalPadding * 3);
  }

  double _estimateCodeBlockHeight(ContentBlock block) {
    final lines = block.rawContent.split('\n').length;
    // Add extra for header with language label
    final headerHeight = 40.0;
    final codeHeight = lines * baseFontSize * 1.4; // Monospace slightly taller
    return headerHeight + codeHeight + (verticalPadding * 2);
  }

  double _estimateBlockquoteHeight(ContentBlock block, double width) {
    final innerWidth = width - 20; // Account for quote border/padding
    final text = block.rawContent.replaceAll(RegExp(r'^>\s*', multiLine: true), '');
    final charPerLine = (innerWidth - horizontalPadding * 2) / (baseFontSize * 0.6);
    final estimatedLines = (text.length / charPerLine).ceil();

    return (estimatedLines * baseFontSize * lineHeight) + (verticalPadding * 3);
  }

  double _estimateListHeight(ContentBlock block, double width) {
    final items = block.rawContent.split('\n').where((l) => l.trim().isNotEmpty).length;
    // Rough estimate per item
    return items * (baseFontSize * lineHeight + verticalPadding);
  }

  double _estimateListItemHeight(ContentBlock block, double width) {
    return baseFontSize * lineHeight + verticalPadding;
  }

  double _estimateTableHeight(ContentBlock block) {
    final rows = block.rawContent.split('\n').where((l) => l.trim().isNotEmpty).length;
    final rowHeight = baseFontSize * lineHeight + 16; // Cell padding
    return (rows * rowHeight) + 32; // Header styling
  }

  double _estimateHorizontalRuleHeight() {
    return 24.0 + (verticalPadding * 2);
  }

  double _estimateLatexBlockHeight(ContentBlock block) {
    // LaTeX blocks vary greatly; use conservative estimate
    final lines = block.rawContent.split('\n').length;
    return (lines * baseFontSize * 2.5) + (verticalPadding * 2);
  }

  double _estimateImageHeight(ContentBlock block) {
    // Default image height; actual will be measured
    return 200.0 + (verticalPadding * 2);
  }
}
