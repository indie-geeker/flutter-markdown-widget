# Performance Optimization & Metrics Dashboard Design

**Date:** 2026-04-16
**Approach:** B — Fix Known Bottlenecks + Dashboard in Parallel

## Summary

Targeted performance fixes to the library's rendering pipeline for smooth scrolling of 10,000+ character documents (both streaming and static), plus a full real-time metrics dashboard in the example app's Performance page for ongoing evaluation.

---

## Part 1: Library Performance Fixes

Six targeted changes, ordered by impact.

### 1.1 O(1) LRU Cache

**File:** `lib/src/core/cache/widget_cache.dart`

**Problem:** `_updateAccessOrder` calls `_accessOrder.remove(contentHash)` which is O(n) on a `List`. This runs on every cache hit — during rapid scrolling of 100+ blocks, this compounds significantly.

**Fix:** Replace the dual `Map<int, Widget> _cache` + `List<int> _accessOrder` structure with a single `LinkedHashMap<int, Widget>`. Dart's `LinkedHashMap` maintains insertion order and supports O(1) removal/reinsertion, giving LRU semantics natively.

**Implementation:**
- On cache hit: remove key, re-insert (moves to end = most recently used)
- On eviction: remove `entries.first` (least recently used)
- `getOrBuild()`, `get()`, `put()`, `invalidate()`, `clear()` all remain with same signatures

### 1.2 Remove Opacity Compositing Layer

**Files:** `lib/src/widgets/virtual_markdown_list.dart:172`, `lib/src/widgets/streaming_markdown_view.dart:386`

**Problem:** The `Opacity` widget wrapping incomplete/faded blocks forces Flutter to allocate a separate compositing layer every frame. This is expensive during scroll.

