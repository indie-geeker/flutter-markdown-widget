# Performance Optimization & Metrics Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Optimize markdown rendering performance for 10,000+ character documents during rapid scrolling (both streaming and static), and build a real-time metrics dashboard in the example app's Performance page.

**Architecture:** Six targeted library fixes (O(1) LRU cache, content-hash keys, RepaintBoundary, Opacity guard, cache extent increase, external cache injection) plus a `PerformanceMonitor` / `MetricsPanel` in the example app that displays FPS, frame times, jank count, scroll velocity, cache hit rate, and block counts.

**Tech Stack:** Flutter/Dart, `WidgetsBinding.addTimingsCallback` for frame timing, `NotificationListener<ScrollNotification>` for scroll velocity, `LinkedHashMap` for O(1) LRU.

**Spec:** `docs/superpowers/specs/2026-04-16-performance-optimization-design.md`

---

## File Map

### Library files (modified)

| File | Changes |
|------|---------|
| `lib/src/core/cache/widget_cache.dart` | Rewrite to `LinkedHashMap`, add hit/miss stats |
| `lib/src/widgets/virtual_markdown_list.dart` | Content-hash keys, RepaintBoundary, Opacity guard, accept external cache |
| `lib/src/widgets/streaming_markdown_view.dart` | Accept external `widgetCache` + `cacheExtent`, pass through to VirtualMarkdownList |

### Example app files (new + modified)

| File | Changes |
|------|---------|
| `example/lib/widgets/performance_monitor.dart` | New — `PerformanceMonitor` ChangeNotifier |
| `example/lib/widgets/metrics_panel.dart` | New — `MetricsPanel` widget |
| `example/lib/data/markdown_samples.dart` | Add `buildPerformanceDocument()` |
| `example/lib/pages/performance_page.dart` | Full rewrite with dashboard |

### Test files (modified + new)

| File | Changes |
|------|---------|
| `test/cache_test.dart` | Add LRU LinkedHashMap tests, stats tests |
| `test/widget_test.dart` | Add RepaintBoundary and content-hash key tests |

---

## Task 1: O(1) LRU Cache with Hit/Miss Stats

**Files:**
- Modify: `lib/src/core/cache/widget_cache.dart`
- Modify: `test/cache_test.dart`

This task rewrites `WidgetRenderCache` to use `LinkedHashMap` for O(1) LRU and adds hit/miss counters.

- [ ] **Step 1: Write failing tests for stats API**

Add to `test/cache_test.dart` inside the existing `group('WidgetRenderCache', ...)`:

```dart
    test('tracks cache hits', () {
      final cache = WidgetRenderCache();
      cache.getOrBuild(111, () => const Text('A'));
      cache.getOrBuild(111, () => const Text('A'));
      cache.getOrBuild(111, () => const Text('A'));

      expect(cache.hits, 2);
      expect(cache.misses, 1);
    });

    test('tracks cache misses', () {
      final cache = WidgetRenderCache();
      cache.getOrBuild(111, () => const Text('A'));
      cache.getOrBuild(222, () => const Text('B'));

      expect(cache.hits, 0);
      expect(cache.misses, 2);
    });

    test('hitRate computes correctly', () {
      final cache = WidgetRenderCache();
      cache.getOrBuild(111, () => const Text('A'));
      cache.getOrBuild(111, () => const Text('A'));
      cache.getOrBuild(222, () => const Text('B'));
      cache.getOrBuild(222, () => const Text('B'));

      // 2 misses + 2 hits = 0.5
      expect(cache.hitRate, 0.5);
    });

    test('hitRate is zero when empty', () {
      final cache = WidgetRenderCache();
      expect(cache.hitRate, 0.0);
    });

    test('resetStats clears counters', () {
      final cache = WidgetRenderCache();
      cache.getOrBuild(111, () => const Text('A'));
      cache.getOrBuild(111, () => const Text('A'));
      cache.resetStats();

      expect(cache.hits, 0);
      expect(cache.misses, 0);
      expect(cache.hitRate, 0.0);
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach && flutter test test/cache_test.dart`
Expected: Compilation errors — `hits`, `misses`, `hitRate`, `resetStats` not defined.

