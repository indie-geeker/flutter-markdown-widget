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
import '../widgets/metrics_panel.dart';
import '../widgets/option_tiles.dart';
import '../widgets/performance_monitor.dart';
import '../widgets/section_header.dart';
import '../widgets/surface_card.dart';

enum _DocSize {
  small('2K', 2000),
  medium('10K', 10000),
  large('30K', 30000);

  const _DocSize(this.label, this.targetChars);
  final String label;
  final int targetChars;
}

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  bool _enableVirtualScroll = true;
  double _virtualThreshold = 12;
  _DocSize _docSize = _DocSize.medium;
  bool _simulateStreaming = false;

  late String _document;
  late WidgetRenderCache _cache;
  late PerformanceMonitor _monitor;

  StreamController<String>? _streamController;
  Timer? _streamTimer;

  @override
  void initState() {
    super.initState();
    _cache = WidgetRenderCache();
    _monitor = PerformanceMonitor();
    _document = MarkdownSamples.buildPerformanceDocument(
      targetChars: _docSize.targetChars,
    );
    _monitor.start();
    _estimateBlockCounts();
  }

  @override
  void dispose() {
    _stopStreaming();
    _monitor.dispose();
    _cache.clear();
    super.dispose();
  }

  void _regenerateDocument() {
    _stopStreaming();
    _cache.clear();
    _cache.resetStats();
    setState(() {
      _document = MarkdownSamples.buildPerformanceDocument(
        targetChars: _docSize.targetChars,
      );
    });
    _estimateBlockCounts();
    if (_simulateStreaming) {
      _startStreaming();
    }
  }

  void _estimateBlockCounts() {
    final parser = IncrementalMarkdownParser(enableLatex: true);
    final result = parser.parse(_document);
    final total = result.blocks.length;
    // Rough estimate: 420px viewport / ~80px avg block height
    final visible = (420 / 80).round().clamp(0, total);
    _monitor.updateBlockCounts(total: total, visible: visible);
  }

  void _startStreaming() {
    _stopStreaming();
    _cache.clear();
    _cache.resetStats();
    _streamController = StreamController<String>();
    int charIndex = 0;
    const chunkSize = 50;
    _streamTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (charIndex >= _document.length) {
        _streamController?.close();
        timer.cancel();
        return;
      }
      final end = (charIndex + chunkSize).clamp(0, _document.length);
      _streamController?.add(_document.substring(charIndex, end));
      charIndex = end;
    });
  }

  void _stopStreaming() {
    _streamTimer?.cancel();
    _streamTimer = null;
    _streamController?.close();
    _streamController = null;
  }

  void _onStreamingToggle(bool value) {
    setState(() {
      _simulateStreaming = value;
    });
    if (value) {
      _startStreaming();
    } else {
      _stopStreaming();
      setState(() {});
    }
  }

  void _updateCacheStats() {
    _monitor.updateCacheStats(_cache);
  }

  RenderOptions _renderOptions() {
    return RenderOptions(
      enableVirtualScrolling: _enableVirtualScroll,
      virtualScrollThreshold: _virtualThreshold.round(),
      enableTables: true,
      enableTaskLists: true,
      enableCodeHighlight: true,
      enableLatex: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateCacheStats();

    final markdownTheme = ExampleTheme.markdownTheme(
      context,
      accent: AppPalette.accent,
      dense: true,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ExampleAppBar(
        title: 'Performance',
        icon: Icons.bolt_rounded,
        gradient: AppGradients.coral,
      ),
      body: AppBackground(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            20,
            24,
          ),
          child: Column(
            children: [
              MetricsPanel(
                monitor: _monitor,
                onReset: () {
                  _monitor.reset();
                  _cache.resetStats();
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    SurfaceCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: SectionHeader(
                              title: 'Controls',
                              subtitle:
                                  'Configure rendering and stress-test parameters.',
                              icon: Icons.tune_rounded,
                            ),
                          ),
                          OptionSwitchTile(
                            title: 'Virtual Scrolling',
                            value: _enableVirtualScroll,
                            onChanged: (v) =>
                                setState(() => _enableVirtualScroll = v),
                          ),
                          OptionSliderTile(
                            title: 'Virtual Threshold',
                            value: _virtualThreshold,
                            min: 6,
                            max: 24,
                            divisions: 9,
                            onChanged: (v) =>
                                setState(() => _virtualThreshold = v),
                            trailingLabel:
                                _virtualThreshold.toStringAsFixed(0),
                          ),
                          OptionSwitchTile(
                            title: 'Simulate Streaming',
                            value: _simulateStreaming,
                            onChanged: _onStreamingToggle,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Document Size',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: _DocSize.values.map((size) {
                                    final selected = size == _docSize;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(size.label),
                                        selected: selected,
                                        onSelected: (_) {
                                          setState(() => _docSize = size);
                                          _regenerateDocument();
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 420,
                      child: SurfaceCard(
                        padding: EdgeInsets.zero,
                        radius: 24,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              _monitor.onScroll(notification);
                              return false;
                            },
                            child: _buildMarkdownView(markdownTheme),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdownView(MarkdownTheme theme) {
    if (_simulateStreaming && _streamController != null) {
      return StreamingMarkdownView.fromStream(
        stream: _streamController!.stream,
        padding: const EdgeInsets.all(24),
        renderOptions: _renderOptions(),
        theme: theme,
        widgetCache: _cache,
      );
    }
    return StreamingMarkdownView(
      content: _document,
      padding: const EdgeInsets.all(24),
      renderOptions: _renderOptions(),
      theme: theme,
      widgetCache: _cache,
    );
  }
}
