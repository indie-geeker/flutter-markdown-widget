// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../pages/editor_preview_page.dart';
import '../pages/feature_showcase_page.dart';
import '../pages/performance_page.dart';
import '../pages/streaming_lab_page.dart';
import '../pages/toc_demo_page.dart';

class DemoEntry {
  const DemoEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.builder,
    this.badges = const [],
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final WidgetBuilder builder;
  final List<String> badges;
}

final List<DemoEntry> demoEntries = [
  DemoEntry(
    title: 'Editor Preview',
    description: 'Split layout with live markdown editing and preview.',
    icon: Icons.edit_note_rounded,
    gradient: AppGradients.amber,
    badges: ['Live Editing', 'Side by Side'],
    builder: (_) => const EditorPreviewPage(),
  ),
  DemoEntry(
    title: 'Feature Showcase',
    description: 'GFM, LaTeX, tables, images, and theming in one place.',
    icon: Icons.auto_awesome_rounded,
    gradient: AppGradients.ocean,
    badges: ['RenderOptions', 'MarkdownTheme'],
    builder: (_) => const FeatureShowcasePage(),
  ),
  DemoEntry(
    title: 'Streaming Lab',
    description: 'Real-time rendering with buffer modes and cursor control.',
    icon: Icons.smart_toy_outlined,
    gradient: AppGradients.violet,
    badges: ['StreamingOptions'],
    builder: (_) => const StreamingLabPage(),
  ),
  DemoEntry(
    title: 'TOC Navigator',
    description: 'Interactive table of contents with smooth jumps.',
    icon: Icons.list_alt_rounded,
    gradient: AppGradients.emerald,
    badges: ['TocController'],
    builder: (_) => const TocDemoPage(),
  ),
  DemoEntry(
    title: 'Performance',
    description: 'Virtual scrolling and embedded markdown patterns.',
    icon: Icons.bolt_rounded,
    gradient: AppGradients.coral,
    badges: ['Virtual Scroll'],
    builder: (_) => const PerformancePage(),
  ),
];