- [ ] **Step 3: Rewrite WidgetRenderCache**

Replace the full contents of `lib/src/core/cache/widget_cache.dart` with:

```dart
// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/widgets.dart';

/// LRU cache for rendered widgets, keyed by content hash.
///
/// Uses a [LinkedHashMap] for O(1) insertion-order tracking.
/// Content-addressed keys ensure that shifted blocks (e.g. after an insert
/// at the top) still hit the cache — the content hash is unchanged even if
/// the positional index moves.
class WidgetRenderCache {
  /// Creates a widget cache with specified maximum size.
  WidgetRenderCache({this.maxSize = 100});

  /// Maximum number of cached widgets.
  final int maxSize;

  final LinkedHashMap<int, Widget> _cache = LinkedHashMap<int, Widget>();

  int _hits = 0;
  int _misses = 0;

  /// Number of cached widgets.
  int get size => _cache.length;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Whether the cache has entries.
  bool get isNotEmpty => _cache.isNotEmpty;

  /// Number of cache hits since last reset.
  int get hits => _hits;

  /// Number of cache misses since last reset.
  int get misses => _misses;

  /// Hit rate as a ratio (0.0 to 1.0). Returns 0.0 if no lookups.
  double get hitRate {
    final total = _hits + _misses;
    return total == 0 ? 0.0 : _hits / total;
  }

  /// Resets hit/miss counters.
  void resetStats() {
    _hits = 0;
    _misses = 0;
  }

  /// Gets a cached widget by content hash.
  ///
  /// Returns null if not cached.
  Widget? get(int contentHash) {
    final widget = _cache.remove(contentHash);
    if (widget != null) {
      _cache[contentHash] = widget; // Move to end (most recently used)
      return widget;
    }
    return null;
  }

  /// Gets or builds a widget for the given content hash.
  ///
  /// If a cached widget exists for [contentHash], returns it.
  /// Otherwise, builds a new widget and caches it.
  Widget getOrBuild(int contentHash, Widget Function() builder) {
    final existing = _cache.remove(contentHash);
    if (existing != null) {
      _cache[contentHash] = existing; // Move to end (most recently used)
      _hits++;
      return existing;
    }
    _misses++;
    final widget = builder();
    _put(contentHash, widget);
    return widget;
  }

  void _put(int contentHash, Widget widget) {
    while (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first); // Evict least recently used
    }
    _cache[contentHash] = widget;
  }

  /// Caches a widget for the given content hash.
  void put(int contentHash, Widget widget) => _put(contentHash, widget);

  /// Removes the cached widget for the given content hash.
  void invalidate(int contentHash) {
    _cache.remove(contentHash);
  }

  /// Invalidates all cached widgets.
  void clear() {
    _cache.clear();
  }

  /// Returns true if there is a cached widget for [contentHash].
  bool containsValid(int contentHash) => _cache.containsKey(contentHash);
}
```

