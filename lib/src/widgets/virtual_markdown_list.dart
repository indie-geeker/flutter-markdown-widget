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
/// Uses [SliverList] so each child can report its natural height (markdown
/// blocks have highly variable, non-predictable heights). A generous
/// [cacheExtent] is used so Flutter pre-measures a large window of items,
/// which stabilizes `maxScrollExtent` and reduces scrollbar jitter during
/// fast scrolling.
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

  /// Cache extent for off-screen items, in logical pixels.
  ///
  /// Larger values pre-build and pre-measure more off-screen items, which
  /// stabilizes `maxScrollExtent` and reduces scrollbar jitter during fast
  /// scrolling, at the cost of memory. Defaults to [_defaultCacheExtent].
  final double? cacheExtent;

  /// Optional external widget cache. If provided, the caller owns its lifecycle.
  final WidgetRenderCache? widgetCache;

  /// Optional index to render with reduced opacity (e.g., incomplete block).
  final int? fadedIndex;

  /// Opacity value to apply to the faded index.
  final double? fadedOpacity;

  /// Default cache extent. Chosen to cover roughly 2 full screen heights of
  /// typical phone/tablet viewports, so the scrollbar's `maxScrollExtent`
  /// estimate draws from a large pool of already-measured children.
  static const double _defaultCacheExtent = 1500;

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
        cacheExtent:
            widget.cacheExtent ?? VirtualMarkdownList._defaultCacheExtent,
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
        findChildIndexCallback: (key) {
          if (key is ValueKey<int>) {
            final hash = key.value;
            final index =
                widget.blocks.indexWhere((b) => b.contentHash == hash);
            return index >= 0 ? index : null;
          }
          return null;
        },
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
