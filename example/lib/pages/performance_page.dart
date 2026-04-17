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
  small('2K', 'Small', 2000, Icons.article_outlined),
  medium('10K', 'Medium', 10000, Icons.menu_book_rounded),
  large('30K', 'Large', 30000, Icons.library_books_rounded);

  const _DocSize(this.label, this.description, this.targetChars, this.icon);
  final String label;
  final String description;
  final int targetChars;
  final IconData icon;
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
  bool _includeImages = false;

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
      includeImages: _includeImages,
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
    setState(() {
      _document = MarkdownSamples.buildPerformanceDocument(
        targetChars: _docSize.targetChars,
        includeImages: _includeImages,
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

  // Each toggle creates a fresh StreamController. _stopStreaming() closes the
  // old one; StreamingMarkdownView.didUpdateWidget detects the new stream and
  // resubscribes automatically.
  void _startStreaming() {
    _stopStreaming();
    _cache.clear();
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

  void _onIncludeImagesToggle(bool value) {
    setState(() => _includeImages = value);
    _regenerateDocument();
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
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _buildControlsCard(context),
                    const SizedBox(height: 12),
                    _buildPreviewCard(context, markdownTheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: SectionHeader(
              title: 'Controls',
              subtitle: 'Configure rendering and stress-test parameters.',
              icon: Icons.tune_rounded,
            ),
          ),
          Divider(height: 16, thickness: 0.5, color: dividerColor),
          OptionSwitchTile(
            icon: Icons.view_list_rounded,
            title: 'Virtual Scrolling',
            subtitle: 'Render only blocks near the viewport',
            value: _enableVirtualScroll,
            onChanged: (v) => setState(() => _enableVirtualScroll = v),
          ),
          OptionSliderTile(
            title: 'Virtual Threshold',
            value: _virtualThreshold,
            min: 6,
            max: 24,
            divisions: 9,
            onChanged: (v) => setState(() => _virtualThreshold = v),
            trailingLabel: _virtualThreshold.toStringAsFixed(0),
          ),
          Divider(
            height: 8,
            thickness: 0.5,
            color: dividerColor,
            indent: 16,
            endIndent: 16,
          ),
          OptionSwitchTile(
            icon: Icons.graphic_eq_rounded,
            title: 'Simulate Streaming',
            subtitle: 'Emit content in 50-char chunks at 60Hz',
            value: _simulateStreaming,
            onChanged: _onStreamingToggle,
          ),
          OptionSwitchTile(
            icon: Icons.image_rounded,
            title: 'Include Images',
            subtitle: _docSize == _DocSize.small
                ? 'Disabled for Small — use Medium or Large'
                : 'Inject remote images every 6 sections',
            value: _includeImages,
            onChanged: _docSize == _DocSize.small
                ? (_) {}
                : _onIncludeImagesToggle,
          ),
          Divider(
            height: 8,
            thickness: 0.5,
            color: dividerColor,
            indent: 16,
            endIndent: 16,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.straighten_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Document Size',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${_docSize.targetChars ~/ 1000}K chars',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SizeSegmentedControl(
                  selected: _docSize,
                  onChanged: (size) {
                    setState(() {
                      _docSize = size;
                      if (size == _DocSize.small) _includeImages = false;
                    });
                    _regenerateDocument();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, MarkdownTheme theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor =
        _simulateStreaming ? AppPalette.accent : AppPalette.mint;
    final statusLabel = _simulateStreaming ? 'Streaming' : 'Static';

    return SizedBox(
      height: 460,
      child: SurfaceCard(
        padding: EdgeInsets.zero,
        radius: 24,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
              child: Row(
                children: [
                  Icon(_docSize.icon,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${_docSize.description} · ${_docSize.label}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  if (_includeImages)
                    const _PreviewTag(
                      icon: Icons.image_rounded,
                      label: 'Images',
                      color: AppPalette.indigo,
                    ),
                  const Spacer(),
                  _PreviewTag(
                    icon: _simulateStreaming
                        ? Icons.graphic_eq_rounded
                        : Icons.check_circle_rounded,
                    label: statusLabel,
                    color: statusColor,
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    _monitor.onScroll(notification);
                    return false;
                  },
                  child: _buildMarkdownView(theme),
                ),
              ),
            ),
          ],
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

class _SizeSegmentedControl extends StatelessWidget {
  const _SizeSegmentedControl({
    required this.selected,
    required this.onChanged,
  });

  final _DocSize selected;
  final ValueChanged<_DocSize> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: _DocSize.values.map((size) {
          final isSelected = size == selected;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(size),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: isDark ? 0.18 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? primary.withValues(alpha: 0.35)
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      size.icon,
                      size: 18,
                      color: isSelected
                          ? primary
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      size.description,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? primary
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                    Text(
                      size.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: isSelected
                            ? primary.withValues(alpha: 0.8)
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PreviewTag extends StatelessWidget {
  const _PreviewTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
