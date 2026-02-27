// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../data/demo_entries.dart';
import '../widgets/app_background.dart';
import '../widgets/demo_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppBackground(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF38BDF8).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.text_snippet_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Flutter Markdown\nWidget',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            letterSpacing: -0.6,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'High-performance streaming markdown for modern Flutter apps.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),
                    const Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _FeatureChip(label: 'Streaming'),
                        _FeatureChip(label: 'TOC'),
                        _FeatureChip(label: 'LaTeX'),
                        _FeatureChip(label: 'Tables'),
                        _FeatureChip(label: 'Task Lists'),
                        _FeatureChip(label: 'Virtual Scroll'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = demoEntries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DemoCard(
                        entry: entry,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: entry.builder),
                        ),
                      ),
                    );
                  },
                  childCount: demoEntries.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
