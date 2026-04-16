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
  /// Returns null if not cached. Does not update [hits]/[misses] counters;
  /// use [getOrBuild] for stat-tracked lookups.
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
