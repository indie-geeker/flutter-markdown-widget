// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../core/parser/content_block.dart';
import '../core/parser/markdown_parser.dart';
import '../core/parser/incremental_parser.dart';
import '../core/cache/widget_cache.dart';
import '../builder/content_builder.dart';
import '../style/markdown_theme.dart';
import '../config/render_options.dart';

/// Non-scrolling markdown body widget.
///
/// Renders markdown content as a Column of widgets.
/// Use this when embedding markdown in a scrollable parent.
class MarkdownContent extends StatefulWidget {
  /// Creates a markdown content widget.
  const MarkdownContent({
    super.key,
    required this.content,
    this.theme,
    this.renderOptions = const RenderOptions(),
    this.onBlocksGenerated,
  });

  /// Markdown content to render.
  final String content;

  /// Theme for styling.
  final MarkdownTheme? theme;

  /// Render options.
  final RenderOptions renderOptions;

  /// Callback when blocks are generated.
  final void Function(List<ContentBlock> blocks)? onBlocksGenerated;

  @override
  State<MarkdownContent> createState() => _MarkdownContentState();
}

class _MarkdownContentState extends State<MarkdownContent> {
  late MarkdownParser _parser;
  late ContentBuilder _builder;
  late WidgetRenderCache _cache;
  List<ContentBlock> _blocks = [];

  @override
  void initState() {
    super.initState();
    _parser = _createParser();
    _builder = ContentBuilder(
      theme: widget.theme,
      renderOptions: widget.renderOptions,
    );
    _cache = WidgetRenderCache();
    _parseContent();
  }

  @override
  void didUpdateWidget(MarkdownContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != oldWidget.content ||
        widget.renderOptions != oldWidget.renderOptions) {
      _parser = _createParser();
      _builder = ContentBuilder(
        theme: widget.theme,
        renderOptions: widget.renderOptions,
      );
      _parseContent();
    }
    if (widget.theme != oldWidget.theme) {
      _cache.clear();
    }
  }

  void _parseContent() {
    final result = _parser.parse(widget.content);
    setState(() {
      _blocks = result.blocks;
    });
    // Invalidate changed blocks in cache
    for (final index in result.modifiedIndices) {
      _cache.invalidate(index);
    }
    widget.onBlocksGenerated?.call(_blocks);
  }

  MarkdownParser _createParser() {
    final factory = widget.renderOptions.parserFactory;
    if (factory != null) {
      return factory(widget.renderOptions);
    }
    return IncrementalMarkdownParser(
      enableLatex: widget.renderOptions.enableLatex,
      customBlockSyntaxes: widget.renderOptions.customBlockSyntaxes,
      customInlineSyntaxes: widget.renderOptions.customInlineSyntaxes,
    );
  }

  @override
  void dispose() {
    _cache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_blocks.isEmpty) {
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth.isFinite 
                ? constraints.maxWidth 
                : MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: _blocks.asMap().entries.map((entry) {
                final index = entry.key;
                final block = entry.value;

                return _cache.getOrBuild(
                  index,
                  block.contentHash,
                  () => _builder.buildBlock(context, block),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
