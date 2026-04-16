import 'package:flutter/material.dart';

import 'performance_monitor.dart';
import 'surface_card.dart';

/// Displays real-time performance metrics in a compact panel.
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
        return SurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow1(context),
              const SizedBox(height: 6),
              _buildRow2(context),
              const SizedBox(height: 6),
              _buildRow3(context),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow1(BuildContext context) {
    return Row(
      children: [
        _MetricChip(
          label: 'FPS',
          value: monitor.fps.toStringAsFixed(1),
          color: _fpsColor(monitor.fps),
          flex: 2,
        ),
        const SizedBox(width: 8),
        _MetricChip(
          label: 'Jank',
          value: '${monitor.jankCount}',
          color: monitor.jankCount > 0 ? Colors.orange : Colors.green,
          flex: 1,
        ),
        const SizedBox(width: 8),
        _MetricChip(
          label: 'Scroll',
          value: '${monitor.scrollVelocity.toStringAsFixed(0)} px/s',
          flex: 2,
        ),
      ],
    );
  }

  Widget _buildRow2(BuildContext context) {
    return Row(
      children: [
        _MetricChip(
          label: 'Build',
          value: '${monitor.buildTimeMs.toStringAsFixed(1)} ms',
          flex: 1,
        ),
        const SizedBox(width: 8),
        _MetricChip(
          label: 'Raster',
          value: '${monitor.rasterTimeMs.toStringAsFixed(1)} ms',
          flex: 1,
        ),
      ],
    );
  }

  Widget _buildRow3(BuildContext context) {
    final hitPct = (monitor.cacheHitRate * 100).toStringAsFixed(0);
    return Row(
      children: [
        _MetricChip(
          label: 'Cache',
          value: '$hitPct%',
          flex: 1,
        ),
        const SizedBox(width: 8),
        _MetricChip(
          label: 'Visible',
          value: '${monitor.visibleBlocks}',
          flex: 1,
        ),
        const SizedBox(width: 8),
        _MetricChip(
          label: 'Total',
          value: '${monitor.totalBlocks}',
          flex: 1,
        ),
      ],
    );
  }

  static Color _fpsColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 30) return Colors.orange;
    return Colors.red;
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    this.color,
    this.flex = 1,
  });

  final String label;
  final String value;
  final Color? color;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white54 : Colors.black45;
    final valueColor = color ?? (isDark ? Colors.white : Colors.black87);

    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: labelColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
