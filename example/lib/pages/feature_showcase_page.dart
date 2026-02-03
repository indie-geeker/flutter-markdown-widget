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

enum PreviewMode {
  streamingView,
  markdownContent,
}

class FeatureShowcasePage extends StatefulWidget {
  const FeatureShowcasePage({super.key});

  @override
  State<FeatureShowcasePage> createState() => _FeatureShowcasePageState();
}

class _FeatureShowcasePageState extends State<FeatureShowcasePage> {
  bool _enableLatex = true;
  bool _enableCodeHighlight = true;
  bool _enableTables = true;
  bool _enableTaskLists = true;
  bool _enableStrikethrough = true;
  bool _enableAutolinks = true;
  bool _enableImageLoading = true;
  bool _selectableText = true;
  bool _enableVirtualScroll = true;

  bool _limitImageWidth = true;
  double _imageMaxWidth = 520;

  bool _limitCodeHeight = true;
  double _codeMaxHeight = 220;

  bool _denseTheme = false;
  bool _useLongDocument = false;

  PreviewMode _previewMode = PreviewMode.streamingView;
  late final String _longDocument;

  @override
  void initState() {
    super.initState();
    _longDocument = MarkdownSamples.buildLongDocument(sections: 20);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  RenderOptions _renderOptions() {
    return RenderOptions(
      enableLatex: _enableLatex,
      enableCodeHighlight: _enableCodeHighlight,
      enableTables: _enableTables,
      enableTaskLists: _enableTaskLists,
      enableStrikethrough: _enableStrikethrough,
      enableAutolinks: _enableAutolinks,
      enableImageLoading: _enableImageLoading,
      enableVirtualScrolling: _enableVirtualScroll,
      selectableText: _selectableText,
      maxImageWidth: _limitImageWidth ? _imageMaxWidth : null,
      codeBlockMaxHeight: _limitCodeHeight ? _codeMaxHeight : null,
      virtualScrollThreshold: 12,
      onLinkTap: (url, _) => _showMessage('Link tapped: $url'),
      onImageTap: (src, _) => _showMessage('Image tapped: $src'),
      onCodeCopy: (_, language) =>
          _showMessage('Code copied${language != null ? ' ($language)' : ''}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final content = _useLongDocument
        ? _longDocument
        : MarkdownSamples.featureShowcase;
    final markdownTheme = ExampleTheme.markdownTheme(
      context,
      accent: AppPalette.brand,
      dense: _denseTheme,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ExampleAppBar(
        title: 'Feature Showcase',
        icon: Icons.auto_awesome_rounded,
        gradient: AppGradients.ocean,
      ),
      body: AppBackground(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            20,
            24,
          ),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 360,
                      child: SingleChildScrollView(
                        child: _OptionsPanel(
                          previewMode: _previewMode,
                          onPreviewModeChanged: (mode) =>
                              setState(() => _previewMode = mode),
                          enableLatex: _enableLatex,
                          enableCodeHighlight: _enableCodeHighlight,
                          enableTables: _enableTables,
                          enableTaskLists: _enableTaskLists,
                          enableStrikethrough: _enableStrikethrough,
                          enableAutolinks: _enableAutolinks,
                          enableImageLoading: _enableImageLoading,
                          selectableText: _selectableText,
                          enableVirtualScroll: _enableVirtualScroll,
                          limitImageWidth: _limitImageWidth,
                          imageMaxWidth: _imageMaxWidth,
                          limitCodeHeight: _limitCodeHeight,
                          codeMaxHeight: _codeMaxHeight,
                          denseTheme: _denseTheme,
                          useLongDocument: _useLongDocument,
                          onToggleLatex: (v) =>
                              setState(() => _enableLatex = v),
                          onToggleCodeHighlight: (v) =>
                              setState(() => _enableCodeHighlight = v),
                          onToggleTables: (v) =>
                              setState(() => _enableTables = v),
                          onToggleTaskLists: (v) =>
                              setState(() => _enableTaskLists = v),
                          onToggleStrikethrough: (v) =>
                              setState(() => _enableStrikethrough = v),
                          onToggleAutolinks: (v) =>
                              setState(() => _enableAutolinks = v),
                          onToggleImages: (v) =>
                              setState(() => _enableImageLoading = v),
                          onToggleSelectable: (v) =>
                              setState(() => _selectableText = v),
                          onToggleVirtualScroll: (v) =>
                              setState(() => _enableVirtualScroll = v),
                          onToggleLimitImage: (v) =>
                              setState(() => _limitImageWidth = v),
                          onImageMaxWidthChanged: (v) =>
                              setState(() => _imageMaxWidth = v),
                          onToggleLimitCode: (v) =>
                              setState(() => _limitCodeHeight = v),
                          onCodeMaxHeightChanged: (v) =>
                              setState(() => _codeMaxHeight = v),
                          onToggleDenseTheme: (v) =>
                              setState(() => _denseTheme = v),
                          onToggleLongDoc: (v) =>
                              setState(() => _useLongDocument = v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _PreviewCard(
                        previewMode: _previewMode,
                        content: content,
                        theme: markdownTheme,
                        renderOptions: _renderOptions(),
                      ),
                    ),
                  ],
                )
              : ListView(
                  children: [
                    _OptionsPanel(
                      previewMode: _previewMode,
                      onPreviewModeChanged: (mode) =>
                          setState(() => _previewMode = mode),
                      enableLatex: _enableLatex,
                      enableCodeHighlight: _enableCodeHighlight,
                      enableTables: _enableTables,
                      enableTaskLists: _enableTaskLists,
                      enableStrikethrough: _enableStrikethrough,
                      enableAutolinks: _enableAutolinks,
                      enableImageLoading: _enableImageLoading,
                      selectableText: _selectableText,
                      enableVirtualScroll: _enableVirtualScroll,
                      limitImageWidth: _limitImageWidth,
                      imageMaxWidth: _imageMaxWidth,
                      limitCodeHeight: _limitCodeHeight,
                      codeMaxHeight: _codeMaxHeight,
                      denseTheme: _denseTheme,
                      useLongDocument: _useLongDocument,
                      onToggleLatex: (v) => setState(() => _enableLatex = v),
                      onToggleCodeHighlight: (v) =>
                          setState(() => _enableCodeHighlight = v),
                      onToggleTables: (v) => setState(() => _enableTables = v),
                      onToggleTaskLists: (v) =>
                          setState(() => _enableTaskLists = v),
                      onToggleStrikethrough: (v) =>
                          setState(() => _enableStrikethrough = v),
                      onToggleAutolinks: (v) =>
                          setState(() => _enableAutolinks = v),
                      onToggleImages: (v) =>
                          setState(() => _enableImageLoading = v),
                      onToggleSelectable: (v) =>
                          setState(() => _selectableText = v),
                      onToggleVirtualScroll: (v) =>
                          setState(() => _enableVirtualScroll = v),
                      onToggleLimitImage: (v) =>
                          setState(() => _limitImageWidth = v),
                      onImageMaxWidthChanged: (v) =>
                          setState(() => _imageMaxWidth = v),
                      onToggleLimitCode: (v) =>
                          setState(() => _limitCodeHeight = v),
                      onCodeMaxHeightChanged: (v) =>
                          setState(() => _codeMaxHeight = v),
                      onToggleDenseTheme: (v) =>
                          setState(() => _denseTheme = v),
                      onToggleLongDoc: (v) =>
                          setState(() => _useLongDocument = v),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 560,
                      child: _PreviewCard(
                        previewMode: _previewMode,
                        content: content,
                        theme: markdownTheme,
                        renderOptions: _renderOptions(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.previewMode,
    required this.content,
    required this.theme,
    required this.renderOptions,
  });

  final PreviewMode previewMode;
  final String content;
  final MarkdownTheme theme;
  final RenderOptions renderOptions;

  @override
  Widget build(BuildContext context) {
    Widget preview;

    if (previewMode == PreviewMode.markdownContent) {
      preview = SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: MarkdownContent(
          content: content,
          theme: theme,
          renderOptions: renderOptions,
        ),
      );
    } else {
      preview = StreamingMarkdownView(
        content: content,
        padding: const EdgeInsets.all(24),
        theme: theme,
        renderOptions: renderOptions,
      );
    }

    return SurfaceCard(
      padding: EdgeInsets.zero,
      radius: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: preview,
      ),
    );
  }
}

class _OptionsPanel extends StatelessWidget {
  const _OptionsPanel({
    required this.previewMode,
    required this.onPreviewModeChanged,
    required this.enableLatex,
    required this.enableCodeHighlight,
    required this.enableTables,
    required this.enableTaskLists,
    required this.enableStrikethrough,
    required this.enableAutolinks,
    required this.enableImageLoading,
    required this.selectableText,
    required this.enableVirtualScroll,
    required this.limitImageWidth,
    required this.imageMaxWidth,
    required this.limitCodeHeight,
    required this.codeMaxHeight,
    required this.denseTheme,
    required this.useLongDocument,
    required this.onToggleLatex,
    required this.onToggleCodeHighlight,
    required this.onToggleTables,
    required this.onToggleTaskLists,
    required this.onToggleStrikethrough,
    required this.onToggleAutolinks,
    required this.onToggleImages,
    required this.onToggleSelectable,
    required this.onToggleVirtualScroll,
    required this.onToggleLimitImage,
    required this.onImageMaxWidthChanged,
    required this.onToggleLimitCode,
    required this.onCodeMaxHeightChanged,
    required this.onToggleDenseTheme,
    required this.onToggleLongDoc,
  });

  final PreviewMode previewMode;
  final ValueChanged<PreviewMode> onPreviewModeChanged;
  final bool enableLatex;
  final bool enableCodeHighlight;
  final bool enableTables;
  final bool enableTaskLists;
  final bool enableStrikethrough;
  final bool enableAutolinks;
  final bool enableImageLoading;
  final bool selectableText;
  final bool enableVirtualScroll;
  final bool limitImageWidth;
  final double imageMaxWidth;
  final bool limitCodeHeight;
  final double codeMaxHeight;
  final bool denseTheme;
  final bool useLongDocument;
  final ValueChanged<bool> onToggleLatex;
  final ValueChanged<bool> onToggleCodeHighlight;
  final ValueChanged<bool> onToggleTables;
  final ValueChanged<bool> onToggleTaskLists;
  final ValueChanged<bool> onToggleStrikethrough;
  final ValueChanged<bool> onToggleAutolinks;
  final ValueChanged<bool> onToggleImages;
  final ValueChanged<bool> onToggleSelectable;
  final ValueChanged<bool> onToggleVirtualScroll;
  final ValueChanged<bool> onToggleLimitImage;
  final ValueChanged<double> onImageMaxWidthChanged;
  final ValueChanged<bool> onToggleLimitCode;
  final ValueChanged<double> onCodeMaxHeightChanged;
  final ValueChanged<bool> onToggleDenseTheme;
  final ValueChanged<bool> onToggleLongDoc;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SectionHeader(
              title: 'Renderer',
              subtitle: 'Switch between widgets for different embedding needs.',
              icon: Icons.view_in_ar_outlined,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<PreviewMode>(
              segments: const [
                ButtonSegment(
                  value: PreviewMode.streamingView,
                  label: Text('StreamingView'),
                ),
                ButtonSegment(
                  value: PreviewMode.markdownContent,
                  label: Text('MarkdownContent'),
                ),
              ],
              selected: {previewMode},
              onSelectionChanged: (value) =>
                  onPreviewModeChanged(value.first),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SectionHeader(
              title: 'Render Options',
              subtitle: 'Toggle features supported by RenderOptions.',
              icon: Icons.tune_rounded,
            ),
          ),
          OptionSwitchTile(
            title: 'LaTeX Math',
            value: enableLatex,
            onChanged: onToggleLatex,
          ),
          OptionSwitchTile(
            title: 'Code Highlight',
            value: enableCodeHighlight,
            onChanged: onToggleCodeHighlight,
          ),
          OptionSwitchTile(
            title: 'Tables',
            value: enableTables,
            onChanged: onToggleTables,
          ),
          OptionSwitchTile(
            title: 'Task Lists',
            value: enableTaskLists,
            onChanged: onToggleTaskLists,
          ),
          OptionSwitchTile(
            title: 'Strikethrough',
            value: enableStrikethrough,
            onChanged: onToggleStrikethrough,
          ),
          OptionSwitchTile(
            title: 'Autolinks',
            value: enableAutolinks,
            onChanged: onToggleAutolinks,
          ),
          OptionSwitchTile(
            title: 'Image Loading',
            value: enableImageLoading,
            onChanged: onToggleImages,
          ),
          OptionSwitchTile(
            title: 'Selectable Text',
            value: selectableText,
            onChanged: onToggleSelectable,
          ),
          OptionSwitchTile(
            title: 'Virtual Scrolling',
            value: enableVirtualScroll,
            onChanged: onToggleVirtualScroll,
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SectionHeader(
              title: 'Layout & Limits',
              subtitle: 'Constrain images and code blocks as needed.',
              icon: Icons.aspect_ratio_rounded,
            ),
          ),
          OptionSwitchTile(
            title: 'Limit Image Width',
            value: limitImageWidth,
            onChanged: onToggleLimitImage,
          ),
          if (limitImageWidth)
            OptionSliderTile(
              title: 'Image Max Width',
              value: imageMaxWidth,
              min: 280,
              max: 720,
              divisions: 11,
              onChanged: onImageMaxWidthChanged,
              trailingLabel: '${imageMaxWidth.toStringAsFixed(0)}px',
            ),
          OptionSwitchTile(
            title: 'Limit Code Height',
            value: limitCodeHeight,
            onChanged: onToggleLimitCode,
          ),
          if (limitCodeHeight)
            OptionSliderTile(
              title: 'Code Block Max Height',
              value: codeMaxHeight,
              min: 160,
              max: 420,
              divisions: 13,
              onChanged: onCodeMaxHeightChanged,
              trailingLabel: '${codeMaxHeight.toStringAsFixed(0)}px',
            ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SectionHeader(
              title: 'Document',
              subtitle: 'Test the renderer with long-form content.',
              icon: Icons.notes_rounded,
            ),
          ),
          OptionSwitchTile(
            title: 'Use Long Document',
            value: useLongDocument,
            onChanged: onToggleLongDoc,
          ),
          OptionSwitchTile(
            title: 'Compact Theme',
            value: denseTheme,
            onChanged: onToggleDenseTheme,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
