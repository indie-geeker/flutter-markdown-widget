// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'performance_monitor.dart';
import 'surface_card.dart';

/// Displays real-time performance metrics in a polished dashboard panel.
class MetricsPanel extends StatelessWidget {
  const MetricsPanel({
    super.key,
    required this.monitor,
    this.onReset,
  });

  final PerformanceMonitor monitor;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return SurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isDark),
              const SizedBox(height: 12),
              _buildMetricsGrid(context, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Metrics',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
        ),
        const Spacer(),
        _StatusIndicator(isRunning: monitor.isRunning, isDark: isDark),
        const SizedBox(width: 8),
        SizedBox(
          height: 30,
          width: 30,
          child: IconButton(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            tooltip: 'Reset metrics',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, bool isDark) {
    final worstMs = monitor.worstFrameMs;
    return Column(
      children: [
        Row(
          children: [
            _MetricTile(
              icon: Icons.speed_rounded,
              color: _fpsColor(monitor.fps),
              label: 'FPS',
              value: monitor.fps.toStringAsFixed(1),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _MetricTile(
              icon: Icons.warning_amber_rounded,
              color: monitor.jankCount > 0
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
              label: 'Jank',
              value: monitor.jankCount.toString(),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _MetricTile(
              icon: Icons.swap_vert_rounded,
              color: const Color(0xFF6366F1),
              label: 'Scroll',
              value: monitor.scrollVelocity.toStringAsFixed(0),
              unit: 'px/s',
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _MetricTile(
              icon: Icons.hourglass_bottom_rounded,
              color: _worstFrameColor(worstMs),
              label: 'Worst',
              value: worstMs.toStringAsFixed(1),
              unit: 'ms',
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _MetricTile(
              icon: Icons.construction_rounded,
              color: const Color(0xFFF97316),
              label: 'Build',
              value: monitor.buildTimeMs.toStringAsFixed(1),
              unit: 'ms',
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _MetricTile(
              icon: Icons.brush_rounded,
              color: const Color(0xFFF43F5E),
              label: 'Raster',
              value: monitor.rasterTimeMs.toStringAsFixed(1),
              unit: 'ms',
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _MetricTile(
              icon: Icons.visibility_rounded,
              color: const Color(0xFF10B981),
              label: 'Visible',
              value: monitor.visibleBlocks.toString(),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _MetricTile(
              icon: Icons.layers_rounded,
              color: const Color(0xFF818CF8),
              label: 'Total',
              value: '${monitor.totalBlocks}',
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  static Color _fpsColor(double fps) {
    if (fps >= 55) return const Color(0xFF10B981);
    if (fps >= 30) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // 16.67ms = 60fps budget. Above that = dropped frame; above 2 budgets = bad.
  static Color _worstFrameColor(double ms) {
    if (ms <= 16.67) return const Color(0xFF10B981);
    if (ms <= 33.34) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.isRunning, required this.isDark});

  final bool isRunning;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isRunning ? const Color(0xFF10B981) : Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: isRunning
                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          isRunning ? 'Live' : 'Paused',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
    this.unit,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? unit;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.15 : 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: color,
                      height: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
