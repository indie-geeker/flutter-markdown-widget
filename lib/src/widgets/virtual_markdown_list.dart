// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../core/parser/content_block.dart';
import '../core/cache/widget_cache.dart';
import '../core/cache/dimension_estimator.dart';
import '../builder/content_builder.dart';
import '../style/markdown_theme.dart';
import '../config/render_options.dart';

/// Virtualized list for rendering large markdown content.
///
/// Uses SliverList for efficient rendering of only visible items.
class VirtualMarkdownList extends StatefulWidget {
  /// Creates a virtual markdown list.
  const VirtualMarkdownList({
    super.key,
    required this.blocks,
    this.theme,
    this.renderOptions = const RenderOptions(),
    this.controller,
    this.padding,
    this.cacheExtent,
  });

  /// Parsed content blocks to render.
  final List<ContentBlock> blocks;

  /// Theme for styling.
  final MarkdownTheme? theme;

  /// Render options.
  final RenderOptions renderOptions;

  /// Scroll controller.
  final ScrollController? controller;

  /// Padding around the list.
  final EdgeInsets? padding;

  /// Cache extent for off-screen items.
  final double? cacheExtent;

  @override
  State<VirtualMarkdownList> createState() => _VirtualMarkdownListState();
}

class _VirtualMarkdownListState extends State<VirtualMarkdownList> {
  late ContentBuilder _builder;
  late WidgetRenderCache _cache;
  late BlockDimensionEstimator _estimator;

  @override
  void initState() {
    super.initState();
    _builder = ContentBuilder(
      theme: widget.theme,
      renderOptions: widget.renderOptions,
    );
    _cache = WidgetRenderCache();
    _estimator = BlockDimensionEstimator();
  }

  @override
  void didUpdateWidget(VirtualMarkdownList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.renderOptions != oldWidget.renderOptions) {
      _builder = ContentBuilder(
        theme: widget.theme,
        renderOptions: widget.renderOptions,
      );
    }
    if (widget.theme != oldWidget.theme) {
      _cache.clear();
    }
    // Detect changed blocks and invalidate cache
    if (widget.blocks != oldWidget.blocks) {
      _invalidateChangedBlocks(oldWidget.blocks, widget.blocks);
    }
  }

  void _invalidateChangedBlocks(
    List<ContentBlock> oldBlocks,
    List<ContentBlock> newBlocks,
  ) {
    final maxLen = oldBlocks.length > newBlocks.length
        ? oldBlocks.length
        : newBlocks.length;

    for (int i = 0; i < maxLen; i++) {
      if (i >= oldBlocks.length || i >= newBlocks.length) {
        _cache.invalidateFrom(i);
        break;
      }
      if (oldBlocks[i].contentHash != newBlocks[i].contentHash) {
        _cache.invalidate(i);
      }
    }
  }

  @override
  void dispose() {
    _cache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get base theme from context (which provides default styles from Flutter's ThemeData)
    final baseTheme = MarkdownThemeProvider.of(context);
    // Merge user's theme on top of base theme (user overrides take precedence)
    final effectiveTheme = widget.theme != null 
        ? baseTheme.merge(widget.theme!) 
        : baseTheme;

    return MarkdownThemeProvider(
      theme: effectiveTheme,
      child: CustomScrollView(
        controller: widget.controller,
        cacheExtent: widget.cacheExtent ?? 250,
        slivers: [
          if (widget.padding != null)
            SliverPadding(
              padding: widget.padding!,
              sliver: _buildSliverList(context),
            )
          else
            _buildSliverList(context),
        ],
      ),
    );
  }

  Widget _buildSliverList(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final block = widget.blocks[index];
          return _BlockItemWidget(
            key: ValueKey('block_$index'),
            block: block,
            builder: _builder,
            cache: _cache,
            estimator: _estimator,
            index: index,
          );
        },
        childCount: widget.blocks.length,
      ),
    );
  }
}

class _BlockItemWidget extends StatefulWidget {
  const _BlockItemWidget({
    super.key,
    required this.block,
    required this.builder,
    required this.cache,
    required this.estimator,
    required this.index,
  });

  final ContentBlock block;
  final ContentBuilder builder;
  final WidgetRenderCache cache;
  final BlockDimensionEstimator estimator;
  final int index;

  @override
  State<_BlockItemWidget> createState() => _BlockItemWidgetState();
}

class _BlockItemWidgetState extends State<_BlockItemWidget> {
  final GlobalKey _key = GlobalKey();
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeight);
  }

  void _measureHeight(_) {
    if (_measured) return;
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      widget.estimator.recordActualHeight(
        widget.block.contentHash,
        renderBox.size.height,
      );
      _measured = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.cache.getOrBuild(
        widget.index,
        widget.block.contentHash,
        () => widget.builder.buildBlock(context, widget.block),
      ),
    );
  }
}
