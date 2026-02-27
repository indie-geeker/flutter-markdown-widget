// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';

import '../app/app_theme.dart';
import '../data/markdown_samples.dart';
import '../widgets/app_background.dart';
import '../widgets/example_app_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/surface_card.dart';

class TocDemoPage extends StatefulWidget {
  const TocDemoPage({super.key});

  @override
  State<TocDemoPage> createState() => _TocDemoPageState();
}

class _TocDemoPageState extends State<TocDemoPage> {
  final TocController _tocController = TocController();
  bool _syncDuringJump = false;

  @override
  void dispose() {
    _tocController.dispose();
    super.dispose();
  }

  void _openTocSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SectionHeader(
                      title: 'Table of Contents',
                      subtitle: 'Jump to any heading in the document.',
                      icon: Icons.toc_rounded,
                    ),
                  ),
                  const Divider(height: 1),
                  SizedBox(
                    height: 360,
                    child: TocListWidget(
                      controller: _tocController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      activeBackgroundColor:
                          AppPalette.mint.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;
    final markdownTheme = ExampleTheme.markdownTheme(
      context,
      accent: AppPalette.mint,
    );

    final tocPanel = SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SectionHeader(
              title: 'Contents',
              subtitle: 'Tap to jump between headings.',
              icon: Icons.toc_rounded,
              accentColor: AppPalette.mint,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sync during jump',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ),
                Switch.adaptive(
                  value: _syncDuringJump,
                  activeThumbColor: AppPalette.mint,
                  activeTrackColor: AppPalette.mint.withValues(alpha: 0.35),
                  onChanged: (value) {
                    setState(() {
                      _syncDuringJump = value;
                      _tocController.syncTocDuringJump = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TocListWidget(
              controller: _tocController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              activeBackgroundColor: AppPalette.mint.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );

    final contentPanel = SurfaceCard(
      padding: EdgeInsets.zero,
      radius: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: MarkdownWidget(
          data: MarkdownSamples.tocContent,
          tocController: _tocController,
          padding: const EdgeInsets.all(28),
          theme: markdownTheme,
        ),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ExampleAppBar(
        title: 'TOC Navigator',
        icon: Icons.list_alt_rounded,
        gradient: AppGradients.emerald,
        actions: isWide
            ? null
            : [
                IconButton(
                  onPressed: _openTocSheet,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppPalette.mint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.toc_rounded, size: 18),
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
          child: isWide
              ? Row(
                  children: [
                    SizedBox(width: 300, child: tocPanel),
                    const SizedBox(width: 20),
                    Expanded(child: contentPanel),
                  ],
                )
              : Column(
                  children: [
                    SurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.toc_rounded, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Open Table of Contents')),
                          TextButton(
                            onPressed: _openTocSheet,
                            child: const Text('Open'),
                          ),
                          Switch.adaptive(
                            value: _syncDuringJump,
                            activeThumbColor: AppPalette.mint,
                            activeTrackColor:
                                AppPalette.mint.withValues(alpha: 0.35),
                            onChanged: (value) {
                              setState(() {
                                _syncDuringJump = value;
                                _tocController.syncTocDuringJump = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: contentPanel),
                  ],
                ),
        ),
      ),
    );
  }
}
