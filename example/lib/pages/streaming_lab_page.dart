// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';

import '../app/app_theme.dart';
import '../data/markdown_samples.dart';
import '../widgets/app_background.dart';
import '../widgets/example_app_bar.dart';
import '../widgets/option_tiles.dart';
import '../widgets/section_header.dart';
import '../widgets/surface_card.dart';

class StreamingLabPage extends StatefulWidget {
  const StreamingLabPage({super.key});

  @override
  State<StreamingLabPage> createState() => _StreamingLabPageState();
}

class _StreamingLabPageState extends State<StreamingLabPage> {
  StreamController<String>? _streamController;
  bool _isStreaming = false;
  bool _disposed = false;

  double _speed = 2.0;
  BufferMode _bufferMode = BufferMode.byCharacter;
  bool _showCursor = true;
  bool _autoScroll = true;
  bool _renderIncomplete = false;
  bool _enableVirtualScroll = true;
  bool _finalizeWithAst = true;
  ParserMode _finalParserMode = ParserMode.ast;

  String _accumulated = '';

  @override
  void dispose() {
    _disposed = true;
    _isStreaming = false;
    _streamController?.close();
    _streamController = null;
    super.dispose();
  }

  void _startStreaming() {
    setState(() {
      _isStreaming = true;
      _accumulated = '';
      _streamController = StreamController<String>();
    });

    _simulateStreaming();
  }

