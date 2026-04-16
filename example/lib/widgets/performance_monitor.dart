import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';

/// Collects real-time performance metrics for the example app dashboard.
///
/// Uses [WidgetsBinding.addTimingsCallback] for frame timing and
/// accepts external scroll/cache data via update methods.
class PerformanceMonitor extends ChangeNotifier {
  PerformanceMonitor({this.rollingWindowSize = 60});

  /// Number of frames to average over.
  final int rollingWindowSize;

  // Frame timing data
  final Queue<FrameTiming> _frameTimings = Queue<FrameTiming>();
  int _jankCount = 0;
  int _totalFrames = 0;

  // Scroll data
  double _scrollVelocity = 0.0;
  DateTime? _lastScrollTime;
  double? _lastScrollOffset;

  // Cache data
  double _cacheHitRate = 0.0;
  int _cacheSize = 0;

  // Content data
  int _totalBlocks = 0;
  int _visibleBlocks = 0;

  // Internal
  Timer? _refreshTimer;
  bool _isRunning = false;

  // --- Public getters ---

  /// Frames per second (rolling average).
  double get fps {
    if (_frameTimings.isEmpty) return 0.0;
    final totalDuration = _frameTimings.fold<Duration>(
      Duration.zero,
      (sum, timing) => sum + timing.totalSpan,
    );
    if (totalDuration.inMicroseconds == 0) return 0.0;
    return _frameTimings.length /
        (totalDuration.inMicroseconds / Duration.microsecondsPerSecond);
  }

  /// Average build duration in milliseconds.
  double get buildTimeMs {
    if (_frameTimings.isEmpty) return 0.0;
    final total = _frameTimings.fold<int>(
      0,
      (sum, timing) => sum + timing.buildDuration.inMicroseconds,
    );
    return total / _frameTimings.length / 1000.0;
  }

  /// Average raster duration in milliseconds.
  double get rasterTimeMs {
    if (_frameTimings.isEmpty) return 0.0;
    final total = _frameTimings.fold<int>(
      0,
      (sum, timing) => sum + timing.rasterDuration.inMicroseconds,
    );
    return total / _frameTimings.length / 1000.0;
  }

  /// Number of janky frames (total > 16.67ms) since last reset.
  int get jankCount => _jankCount;

  /// Total frames recorded since last reset.
  int get totalFrames => _totalFrames;

  /// Current scroll velocity in pixels per second.
  double get scrollVelocity => _scrollVelocity;

  /// Cache hit rate (0.0 to 1.0).
  double get cacheHitRate => _cacheHitRate;

  /// Current cache size.
  int get cacheSize => _cacheSize;

  /// Total content blocks in the document.
  int get totalBlocks => _totalBlocks;

  /// Estimated visible blocks in the viewport.
  int get visibleBlocks => _visibleBlocks;

  /// Whether the monitor is actively collecting.
  bool get isRunning => _isRunning;

  // --- Lifecycle ---

  /// Starts collecting frame timing data.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);
    _refreshTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => notifyListeners(),
    );
  }

  /// Stops collecting and cancels the refresh timer.
  void stop() {
    if (!_isRunning) return;
    _isRunning = false;
    WidgetsBinding.instance.removeTimingsCallback(_onFrameTimings);
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Resets all counters and timings.
  void reset() {
    _frameTimings.clear();
    _jankCount = 0;
    _totalFrames = 0;
    _scrollVelocity = 0.0;
    _lastScrollTime = null;
    _lastScrollOffset = null;
    _cacheHitRate = 0.0;
    _cacheSize = 0;
    _totalBlocks = 0;
    _visibleBlocks = 0;
    notifyListeners();
  }

  // --- External data feeds ---

  /// Call from a [NotificationListener] wrapping the scroll view.
  void onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final now = DateTime.now();
      final offset = notification.metrics.pixels;

      if (_lastScrollTime != null && _lastScrollOffset != null) {
        final dtSeconds =
            now.difference(_lastScrollTime!).inMicroseconds /
            Duration.microsecondsPerSecond;
        if (dtSeconds > 0) {
          final velocity = (offset - _lastScrollOffset!).abs() / dtSeconds;
          // Smoothed: 70% new, 30% old
          _scrollVelocity = velocity * 0.7 + _scrollVelocity * 0.3;
        }
      }

      _lastScrollTime = now;
      _lastScrollOffset = offset;
    }

    if (notification is ScrollEndNotification) {
      _scrollVelocity = 0.0;
    }
  }

  /// Updates cache stats from an external [WidgetRenderCache].
  void updateCacheStats(WidgetRenderCache cache) {
    _cacheHitRate = cache.hitRate;
    _cacheSize = cache.size;
  }

  /// Sets content block counts.
  void updateBlockCounts({required int total, required int visible}) {
    _totalBlocks = total;
    _visibleBlocks = visible;
  }

  // --- Internal ---

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frameTimings.addLast(timing);
      _totalFrames++;

      if (timing.totalSpan.inMicroseconds > 16667) {
        _jankCount++;
      }

      while (_frameTimings.length > rollingWindowSize) {
        _frameTimings.removeFirst();
      }
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
