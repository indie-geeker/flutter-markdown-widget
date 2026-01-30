// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/parser/content_block.dart';
import '../core/parser/incremental_parser.dart';
import '../core/parser/text_buffer.dart';
import '../core/cache/widget_cache.dart';
import '../builder/content_builder.dart';
import '../style/markdown_theme.dart';
import '../config/streaming_options.dart';
import '../config/render_options.dart';
import 'components/typing_cursor.dart';
import 'virtual_markdown_list.dart';

/// Main streaming markdown widget.
///
/// Supports both static content and streaming input from a Stream.
class StreamingMarkdownView extends StatefulWidget {
  /// Creates a streaming markdown view with static content.
  const StreamingMarkdownView({
    super.key,
    required this.content,
    this.theme,
    this.streamingOptions = const StreamingOptions(),
    this.renderOptions = const RenderOptions(),
    this.controller,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
  })  : stream = null,
        isStreaming = false;

  /// Creates a streaming markdown view from a stream.
  const StreamingMarkdownView.fromStream({
    super.key,
    required Stream<String> this.stream,
    this.theme,
    this.streamingOptions = const StreamingOptions(),
    this.renderOptions = const RenderOptions(),
    this.controller,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
  })  : content = '',
        isStreaming = true;

  /// Static markdown content.
  final String content;

  /// Stream of markdown chunks.
  final Stream<String>? stream;

  /// Whether receiving streaming content.
  final bool isStreaming;

  /// Theme for styling.
  final MarkdownTheme? theme;

  /// Streaming configuration.
  final StreamingOptions streamingOptions;

  /// Render options.
  final RenderOptions renderOptions;

  /// Scroll controller.
  final ScrollController? controller;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Padding around content.
  final EdgeInsets? padding;

  /// Whether to shrink-wrap content.
  final bool shrinkWrap;

  @override
  State<StreamingMarkdownView> createState() => _StreamingMarkdownViewState();
}

class _StreamingMarkdownViewState extends State<StreamingMarkdownView> {
  late IncrementalMarkdownParser _parser;
  late ContentBuilder _builder;
  late WidgetRenderCache _cache;
  late TextChunkBuffer _buffer;
  late ScrollController _scrollController;

  List<ContentBlock> _blocks = [];
  IncompleteBlock? _incompleteBlock;
  StreamSubscription<String>? _streamSubscription;
  bool _isReceiving = false;
  Timer? _throttleTimer;
  String _pendingContent = '';

  @override
  void initState() {
    super.initState();
    _parser = IncrementalMarkdownParser(
      enableLatex: widget.renderOptions.enableLatex,
    );
    _builder = ContentBuilder(
      theme: widget.theme,
      renderOptions: widget.renderOptions,
    );
    _cache = WidgetRenderCache();
    _buffer = TextChunkBuffer();
    _scrollController = widget.controller ?? ScrollController();

    if (widget.isStreaming && widget.stream != null) {
      _subscribeToStream();
    } else {
      _parseContent(widget.content);
    }
  }

  @override
  void didUpdateWidget(StreamingMarkdownView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update builder if options changed
    if (widget.renderOptions != oldWidget.renderOptions ||
        widget.theme != oldWidget.theme) {
      _builder = ContentBuilder(
        theme: widget.theme,
        renderOptions: widget.renderOptions,
      );
      _cache.clear();
    }

    // Handle content changes
    if (!widget.isStreaming && widget.content != oldWidget.content) {
      _parseContent(widget.content);
    }

    // Handle stream changes
    if (widget.stream != oldWidget.stream) {
      _streamSubscription?.cancel();
      if (widget.stream != null) {
        _buffer.clear();
        _subscribeToStream();
      }
    }
  }

  void _subscribeToStream() {
    _isReceiving = true;
    _streamSubscription = widget.stream!.listen(
      _onStreamData,
      onDone: _onStreamDone,
      onError: _onStreamError,
    );
  }

  void _onStreamData(String chunk) {
    _buffer.append(chunk);
    _scheduleUpdate();
  }

  void _scheduleUpdate() {
    if (_throttleTimer?.isActive == true) {
      _pendingContent = _buffer.content;
      return;
    }

    _performUpdate();

    _throttleTimer = Timer(
      Duration(milliseconds: widget.streamingOptions.throttleMs),
      () {
        if (_pendingContent.isNotEmpty) {
          _performUpdate();
          _pendingContent = '';
        }
      },
    );
  }

  void _performUpdate() {
    final result = _parser.parse(_buffer.content, isStreaming: _isReceiving);
    setState(() {
      _blocks = result.blocks;
      _incompleteBlock = result.incompleteBlock;
    });

    // Invalidate changed blocks
    for (final index in result.modifiedIndices) {
      _cache.invalidate(index);
    }

    // Auto-scroll to bottom
    if (widget.streamingOptions.autoScrollToBottom && _isReceiving) {
      _scrollToBottom();
    }
  }

  void _onStreamDone() {
    setState(() {
      _isReceiving = false;
      _incompleteBlock = null;
    });
    // Final parse without streaming mode
    _parseContent(_buffer.content);
  }

  void _onStreamError(Object error) {
    setState(() {
      _isReceiving = false;
    });
  }

  void _parseContent(String content) {
    final result = _parser.parse(content);
    setState(() {
      _blocks = result.blocks;
      _incompleteBlock = null;
    });
    for (final index in result.modifiedIndices) {
      _cache.invalidate(index);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: widget.streamingOptions.scrollAnimationDuration,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _throttleTimer?.cancel();
    _buffer.dispose();
    _cache.clear();
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get base theme from context (which provides default styles from Flutter's ThemeData)
    final baseTheme = MarkdownThemeProvider.of(context);
    // Merge user's theme on top of base theme (user overrides take precedence)
    final effectiveTheme = widget.theme != null 
        ? baseTheme.merge(widget.theme!) 
        : baseTheme;

    return MarkdownThemeProvider(
      theme: effectiveTheme,
      child: _buildContent(context, effectiveTheme),
    );
  }

  Widget _buildContent(BuildContext context, MarkdownTheme theme) {
    // Determine if we should use virtual scrolling
    final useVirtualScroll = widget.renderOptions.enableVirtualScrolling &&
        _blocks.length > widget.renderOptions.virtualScrollThreshold;

    if (useVirtualScroll) {
      return VirtualMarkdownList(
        blocks: _blocks,
        theme: theme,
        renderOptions: widget.renderOptions,
        controller: _scrollController,
        padding: widget.padding,
      );
    }

    // Non-virtualized list
    return ListView.builder(
      controller: _scrollController,
      physics: widget.physics,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      itemCount: _blocks.length + (_showCursor ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing cursor at the end
        if (index == _blocks.length && _showCursor) {
          return _buildCursorRow(context);
        }

        final block = _blocks[index];
        return _cache.getOrBuild(
          index,
          block.contentHash,
          () => _builder.buildBlock(context, block),
        );
      },
    );
  }

  bool get _showCursor =>
      _isReceiving && widget.streamingOptions.showTypingCursor;

  Widget _buildCursorRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Row(
        children: [
          TypingCursor(
            blinkDuration: widget.streamingOptions.cursorBlinkRate,
          ),
        ],
      ),
    );
  }
}
