// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';

import '../app/app_theme.dart';
import '../data/markdown_samples.dart';
import '../widgets/app_background.dart';
import '../widgets/example_app_bar.dart';
import '../widgets/option_tiles.dart';
import '../widgets/section_header.dart';
import '../widgets/surface_card.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  bool _enableVirtualScroll = true;
  double _virtualThreshold = 12;
  late final String _longDocument;

  static const String _embeddedSnippet = r'''
### Embedded MarkdownContent

Use this widget inside your own scroll views or layouts.

- No internal scrolling
- Great for chat bubbles
- Lightweight column rendering
''';

  @override
  void initState() {
    super.initState();
    _longDocument = MarkdownSamples.buildLongDocument(sections: 24);
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
                        title: 'Virtual Scrolling',
                        subtitle:
                            'Render only visible blocks for long documents.',
                        icon: Icons.blur_on_rounded,
                      ),
                    ),
                    OptionSwitchTile(
                      title: 'Enable Virtual Scrolling',
                      value: _enableVirtualScroll,
                      onChanged: (v) => setState(() => _enableVirtualScroll = v),
                    ),
                    OptionSliderTile(
                      title: 'Virtual Scroll Threshold',
                      value: _virtualThreshold,
                      min: 6,
                      max: 24,
                      divisions: 9,
                      onChanged: (v) => setState(() => _virtualThreshold = v),
                      trailingLabel: _virtualThreshold.toStringAsFixed(0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                padding: EdgeInsets.zero,
                radius: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: MarkdownContent(
                      content: _embeddedSnippet,
                      theme: markdownTheme,
                      renderOptions: const RenderOptions(
                        enableTables: false,
                        enableLatex: false,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 520,
                child: SurfaceCard(
                  padding: EdgeInsets.zero,
                  radius: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: StreamingMarkdownView(
                      content: _longDocument,
                      padding: const EdgeInsets.all(24),
                      renderOptions: _renderOptions(),
                      theme: markdownTheme,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
