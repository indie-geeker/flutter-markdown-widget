// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../core/parser/content_block.dart';
import '../core/cache/widget_cache.dart';
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
    this.widgetCache,
    this.fadedIndex,
    this.fadedOpacity,
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

  /// Optional external widget cache. If provided, the caller owns its lifecycle.
  final WidgetRenderCache? widgetCache;

  /// Optional index to render with reduced opacity (e.g., incomplete block).
  final int? fadedIndex;

  /// Opacity value to apply to the faded index.
  final double? fadedOpacity;

  @override
  State<VirtualMarkdownList> createState() => _VirtualMarkdownListState();
}

class _VirtualMarkdownListState extends State<VirtualMarkdownList> {
  late ContentBuilder _builder;
  late WidgetRenderCache _cache;
  late final bool _ownsCache;

  @override
  void initState() {
    super.initState();
    _builder = ContentBuilder(
      theme: widget.theme,
      renderOptions: widget.renderOptions,
    );
    _cache = widget.widgetCache ?? WidgetRenderCache();
    _ownsCache = widget.widgetCache == null;
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
      _builder = ContentBuilder(theme: widget.theme, renderOptions: widget.renderOptions);
      if (_ownsCache) _cache.clear();
    }
  }

  @override
  void dispose() {
    if (_ownsCache) _cache.clear();
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
        cacheExtent: widget.cacheExtent ?? 500,
        slivers: [
          if (widget.padding != null)
            SliverPadding(
              padding: widget.padding!,
              sliver: _buildSliverList(context, effectiveTheme),
            )
          else
            _buildSliverList(context, effectiveTheme),
        ],
      ),
    );
  }

  Widget _buildSliverList(BuildContext context, MarkdownTheme resolvedTheme) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final block = widget.blocks[index];
          return _BlockItemWidget(
            key: ValueKey(block.contentHash),
            block: block,
            builder: _builder,
            cache: _cache,
            resolvedTheme: resolvedTheme,
            isFaded: widget.fadedIndex != null &&
                widget.fadedIndex == index &&
                widget.fadedOpacity != null,
            fadedOpacity: widget.fadedOpacity ?? 1.0,
          );
        },
        childCount: widget.blocks.length,
      ),
    );
  }
}

class _BlockItemWidget extends StatelessWidget {
  const _BlockItemWidget({
    super.key,
    required this.block,
    required this.builder,
    required this.cache,
    required this.isFaded,
    required this.fadedOpacity,
    this.resolvedTheme,
  });

  final ContentBlock block;
  final ContentBuilder builder;
  final WidgetRenderCache cache;
  final bool isFaded;
  final double fadedOpacity;
  final MarkdownTheme? resolvedTheme;

  @override
  Widget build(BuildContext context) {
    Widget child = cache.getOrBuild(
      block.contentHash,
      () => builder.buildBlock(context, block, resolvedTheme: resolvedTheme),
    );

    if (isFaded && fadedOpacity < 1.0) {
      child = Opacity(
        opacity: fadedOpacity.clamp(0.0, 1.0),
        child: child,
      );
    }

    return RepaintBoundary(child: child);
  }
}