**Fix:** Both `VirtualMarkdownList` and `StreamingMarkdownView` already guard with `if (isFaded)` / `if (incompleteIndex != null && index == incompleteIndex)`, so `Opacity` only wraps the single incomplete block. The actual optimization: when `fadedOpacity == 1.0`, skip the `Opacity` wrapper entirely (it's a no-op that still allocates a layer). Add the guard `if (fadedOpacity < 1.0)` before wrapping. This is a minor fix — the Opacity is already scoped correctly, just needs the 1.0 short-circuit.

### 1.3 Content-Hash-Based Keys

**File:** `lib/src/widgets/virtual_markdown_list.dart:130`

**Problem:** `ValueKey('block_$index')` means when blocks shift during streaming (new block inserted at top/middle), every subsequent block's key changes, forcing Flutter to rebuild all of them.

**Fix:** Change to `ValueKey(block.contentHash)`. Content hashes are stable across position changes — Flutter can match and reuse existing elements even when the list shifts.

**Risk:** Two blocks with identical content would share a hash. The existing `contentHash` uses `Object.hash(rawContent, type, ...)` which includes enough entropy. If a collision occurs, Flutter would reuse the wrong element — but identical content renders identically anyway, so the visual result is correct. No action needed.

### 1.4 RepaintBoundary on Block Items

**File:** `lib/src/widgets/virtual_markdown_list.dart:166`

**Problem:** Without `RepaintBoundary`, a single dirty block during scroll triggers repaints cascading across all visible blocks in the same layer.

**Fix:** Wrap the return value of `_BlockItemWidget.build()` in `RepaintBoundary(child: child)`. This isolates each block's paint, so only the actually-dirty block repaints.

**Trade-off:** Each `RepaintBoundary` allocates its own `Layer`. For typical visible counts (5-15 blocks), this is negligible. For very small blocks (single-line paragraphs), the overhead could theoretically exceed the savings — but in practice, markdown documents have enough variety that the isolation wins.

### 1.5 Increase Default Cache Extent

**File:** `lib/src/widgets/virtual_markdown_list.dart:110`

**Problem:** `cacheExtent: 250` pre-builds items within 250px of the viewport edge. During fast fling-scrolling, the scroll can outpace the build pipeline, causing visible pop-in (blank space before items render).

**Fix:**
- Increase default from 250px to 500px
- Expose `cacheExtent` as an optional parameter on `StreamingMarkdownView` so users can tune it for their use case

**Impact:** ~2-3 extra blocks pre-built off-screen vs ~1 at 250px. Memory impact is minimal because `WidgetRenderCache` already caps at 100 entries.

### 1.6 Larger Test Document

**File:** `example/lib/data/markdown_samples.dart`

**Problem:** `buildLongDocument(sections: 24)` generates ~3,500 characters — well under the 10,000+ char target for stress testing.

**Fix:** Add `buildPerformanceDocument({int targetChars = 10000})` that generates a document with mixed content types:
- Headings (h1-h3)
- Paragraphs with inline formatting (bold, italic, code, links)
- Bullet and numbered lists
- Code blocks (multi-line, with language tags)
- Tables (3-4 columns)
- LaTeX blocks (inline and display)
- Horizontal rules

The method builds sections until `targetChars` is reached, ensuring a realistic mix rather than repetitive structure. Three presets: small (~2,000), medium (~10,000), large (~30,000).

---

## Part 2: Cache Stats Instrumentation

Minimal library addition to support the dashboard.

### 2.1 WidgetRenderCache Additions

**File:** `lib/src/core/cache/widget_cache.dart`

New fields:
```dart
int _hits = 0;
int _misses = 0;

int get hits => _hits;
int get misses => _misses;
double get hitRate => (_hits + _misses) == 0 ? 0.0 : _hits / (_hits + _misses);

void resetStats() {
  _hits = 0;
  _misses = 0;
}
```

In `getOrBuild()`:
- Cache hit branch: `_hits++`
- Cache miss branch: `_misses++`

### 2.2 External Cache Parameter

**File:** `lib/src/widgets/streaming_markdown_view.dart`

Add optional parameter:
```dart
final WidgetRenderCache? widgetCache;
```

In `initState()`: `_cache = widget.widgetCache ?? WidgetRenderCache();`
In `didUpdateWidget()`: only call `_cache.clear()` if the cache was internally created (i.e., `widget.widgetCache == null`). If an external cache is injected, the caller owns its lifecycle.
In `dispose()`: same rule — only clear internally-created caches.

Same for `VirtualMarkdownList` — accept optional `WidgetRenderCache? widgetCache`.

This lets the example app's Performance page inject its own cache instance and read stats from it.

---

## Part 3: Performance Metrics Dashboard

All code in the example app (`example/lib/`). No library changes beyond Part 2.

### 3.1 PerformanceMonitor Class

**File:** `example/lib/widgets/performance_monitor.dart` (new)

A `ChangeNotifier` that collects metrics:

**Frame metrics** (via `WidgetsBinding.addTimingsCallback`):
- `fps`: rolling average over last 60 frames
- `buildTimeMs`: rolling average build duration
- `rasterTimeMs`: rolling average raster duration
- `jankCount`: frames exceeding 16.67ms total duration
- `totalFrames`: frames since last reset

**Scroll metrics** (fed externally via `onScroll(ScrollNotification)`):
- `scrollVelocity`: pixels/second, smoothed

**Cache metrics** (fed externally via `updateCacheStats(WidgetRenderCache)`):
- `cacheHitRate`: percentage
- `cacheSize`: current entries

**Content metrics** (set externally):
- `totalBlocks`: total content blocks
- `visibleBlocks`: estimated visible count

**Lifecycle:**
- `start()`: registers frame timing callback, starts 500ms refresh timer
- `stop()`: unregisters callback, cancels timer
- `reset()`: zeroes all counters
- Notifies listeners every 500ms (not per-frame) to avoid dashboard jank

### 3.2 MetricsPanel Widget

**File:** `example/lib/widgets/metrics_panel.dart` (new)

A `ListenableBuilder` consuming `PerformanceMonitor`, laid out as:

```
+--------------------------------------------------+
| FPS: 60      Jank: 0      Scroll: 0 px/s         |
| Build: 2.1ms   Raster: 1.3ms                     |
| Cache: 94%   Visible: 8   Total: 142   ~1.2 MB   |
|                                    [Reset]        |
+--------------------------------------------------+
```

- FPS number uses color coding: green (>=55), yellow (30-54), red (<30)
- Compact layout (~140px height) to maximize space for the markdown view
- All text uses monospace font for stable layout during updates
- Styled consistently with the existing example app's `SurfaceCard` / `SectionHeader` widgets

### 3.3 Revised Performance Page

**File:** `example/lib/pages/performance_page.dart` (rewrite)

Layout:
1. **Metrics Panel** (top, always visible)
2. **Controls Card** — virtual scrolling toggle, threshold slider, document size selector (small/medium/large), streaming simulation toggle
3. **Markdown View** (remaining height) — `StreamingMarkdownView` or `StreamingMarkdownView.fromStream` depending on streaming toggle, wrapped in `NotificationListener<ScrollNotification>` to feed scroll velocity to the monitor

**Document size selector:** Three chips — "2K chars", "10K chars", "30K chars" — regenerate document on change.

**Streaming simulation:** When enabled, replays the selected document through a `Stream<String>` that emits chunks at ~50 chars per 16ms (simulating typical LLM token output). When disabled, renders as static content.

---

## Part 4: Scope

### In scope
- 6 library performance fixes (Sections 1.1-1.6)
- Cache stats counters + `widgetCache` parameter (Section 2)
- `PerformanceMonitor` class, `MetricsPanel` widget, Performance page overhaul (Section 3)
- Unit tests for modified `WidgetRenderCache` (LRU behavior, stats counters)
- Widget tests for `VirtualMarkdownList` key stability

### Out of scope
- Parser pipeline changes (already well-optimized)
- Custom `RenderObject` work
- Changes to `MarkdownWidget` or `MarkdownContent`
- New public API beyond `widgetCache` parameter and cache stat fields
- Performance monitoring in the library itself (dashboard is example-app only)

### Risks
- **Content-hash key collisions (1.3):** Two blocks with identical raw content and type share a hash. Since identical content renders identically, the visual result is correct even on collision. No mitigation needed.
- **Increased cache extent memory (1.5):** 500px pre-builds ~2-3 extra blocks. `WidgetRenderCache` caps at 100 entries regardless. Negligible impact.
- **FrameTiming callback overhead (3.1):** The callback fires per-frame but only stores a number in a circular buffer. Dashboard reads at 500ms intervals. No measurable overhead.
