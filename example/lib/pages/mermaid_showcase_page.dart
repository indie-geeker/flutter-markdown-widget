// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// ignore_for_file: experimental_member_use

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
      ),
    );
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
                    onChanged: (mode) => setState(() => _mode = mode),
                  ),
                  const SizedBox(height: 16),
                  _ThemeSelector(
                    value: _mermaidTheme,
                    onChanged: (theme) => setState(() => _mermaidTheme = theme),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              padding: const EdgeInsets.all(18),
              child: MarkdownContent(
                content: _content,
                theme: markdownTheme,
                renderOptions: _renderOptions(renderer),
              ),
            ),
          ],
        ),
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