  Future<void> _simulateStreaming() async {
    final chunks = MarkdownSamples.streamingResponse.runes
        .map((r) => String.fromCharCode(r))
        .toList();
    final delay = (20 / _speed).round();

    for (final chunk in chunks) {
      if (_disposed || !_isStreaming || _streamController == null) break;

      _accumulated += chunk;
      _streamController!.add(chunk);

      if (chunk == '\n') {
        await Future.delayed(Duration(milliseconds: delay * 4));
      } else if (chunk == ' ') {
        await Future.delayed(Duration(milliseconds: delay ~/ 2));
      } else {
        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    if (!_disposed) {
      _stopStreaming();
    }
  }

  void _stopStreaming() {
    _isStreaming = false;
    if (!_disposed) {
      setState(() {});
    }
    _streamController?.close();
    _streamController = null;
  }

  void _reset() {
    _stopStreaming();
    if (!_disposed) {
      setState(() => _accumulated = '');
    }
  }

  StreamingOptions _streamingOptions() {
    final throttle = _bufferMode == BufferMode.byInterval
        ? (120 / _speed).round().clamp(16, 200)
        : 16;

    return StreamingOptions(
      bufferMode: _bufferMode,
      throttleMs: throttle,
      showTypingCursor: _showCursor,
      autoScrollToBottom: _autoScroll,
      renderIncompleteBlocks: _renderIncomplete,
      incompleteBlockOpacity: 0.55,
      finalizeWithAst: _finalizeWithAst,
    );
  }

  RenderOptions _renderOptions() {
    return RenderOptions(
      parserMode: _finalParserMode,
      enableTables: true,
      enableTaskLists: true,
      enableCodeHighlight: true,
      enableLatex: true,
      enableVirtualScrolling: _enableVirtualScroll,
      virtualScrollThreshold: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        ExampleTheme.markdownTheme(context, accent: AppPalette.indigo);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ExampleAppBar(
        title: 'Streaming Lab',
        icon: Icons.smart_toy_outlined,
        gradient: AppGradients.violet,
        actions: [
          if (_isStreaming)
            IconButton(
              onPressed: _stopStreaming,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.stop_rounded, size: 18, color: Colors.red),
              ),
            )
          else if (_accumulated.isNotEmpty)
            IconButton(
              onPressed: _reset,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: AppBackground(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            20,
            24,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : 640.0;
              final isCompact = maxHeight < 640;
              final previewHeight = (maxHeight * 0.55).clamp(320.0, 520.0);

              if (isCompact) {
                return ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    _buildOptionsPanel(
                      scrollable: false,
                      maxHeight: null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: previewHeight,
                      child: _buildPreviewPanel(theme),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildOptionsPanel(
                    scrollable: true,
                    maxHeight: maxHeight * 0.5,
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildPreviewPanel(theme)),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: !_isStreaming && _accumulated.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _startStreaming,
              backgroundColor: AppPalette.indigo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Start Streaming',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildOptionsPanel({
    required bool scrollable,
    required double? maxHeight,
  }) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SectionHeader(
            title: 'Streaming Options',
            subtitle: 'Tune buffer mode, cursor, and playback speed.',
            icon: Icons.speed_rounded,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<BufferMode>(
            segments: const [
              ButtonSegment(
                value: BufferMode.byCharacter,
                label: Text('Character'),
              ),
              ButtonSegment(
                value: BufferMode.byLine,
                label: Text('Line'),
              ),
              ButtonSegment(
                value: BufferMode.byInterval,
                label: Text('Interval'),
              ),
              ButtonSegment(
                value: BufferMode.byBlock,
                label: Text('Block'),
              ),
            ],
            selected: {_bufferMode},
            onSelectionChanged: (value) =>
                setState(() => _bufferMode = value.first),
          ),
        ),
        OptionSliderTile(
          title: 'Playback Speed',
          value: _speed,
          min: 0.5,
          max: 5,
          divisions: 9,
          onChanged: (v) => setState(() => _speed = v),
          trailingLabel: '${_speed.toStringAsFixed(1)}x',
        ),
        OptionSwitchTile(
          title: 'Typing Cursor',
          value: _showCursor,
          onChanged: (v) => setState(() => _showCursor = v),
        ),
        OptionSwitchTile(
          title: 'Auto Scroll',
          value: _autoScroll,
          onChanged: (v) => setState(() => _autoScroll = v),
        ),
        OptionSwitchTile(
          title: 'Render Incomplete Blocks',
          value: _renderIncomplete,
          onChanged: (v) => setState(() => _renderIncomplete = v),
        ),
        OptionSwitchTile(
          title: 'Virtual Scrolling',
          value: _enableVirtualScroll,
          onChanged: (v) => setState(() => _enableVirtualScroll = v),
        ),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SectionHeader(
            title: 'Finalization',
            subtitle:
                'Control how final output is parsed after stream completion.',
            icon: Icons.rule_folder_outlined,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<ParserMode>(
            segments: const [
              ButtonSegment(
                value: ParserMode.ast,
                label: Text('Final AST'),
              ),
              ButtonSegment(
                value: ParserMode.incremental,
                label: Text('Final Incremental'),
              ),
            ],
            selected: {_finalParserMode},
            onSelectionChanged: (value) =>
                setState(() => _finalParserMode = value.first),
          ),
        ),
        OptionSwitchTile(
          title: 'Finalize With AST',
          value: _finalizeWithAst,
          onChanged: (v) {
            if (_finalParserMode != ParserMode.ast) return;
            setState(() => _finalizeWithAst = v);
          },
          subtitle: _finalParserMode == ParserMode.ast
              ? 'When enabled, stream completion re-parses with AST.'
              : 'Only available when final parser mode is AST.',
        ),
      ],
    );

    content = scrollable
        ? SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: content,
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: content,
          );

    Widget panel = SurfaceCard(
      padding: EdgeInsets.zero,
      child: content,
    );

    if (maxHeight != null) {
      panel = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: panel,
      );
    }

    return panel;
  }

  Widget _buildPreviewPanel(MarkdownTheme theme) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      radius: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _streamController != null
            ? StreamingMarkdownView.fromStream(
                stream: _streamController!.stream,
                padding: const EdgeInsets.all(24),
                streamingOptions: _streamingOptions(),
                renderOptions: _renderOptions(),
                theme: theme,
              )
            : _accumulated.isNotEmpty
                ? StreamingMarkdownView(
                    content: _accumulated,
                    padding: const EdgeInsets.all(24),
                    renderOptions: _renderOptions(),
                    theme: theme,
                  )
                : _StreamingEmptyState(
                    onStart: _startStreaming,
                  ),
      ),
    );
  }
}

class _StreamingEmptyState extends StatelessWidget {
  const _StreamingEmptyState({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppPalette.indigo.withValues(alpha: 0.18),
                  AppPalette.indigo.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ready to Stream',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Press the button below to start rendering.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start streaming'),
          ),
        ],
      ),
    );
  }
}