- [ ] **Step 4: Run all cache tests**

Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach && flutter test test/cache_test.dart`
Expected: All tests pass (existing + new stats tests).

- [ ] **Step 5: Run full test suite to check for regressions**

Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach && flutter test`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/src/core/cache/widget_cache.dart test/cache_test.dart
git commit -m "perf: rewrite WidgetRenderCache with O(1) LinkedHashMap LRU and hit/miss stats"
```

---

## Task 2: Content-Hash Keys + RepaintBoundary + Opacity Guard in VirtualMarkdownList

**Files:**
- Modify: `lib/src/widgets/virtual_markdown_list.dart`

Three small changes in one file.

- [ ] **Step 1: Change ValueKey to content-hash**

In `lib/src/widgets/virtual_markdown_list.dart`, in `_buildSliverList` (around line 129), change:

```dart
          return _BlockItemWidget(
            key: ValueKey('block_$index'),
```

to:

```dart
          return _BlockItemWidget(
            key: ValueKey(block.contentHash),
```

- [ ] **Step 2: Add RepaintBoundary and Opacity guard in _BlockItemWidget.build**

In `lib/src/widgets/virtual_markdown_list.dart`, replace the `_BlockItemWidget.build` method (lines 166-180) with:

```dart
  @override
  Widget build(BuildContext context) {
    Widget child = cache.getOrBuild(
      block.contentHash,
      () => builder.buildBlock(context, block, resolvedTheme: resolvedTheme),
    );

    if (isFaded && fadedOpacity < 1.0) {
      child = Opacity(
        opacity: fadedOpacity.clamp(0.0, 1.0),
        child: child,
      );
    }

    return RepaintBoundary(child: child);
  }
```

- [ ] **Step 3: Run full test suite**

Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach && flutter test`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/src/widgets/virtual_markdown_list.dart
git commit -m "perf: use content-hash keys, RepaintBoundary, and Opacity guard in VirtualMarkdownList"
```

---

## Task 3: External Cache + Cache Extent on StreamingMarkdownView

**Files:**
- Modify: `lib/src/widgets/streaming_markdown_view.dart`
- Modify: `lib/src/widgets/virtual_markdown_list.dart`

- [ ] **Step 1: Add widgetCache parameter to VirtualMarkdownList**

In `lib/src/widgets/virtual_markdown_list.dart`, add to the constructor parameters (after `cacheExtent`):

```dart
    this.widgetCache,
```

Add the field declaration:

```dart
  /// Optional external widget cache. If provided, the caller owns its lifecycle.
  final WidgetRenderCache? widgetCache;
```

In `_VirtualMarkdownListState.initState()`, change:

```dart
    _cache = WidgetRenderCache();
```

to:

```dart
    _cache = widget.widgetCache ?? WidgetRenderCache();
```

Track whether the cache is internally owned. Add a field:

```dart
  late final bool _ownsCache;
```

In `initState()`, after setting `_cache`:

```dart
    _ownsCache = widget.widgetCache == null;
```

In `didUpdateWidget()`, guard the theme-change cache clear:

```dart
    if (widget.theme != oldWidget.theme) {
      _builder = ContentBuilder(theme: widget.theme, renderOptions: widget.renderOptions);
      if (_ownsCache) _cache.clear();
    }
```

In `dispose()`, guard the clear:

```dart
  @override
  void dispose() {
    if (_ownsCache) _cache.clear();
    super.dispose();
  }
```

- [ ] **Step 2: Add widgetCache and cacheExtent parameters to StreamingMarkdownView**

In `lib/src/widgets/streaming_markdown_view.dart`, add two parameters to both constructors.

In the static constructor (around line 27), add after `this.shrinkWrap = false`:

```dart
    this.widgetCache,
    this.cacheExtent,
```

In the `.fromStream` constructor (around line 41), add the same two parameters after `this.shrinkWrap = false`:

```dart
    this.widgetCache,
    this.cacheExtent,
```

Add field declarations in the widget class:

```dart
  /// Optional external widget cache. If provided, the caller owns its lifecycle.
  final WidgetRenderCache? widgetCache;

  /// Cache extent for off-screen items in virtual scroll mode.
  /// Defaults to 500 pixels.
  final double? cacheExtent;
```

- [ ] **Step 3: Use external cache and guard lifecycle in state**

In `_StreamingMarkdownViewState`, add:

```dart
  late final bool _ownsCache;
```

In `initState()`, change:

```dart
    _cache = WidgetRenderCache();
```

to:

```dart
    _cache = widget.widgetCache ?? WidgetRenderCache();
    _ownsCache = widget.widgetCache == null;
```

In `didUpdateWidget()`, guard the cache clear (around the `_cache.clear()` call):

```dart
      if (_ownsCache) _cache.clear();
```

In `dispose()`, change:

```dart
    _cache.clear();
```

to:

```dart
    if (_ownsCache) _cache.clear();
```

- [ ] **Step 4: Pass widgetCache and cacheExtent through to VirtualMarkdownList**

In `_buildContent()`, update the `VirtualMarkdownList` construction (around line 354):

```dart
      return VirtualMarkdownList(
        blocks: displayBlocks,
        theme: theme,
        renderOptions: widget.renderOptions,
        controller: _scrollController,
        padding: widget.padding,
        cacheExtent: widget.cacheExtent,
        widgetCache: widget.widgetCache,
        fadedIndex: incompleteIndex,
        fadedOpacity: widget.streamingOptions.incompleteBlockOpacity,
      );
```

- [ ] **Step 5: Add Opacity guard in StreamingMarkdownView**

In `_buildContent()` (around line 385), change:

```dart
        if (incompleteIndex != null && index == incompleteIndex) {
          return Opacity(
            opacity: widget.streamingOptions.incompleteBlockOpacity,
            child: built,
          );
        }
```

to:

```dart
        if (incompleteIndex != null && index == incompleteIndex &&
            widget.streamingOptions.incompleteBlockOpacity < 1.0) {
          return Opacity(
            opacity: widget.streamingOptions.incompleteBlockOpacity,
            child: built,
          );
        }
```

- [ ] **Step 6: Increase default cache extent to 500px**

In `lib/src/widgets/virtual_markdown_list.dart`, in the `build` method (around line 110), change:

```dart
        cacheExtent: widget.cacheExtent ?? 250,
```

to:

```dart
        cacheExtent: widget.cacheExtent ?? 500,
```

- [ ] **Step 7: Run full test suite**

Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach && flutter test`
Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/src/widgets/streaming_markdown_view.dart lib/src/widgets/virtual_markdown_list.dart
git commit -m "perf: add external widgetCache param, Opacity guard, increase default cache extent to 500px"
```

---

## Task 4: Performance Test Document Generator

**Files:**
- Modify: `example/lib/data/markdown_samples.dart`

- [ ] **Step 1: Add buildPerformanceDocument method**

In `example/lib/data/markdown_samples.dart`, add this method to the `MarkdownSamples` class, after `buildLongDocument`:

```dart
  /// Builds a mixed-content document targeting a specific character count.
  ///
  /// Generates headings, paragraphs with inline formatting, lists, code blocks,
  /// tables, LaTeX, and horizontal rules for realistic performance testing.
  static String buildPerformanceDocument({int targetChars = 10000}) {
    final buffer = StringBuffer();
    int section = 0;

    while (buffer.length < targetChars) {
      section++;
      final mod = section % 6;

      buffer.writeln('# Section $section: Performance Test');
      buffer.writeln();

      // Paragraph with inline formatting
      buffer.writeln(
        'This is paragraph **$section** with *italic text*, `inline code`, '
        'and a [link](https://example.com/$section). The quick brown fox jumps '
        'over the lazy dog. Lorem ipsum dolor sit amet, consectetur adipiscing '
        'elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      );
      buffer.writeln();

      if (mod == 0) {
        // Table section
        buffer.writeln('| Column A | Column B | Column C | Column D |');
        buffer.writeln('|----------|----------|----------|----------|');
        for (int row = 1; row <= 4; row++) {
          buffer.writeln('| Cell ${section}x$row | Value $row | Data | Result |');
        }
        buffer.writeln();
      } else if (mod == 1) {
        // Code block
        buffer.writeln('```dart');
        buffer.writeln('class Section$section {');
        buffer.writeln('  final int id = $section;');
        buffer.writeln('  final String name;');
        buffer.writeln('');
        buffer.writeln('  Section$section(this.name);');
        buffer.writeln('');
        buffer.writeln('  String describe() {');
        buffer.writeln("    return 'Section \$id: \$name';");
        buffer.writeln('  }');
        buffer.writeln('}');
        buffer.writeln('```');
        buffer.writeln();
      } else if (mod == 2) {
        // Bullet list
        buffer.writeln('- First item with **bold** emphasis');
        buffer.writeln('- Second item with `code` formatting');
        buffer.writeln('- Third item with *italic* styling');
        buffer.writeln('- Fourth item linking to [docs](https://example.com)');
        buffer.writeln('- Fifth item in section $section');
        buffer.writeln();
      } else if (mod == 3) {
        // Numbered list
        buffer.writeln('1. Step one: Initialize the configuration');
        buffer.writeln('2. Step two: Parse the markdown input');
        buffer.writeln('3. Step three: Build the widget tree');
        buffer.writeln('4. Step four: Render to the screen');
        buffer.writeln();
      } else if (mod == 4) {
        // LaTeX block
        buffer.writeln(r'Inline math: $E = mc^2$ and $\alpha + \beta = \gamma$');
        buffer.writeln();
        buffer.writeln(r'$$');
        buffer.writeln(r'\sum_{i=1}^{n} x_i = \frac{n(n+1)}{2}');
        buffer.writeln(r'$$');
        buffer.writeln();
      } else {
        // Blockquote
        buffer.writeln('> "Performance is not just about speed — it\'s about '
            'consistency. A smooth 60fps experience builds user trust."');
        buffer.writeln('>');
        buffer.writeln('> — Section $section');
        buffer.writeln();
      }

      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }
```

- [ ] **Step 2: Verify the generator produces correct sizes**

Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach && dart run -c 'import "example/lib/data/markdown_samples.dart"; void main() { print(MarkdownSamples.buildPerformanceDocument(targetChars: 2000).length); print(MarkdownSamples.buildPerformanceDocument(targetChars: 10000).length); print(MarkdownSamples.buildPerformanceDocument(targetChars: 30000).length); }'`

If that doesn't work due to import resolution, verify manually after integration in the Performance page. The while loop guarantees at least `targetChars` characters.

- [ ] **Step 3: Commit**

```bash
git add example/lib/data/markdown_samples.dart
git commit -m "feat: add buildPerformanceDocument for mixed-content stress testing"
```

---

## Task 5: PerformanceMonitor Class

**Files:**
- Create: `example/lib/widgets/performance_monitor.dart`

- [ ] **Step 1: Create PerformanceMonitor**

Create `example/lib/widgets/performance_monitor.dart`:

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add example/lib/widgets/performance_monitor.dart
git commit -m "feat: add PerformanceMonitor for real-time frame/scroll/cache metrics"
```

---

## Task 6: MetricsPanel Widget

**Files:**
- Create: `example/lib/widgets/metrics_panel.dart`

- [ ] **Step 1: Create MetricsPanel**

Create `example/lib/widgets/metrics_panel.dart`:

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add example/lib/widgets/metrics_panel.dart
git commit -m "feat: add MetricsPanel widget for performance dashboard display"
```

---

## Task 7: Rewrite Performance Page

**Files:**
- Modify: `example/lib/pages/performance_page.dart`

- [ ] **Step 1: Rewrite performance_page.dart**

Replace the full contents of `example/lib/pages/performance_page.dart` with:

```dart
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
  small('2K', 2000),
  medium('10K', 10000),
  large('30K', 30000);

  const _DocSize(this.label, this.targetChars);
  final String label;
  final int targetChars;
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
    );
    _monitor.start();
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
    _cache.resetStats();
    setState(() {
      _document = MarkdownSamples.buildPerformanceDocument(
        targetChars: _docSize.targetChars,
      );
    });
    if (_simulateStreaming) {
      _startStreaming();
    }
  }

  void _startStreaming() {
    _stopStreaming();
    _cache.clear();
    _cache.resetStats();
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
      // Force rebuild with static content
      setState(() {});
    }
  }

  void _updateCacheStats() {
    _monitor.updateCacheStats(_cache);
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
    // Periodically update cache stats
    _updateCacheStats();

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
              // Metrics Panel
              MetricsPanel(
                monitor: _monitor,
                onReset: () {
                  _monitor.reset();
                  _cache.resetStats();
                },
              ),
              const SizedBox(height: 12),
              // Controls
              Expanded(
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
                              title: 'Controls',
                              subtitle: 'Configure rendering and stress-test parameters.',
                              icon: Icons.tune_rounded,
                            ),
                          ),
                          OptionSwitchTile(
                            title: 'Virtual Scrolling',
                            value: _enableVirtualScroll,
                            onChanged: (v) =>
                                setState(() => _enableVirtualScroll = v),
                          ),
                          OptionSliderTile(
                            title: 'Virtual Threshold',
                            value: _virtualThreshold,
                            min: 6,
                            max: 24,
                            divisions: 9,
                            onChanged: (v) =>
                                setState(() => _virtualThreshold = v),
                            trailingLabel:
                                _virtualThreshold.toStringAsFixed(0),
                          ),
                          OptionSwitchTile(
                            title: 'Simulate Streaming',
                            value: _simulateStreaming,
                            onChanged: _onStreamingToggle,
                          ),
                          // Document size chips
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Document Size',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: _DocSize.values.map((size) {
                                    final selected = size == _docSize;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(size.label),
                                        selected: selected,
                                        onSelected: (_) {
                                          setState(() => _docSize = size);
                                          _regenerateDocument();
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Markdown view
                    SizedBox(
                      height: 420,
                      child: SurfaceCard(
                        padding: EdgeInsets.zero,
                        radius: 24,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              _monitor.onScroll(notification);
                              return false;
                            },
                            child: _buildMarkdownView(markdownTheme),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
```

- [ ] **Step 2: Build example app to verify no compilation errors**

Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach/example && flutter build apk --debug 2>&1 | head -30`

If the project targets macOS/web instead:
Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach/example && flutter analyze`

Expected: No errors.

- [ ] **Step 3: Run full test suite**

Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach && flutter test`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add example/lib/pages/performance_page.dart
git commit -m "feat: rewrite Performance page with real-time metrics dashboard and stress-test controls"
```

---

## Task 8: Update Block Count Tracking

**Files:**
- Modify: `example/lib/pages/performance_page.dart`

The `PerformanceMonitor` needs to know total and visible block counts. Since `StreamingMarkdownView` doesn't expose block count directly, we estimate visible blocks from viewport height.

- [ ] **Step 1: Add block count estimation**

In `example/lib/pages/performance_page.dart`, add a method to `_PerformancePageState`:

```dart
  void _estimateBlockCounts() {
    // Parse document to count blocks
    final parser = IncrementalMarkdownParser(enableLatex: true);
    final result = parser.parse(_document);
    final total = result.blocks.length;
    // Rough estimate: 420px viewport / ~80px avg block height
    final visible = (420 / 80).round().clamp(0, total);
    _monitor.updateBlockCounts(total: total, visible: visible);
  }
```

Call `_estimateBlockCounts()` at the end of `initState()` and inside `_regenerateDocument()` (after setting `_document`).

In `initState()`, after `_monitor.start()`:

```dart
    _estimateBlockCounts();
```

In `_regenerateDocument()`, after the `setState`:

```dart
    _estimateBlockCounts();
```

- [ ] **Step 2: Run flutter analyze**

Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach && flutter analyze`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add example/lib/pages/performance_page.dart
git commit -m "feat: add block count estimation to performance dashboard"
```

---

## Task 9: Final Integration Test

- [ ] **Step 1: Run full test suite**

Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach && flutter test`
Expected: All tests pass.

- [ ] **Step 2: Run flutter analyze on entire project**

Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach && flutter analyze`
Expected: No issues.

- [ ] **Step 3: Verify example app compiles**

Run: `cd /Users/wen/Desktop/Personal/Projects/flutter-markdown-widget/.claude/worktrees/festive-banach/example && flutter analyze`
Expected: No issues.

- [ ] **Step 4: Commit any final fixes if needed**

Only if Steps 1-3 revealed issues that need fixing.
