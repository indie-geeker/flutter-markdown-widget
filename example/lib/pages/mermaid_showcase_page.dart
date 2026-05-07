// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';

import '../app/app_theme.dart';
import '../data/mermaid_samples.dart';
import '../mermaid/mermaid_demo_scope.dart';
import '../widgets/app_background.dart';
import '../widgets/example_app_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/surface_card.dart';

enum MermaidShowcaseMode {
  static,
  streaming,
  errors,
}

class MermaidShowcasePage extends StatefulWidget {
  const MermaidShowcasePage({super.key});

  @override
  State<MermaidShowcasePage> createState() => _MermaidShowcasePageState();
}

class _MermaidShowcasePageState extends State<MermaidShowcasePage> {
  MermaidShowcaseMode _mode = MermaidShowcaseMode.static;
  MermaidTheme _mermaidTheme = MermaidTheme.auto;
  StreamController<String>? _streamController;
  bool _isStreaming = false;
  int _errorCount = 0;
  String? _lastErrorType;
  late final void Function(MermaidError error) _onMermaidError =
      _handleMermaidError;
  late final Widget Function(BuildContext, MermaidErrorContext)
      _inlineErrorBuilder = _buildInlineError;

  String get _content {
    return switch (_mode) {
      MermaidShowcaseMode.static => MermaidSamples.staticShowcase,
      MermaidShowcaseMode.streaming => MermaidSamples.streamingShowcase,
      MermaidShowcaseMode.errors => MermaidSamples.errorShowcase,
    };
  }

  RenderOptions _renderOptions(MermaidRenderer renderer) {
    return RenderOptions(
      parserMode: ParserMode.ast,
      enableVirtualScrolling: false,
      mermaidOptions: MermaidOptions(
        renderer: renderer,
        theme: _mermaidTheme,
        onError: _onMermaidError,
        errorBuilder: _inlineErrorBuilder,
      ),
    );
  }

  StreamingOptions get _streamingOptions {
    return const StreamingOptions(
      bufferMode: BufferMode.byBlock,
      showTypingCursor: true,
      renderIncompleteBlocks: true,
    );
  }

  void _setMode(MermaidShowcaseMode mode) {
    if (_mode == mode) return;
    _closeStream();
    setState(() {
      _mode = mode;
      _errorCount = 0;
      _lastErrorType = null;
    });
  }

  void _handleMermaidError(MermaidError error) {
    if (!mounted) return;
    setState(() {
      _errorCount++;
      _lastErrorType = error.runtimeType.toString();
    });
  }

  void _startStreaming() {
    _closeStream();
    final controller = StreamController<String>();
    setState(() {
      _streamController = controller;
      _isStreaming = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStreamingReplay(controller);
    });
  }

  Future<void> _runStreamingReplay(StreamController<String> controller) async {
    const chunks = [
      'The assistant is composing a response with a diagram.\n\n```mermaid\nflowchart LR\n  Stream[Streaming chunks] --> Parser\n',
      '  Parser --> Complete{Fence closed?}\n  Complete -->|yes| Render\n  Complete -->|no| Fallback\n```',
    ];

    for (final chunk in chunks) {
      if (!mounted || _streamController != controller || controller.isClosed) {
        return;
      }
      controller.add(chunk);
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    if (!mounted || _streamController != controller || controller.isClosed) {
      return;
    }
    await controller.close();
    if (mounted && _streamController == controller) {
      setState(() => _isStreaming = false);
    }
  }

  void _closeStream() {
    final controller = _streamController;
    _streamController = null;
    _isStreaming = false;
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
  }

  @override
  void dispose() {
    _closeStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderer = MermaidDemoScope.of(context);
    final markdownTheme = ExampleTheme.markdownTheme(
      context,
      accent: AppPalette.mint,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ExampleAppBar(
        title: 'Mermaid Showcase',
        icon: Icons.account_tree_rounded,
        gradient: AppGradients.emerald,
      ),
      body: AppBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            20,
            24,
          ),
          children: [
            SurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Mode',
                    icon: Icons.tune_rounded,
                    accentColor: AppPalette.mint,
                  ),
                  const SizedBox(height: 16),
                  _ModeSelector(
                    value: _mode,
                    onChanged: _setMode,
                  ),
                  const SizedBox(height: 16),
                  _ThemeSelector(
                    value: _mermaidTheme,
                    onChanged: (theme) => setState(() => _mermaidTheme = theme),
                  ),
                  if (_mode == MermaidShowcaseMode.streaming) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        key: const Key('mermaid-showcase-replay'),
                        onPressed: _isStreaming ? null : _startStreaming,
                        icon: Icon(
                          _isStreaming
                              ? Icons.hourglass_top_rounded
                              : Icons.replay_rounded,
                        ),
                        label: Text(_isStreaming ? 'Streaming' : 'Replay'),
                      ),
                    ),
                  ],
                  if (_mode == MermaidShowcaseMode.errors) ...[
                    const SizedBox(height: 16),
                    _DiagnosticsPanel(
                      errorCount: _errorCount,
                      lastErrorType: _lastErrorType,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              padding: const EdgeInsets.all(18),
              child: _buildPreview(renderer, markdownTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(MermaidRenderer renderer, MarkdownTheme markdownTheme) {
    if (_mode == MermaidShowcaseMode.streaming && _streamController != null) {
      return SizedBox(
        height: 420,
        child: StreamingMarkdownView.fromStream(
          stream: _streamController!.stream,
          theme: markdownTheme,
          streamingOptions: _streamingOptions,
          renderOptions: _renderOptions(renderer),
        ),
      );
    }

    return MarkdownContent(
      content: _content,
      theme: markdownTheme,
      renderOptions: _renderOptions(renderer),
    );
  }

  Widget _buildInlineError(
    BuildContext context,
    MermaidErrorContext context_,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('mermaid-showcase-inline-error'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context_.error.runtimeType.toString(),
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            key: const Key('mermaid-showcase-error-retry'),
            onPressed: context_.retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsPanel extends StatelessWidget {
  const _DiagnosticsPanel({
    required this.errorCount,
    required this.lastErrorType,
  });

  final int errorCount;
  final String? lastErrorType;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mermaid-showcase-diagnostics'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(
              alpha: 0.42,
            ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bug_report_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 10),
          Text(
            'Errors: $errorCount',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lastErrorType ?? 'No error',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.value, required this.onChanged});

  final MermaidShowcaseMode value;
  final ValueChanged<MermaidShowcaseMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MermaidShowcaseMode>(
      segments: const [
        ButtonSegment(
          value: MermaidShowcaseMode.static,
          icon: Icon(Icons.schema_rounded),
          label: Text('Static'),
        ),
        ButtonSegment(
          value: MermaidShowcaseMode.streaming,
          icon: Icon(Icons.play_arrow_rounded),
          label: Text('Streaming'),
        ),
        ButtonSegment(
          value: MermaidShowcaseMode.errors,
          icon: Icon(Icons.error_outline_rounded),
          label: Text('Errors'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final MermaidTheme value;
  final ValueChanged<MermaidTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MermaidTheme>(
      segments: const [
        ButtonSegment(
          value: MermaidTheme.auto,
          icon: Icon(Icons.brightness_auto_rounded),
          label: Text('Auto'),
        ),
        ButtonSegment(
          value: MermaidTheme.light,
          icon: Icon(Icons.light_mode_rounded),
          label: Text('Light'),
        ),
        ButtonSegment(
          value: MermaidTheme.dark,
          icon: Icon(Icons.dark_mode_rounded),
          label: Text('Dark'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}
