// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../core/parser/content_block.dart';
import '../core/parser/incremental_parser.dart';
import '../core/cache/widget_cache.dart';
import '../builder/content_builder.dart';
import '../style/markdown_theme.dart';
import '../config/render_options.dart';
import '../toc/toc_controller.dart';
import '../toc/toc_generator.dart';

/// A scrollable markdown widget with TOC support.
///
/// This widget renders markdown content in a scrollable list and optionally
/// integrates with a [TocController] for table of contents functionality.
///
/// Usage with TOC:
/// ```dart
/// final tocController = TocController();
///
/// Row(
///   children: [
///     Expanded(child: TocListWidget(controller: tocController)),
///     Expanded(
///       flex: 3,
///       child: MarkdownWidget(
///         data: markdownContent,
///         tocController: tocController,
///       ),
///     ),
///   ],
/// )
/// ```
class MarkdownWidget extends StatefulWidget {
  /// Creates a markdown widget.
  const MarkdownWidget({
    super.key,
    required this.data,
    this.theme,
    this.renderOptions = const RenderOptions(),
    this.tocController,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
  });

  /// The markdown content to render.
  final String data;

  /// Theme for styling.
  final MarkdownTheme? theme;

  /// Render options.
  final RenderOptions renderOptions;

  /// Optional TOC controller for table of contents integration.
  ///
  /// When provided, the widget will:
  /// 1. Generate TOC entries and pass them to the controller
  /// 2. Support jumping to specific headings when TOC items are tapped
  /// 3. Update the controller's current index as the user scrolls
  final TocController? tocController;

  /// Padding around the content.
  final EdgeInsetsGeometry? padding;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Whether to shrink wrap the content.
  final bool shrinkWrap;

  /// Optional scroll controller.
  final ScrollController? controller;

  @override
  State<MarkdownWidget> createState() => _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<MarkdownWidget> {
  late IncrementalMarkdownParser _parser;
  late ContentBuilder _builder;
  late WidgetRenderCache _cache;
  late ScrollController _scrollController;
  List<ContentBlock> _blocks = [];
  final Map<int, GlobalKey> _blockKeys = {};
  final TocGenerator _tocGenerator = TocGenerator(
    config: const TocConfig(buildHierarchy: false),
  );

  bool get _hasExternalScrollController => widget.controller != null;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _parser = IncrementalMarkdownParser(
      enableLatex: widget.renderOptions.enableLatex,
    );
    _builder = ContentBuilder(
      theme: widget.theme,
      renderOptions: widget.renderOptions,
    );
    _cache = WidgetRenderCache();
    _parseContent();
    _setupTocController();
  }

  void _setupTocController() {
    widget.tocController?.jumpToWidgetIndexCallback = _jumpToIndex;
  }

  @override
  void didUpdateWidget(MarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data ||
        widget.renderOptions != oldWidget.renderOptions) {
      _builder = ContentBuilder(
        theme: widget.theme,
        renderOptions: widget.renderOptions,
      );
      _parseContent();
    }
    if (widget.theme != oldWidget.theme) {
      _cache.clear();
    }
    if (widget.tocController != oldWidget.tocController) {
      oldWidget.tocController?.jumpToWidgetIndexCallback = null;
      _setupTocController();
    }
    if (widget.controller != oldWidget.controller) {
      if (!_hasExternalScrollController) {
        _scrollController.dispose();
      }
      _scrollController = widget.controller ?? ScrollController();
    }
  }

  void _parseContent() {
    final result = _parser.parse(widget.data);
    _blocks = result.blocks;
    
    // Generate keys for heading blocks
    _blockKeys.clear();
    for (int i = 0; i < _blocks.length; i++) {
      if (_blocks[i].type == ContentBlockType.heading) {
        _blockKeys[i] = GlobalKey();
      }
    }

    // Invalidate changed blocks in cache
    for (final index in result.modifiedIndices) {
      _cache.invalidate(index);
    }

    // Update TOC controller after frame to ensure listeners are registered
    if (widget.tocController != null) {
      final tocEntries = _tocGenerator.generate(_blocks);
      // Use post frame callback to ensure TocListWidget has registered listeners
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.tocController!.setTocList(tocEntries);
        }
      });
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _jumpToIndex(int blockIndex) {
    final key = _blockKeys[blockIndex];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  @override
  void dispose() {
    widget.tocController?.jumpToWidgetIndexCallback = null;
    _cache.clear();
    if (!_hasExternalScrollController) {
      _scrollController.dispose();
    }
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
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        itemCount: _blocks.length,
        itemBuilder: (context, index) {
          final block = _blocks[index];
          final widget = _cache.getOrBuild(
            index,
            block.contentHash,
            () => _builder.buildBlock(context, block),
          );

          // Wrap heading blocks with GlobalKey for scroll-to functionality
          if (_blockKeys.containsKey(index)) {
            return Container(
              key: _blockKeys[index],
              child: widget,
            );
          }
          return widget;
        },
      ),
    );
  }
}
