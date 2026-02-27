// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../core/parser/content_block.dart';
import '../core/parser/markdown_parser.dart';
import '../core/parser/incremental_parser.dart';
import '../core/parser/ast_markdown_parser.dart';
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
  final EdgeInsets? padding;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Whether to shrink wrap the content.
  final bool shrinkWrap;

  @override
  State<MarkdownWidget> createState() => _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<MarkdownWidget> {
  late MarkdownParser _parser;
  late ContentBuilder _builder;
  late WidgetRenderCache _cache;

  /// Controller for jumping to specific items by index
  final ItemScrollController _itemScrollController = ItemScrollController();

  /// Listener for tracking visible items (used for TOC sync)
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  /// Timer for sequential TOC highlighting during jump transitions
  Timer? _transitionTimer;
  late final TocIndexCallback _jumpToIndexCallback;

  List<ContentBlock> _blocks = [];
  final TocGenerator _tocGenerator = TocGenerator(
    config: const TocConfig(buildHierarchy: false),
  );

  @override
  void initState() {
    super.initState();
    _jumpToIndexCallback = _jumpToIndex;
    _parser = _createParser();
    _builder = ContentBuilder(
      theme: widget.theme,
      renderOptions: widget.renderOptions,
    );
    _cache = WidgetRenderCache();
    _parseContent();
    _setupTocController();
    _setupScrollListener();
  }

  void _setupTocController() {
    widget.tocController?.jumpToWidgetIndexCallback = _jumpToIndexCallback;
  }

  void _setupScrollListener() {
    // Listen to visible items and update TOC current index
    _itemPositionsListener.itemPositions.addListener(_onVisibleItemsChanged);
  }

  void _onVisibleItemsChanged() {
    if (widget.tocController == null) return;

    // Skip scroll-based updates while a programmatic jump is in progress
    if (widget.tocController!.isJumping) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    const double topThreshold = 0.15;
    int? closestBelowIndex;
    double closestBelowEdge = double.infinity;
    int? closestAboveIndex;
    double closestAboveEdge = double.negativeInfinity;

    for (final position in positions) {
      final block = _blocks[position.index];
      if (block.type != ContentBlockType.heading) continue;

      // itemLeadingEdge: 0 = at top, negative = above viewport, positive = below top
      final edge = position.itemLeadingEdge;
      if (edge >= 0 && edge <= topThreshold) {
        if (edge < closestBelowEdge) {
          closestBelowEdge = edge;
          closestBelowIndex = position.index;
        }
      } else if (edge < 0) {
        if (edge > closestAboveEdge) {
          closestAboveEdge = edge;
          closestAboveIndex = position.index;
        }
      }
    }

    // Prefer the heading at/just below the top, if available.
    if (closestBelowIndex != null) {
      widget.tocController!.notifyIndexChanged(closestBelowIndex);
      return;
    }

    // Otherwise, use the closest visible heading above the top.
    if (closestAboveIndex != null) {
      widget.tocController!.notifyIndexChanged(closestAboveIndex);
      return;
    }

    // Otherwise, find the nearest heading above the first visible item
    final sortedPositions = positions.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final firstVisibleIndex = sortedPositions.first.index;

    for (int i = firstVisibleIndex; i >= 0; i--) {
      if (_blocks[i].type == ContentBlockType.heading) {
        widget.tocController!.notifyIndexChanged(i);
        return;
      }
    }
  }

  @override
  void didUpdateWidget(MarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data ||
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
    if (widget.tocController != oldWidget.tocController) {
      oldWidget.tocController?.clearJumpToWidgetIndexCallback(
        _jumpToIndexCallback,
      );
      _setupTocController();
    }
  }

  void _parseContent() {
    final result = _parser.parse(widget.data);
    _blocks = result.blocks;

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

  MarkdownParser _createParser() {
    final factory = widget.renderOptions.parserFactory;
    if (factory != null) {
      return factory(widget.renderOptions);
    }
    if (widget.renderOptions.parserMode == ParserMode.ast) {
      return AstMarkdownParser(
        enableLatex: widget.renderOptions.enableLatex,
        enableAutolinks: widget.renderOptions.enableAutolinks,
        customBlockSyntaxes: widget.renderOptions.customBlockSyntaxes,
        customInlineSyntaxes: widget.renderOptions.customInlineSyntaxes,
        extensionSet: widget.renderOptions.extensionSet,
      );
    }
    return IncrementalMarkdownParser(
      enableLatex: widget.renderOptions.enableLatex,
      customBlockSyntaxes: widget.renderOptions.customBlockSyntaxes,
      customInlineSyntaxes: widget.renderOptions.customInlineSyntaxes,
    );
  }

  void _jumpToIndex(int blockIndex) {
    if (!_itemScrollController.isAttached) return;
    if (blockIndex < 0 || blockIndex >= _blocks.length) return;

    // Cancel any existing transition timer
    _transitionTimer?.cancel();

    final isSyncMode = widget.tocController?.syncTocDuringJump ?? false;
    final currentIndex = widget.tocController?.currentIndex ?? 0;

    Duration scrollDuration;
    Curve scrollCurve;

    if (isSyncMode) {
      // Collect all headings between current and target
      final headingIndices = _collectHeadingsBetween(currentIndex, blockIndex);
      final headingCount = headingIndices.length;

      // 100ms per heading, minimum 200ms, maximum 1500ms
      final calculatedMs = headingCount * 60;
      scrollDuration = Duration(milliseconds: calculatedMs.clamp(200, 1500));
      scrollCurve = Curves.linear;

      // Start sequential highlighting animation
      if (headingIndices.isNotEmpty) {
        _startTransitionAnimation(headingIndices, scrollDuration);
      }
    } else {
      // Direct jump mode
      scrollDuration = const Duration(milliseconds: 300);
      scrollCurve = Curves.easeInOut;
    }

    _itemScrollController
        .scrollTo(
          index: blockIndex,
          duration: scrollDuration,
          curve: scrollCurve,
          alignment: 0.0,
        )
        .then((_) {
          _transitionTimer?.cancel();
          widget.tocController?.notifyIndexChanged(blockIndex);
          widget.tocController?.onJumpComplete();
        });
  }

  /// Collects heading indices between [fromIndex] and [toIndex] in scroll order.
  List<int> _collectHeadingsBetween(int fromIndex, int toIndex) {
    final List<int> headingIndices = [];
    final isForward = toIndex > fromIndex;

    if (isForward) {
      for (int i = fromIndex + 1; i <= toIndex; i++) {
        if (_blocks[i].type == ContentBlockType.heading) {
          headingIndices.add(i);
        }
      }
    } else {
      for (int i = fromIndex - 1; i >= toIndex; i--) {
        if (_blocks[i].type == ContentBlockType.heading) {
          headingIndices.add(i);
        }
      }
    }
    return headingIndices;
  }

  /// Starts a timer that highlights each heading in [headingIndices] sequentially.
  void _startTransitionAnimation(
    List<int> headingIndices,
    Duration totalDuration,
  ) {
    final delayPerHeading =
        totalDuration.inMilliseconds ~/ headingIndices.length;
    int currentStep = 0;

    _transitionTimer = Timer.periodic(Duration(milliseconds: delayPerHeading), (
      timer,
    ) {
      if (currentStep >= headingIndices.length || !mounted) {
        timer.cancel();
        return;
      }
      widget.tocController?.notifyIndexChanged(headingIndices[currentStep]);
      currentStep++;
    });
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    widget.tocController?.clearJumpToWidgetIndexCallback(_jumpToIndexCallback);
    _itemPositionsListener.itemPositions.removeListener(_onVisibleItemsChanged);
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
      child: ScrollablePositionedList.builder(
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        padding: widget.padding,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        itemCount: _blocks.length,
        itemBuilder: (context, index) {
          final block = _blocks[index];
          return _cache.getOrBuild(
            index,
            block.contentHash,
            () => _builder.buildBlock(context, block),
          );
        },
      ),
    );
  }
}
