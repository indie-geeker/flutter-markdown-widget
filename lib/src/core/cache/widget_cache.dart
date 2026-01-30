// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// LRU cache for rendered widgets.
///
/// Caches built widgets by block index to avoid
/// unnecessary rebuilds during scrolling.
class WidgetRenderCache {
  /// Creates a widget cache with specified maximum size.
  WidgetRenderCache({this.maxSize = 100});

  /// Maximum number of cached widgets.
  final int maxSize;

  final Map<int, _CacheEntry> _cache = {};
  final List<int> _accessOrder = [];

  /// Number of cached widgets.
  int get size => _cache.length;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Whether the cache has entries.
  bool get isNotEmpty => _cache.isNotEmpty;

  /// Gets a cached widget by block index.
  ///
  /// Returns null if not cached.
  Widget? get(int blockIndex) {
    final entry = _cache[blockIndex];
    if (entry != null) {
      _updateAccessOrder(blockIndex);
      return entry.widget;
    }
    return null;
  }

  /// Gets or builds a widget for the given block index.
  ///
  /// If cached and hash matches, returns cached widget.
  /// Otherwise, builds new widget and caches it.
  Widget getOrBuild(
    int blockIndex,
    int contentHash,
    Widget Function() builder,
  ) {
    final entry = _cache[blockIndex];

    if (entry != null && entry.contentHash == contentHash) {
      _updateAccessOrder(blockIndex);
      return entry.widget;
    }

    final widget = builder();
    put(blockIndex, widget, contentHash);
    return widget;
  }

  /// Caches a widget for the given block index.
  void put(int blockIndex, Widget widget, int contentHash) {
    // Evict if necessary
    while (_cache.length >= maxSize) {
      _evictLeastRecentlyUsed();
    }

    _cache[blockIndex] = _CacheEntry(
      widget: widget,
      contentHash: contentHash,
    );
    _updateAccessOrder(blockIndex);
  }

  /// Invalidates cached widget at block index.
  void invalidate(int blockIndex) {
    _cache.remove(blockIndex);
    _accessOrder.remove(blockIndex);
  }

  /// Invalidates all widgets from block index onwards.
  void invalidateFrom(int startIndex) {
    final keysToRemove =
        _cache.keys.where((k) => k >= startIndex).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }

  /// Invalidates all cached widgets.
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Checks if block is cached with matching hash.
  bool containsValid(int blockIndex, int contentHash) {
    final entry = _cache[blockIndex];
    return entry != null && entry.contentHash == contentHash;
  }

  void _updateAccessOrder(int blockIndex) {
    _accessOrder.remove(blockIndex);
    _accessOrder.add(blockIndex);
  }

  void _evictLeastRecentlyUsed() {
    if (_accessOrder.isNotEmpty) {
      final lruIndex = _accessOrder.removeAt(0);
      _cache.remove(lruIndex);
    }
  }
}

/// Cache entry for a single widget.
class _CacheEntry {
  const _CacheEntry({
    required this.widget,
    required this.contentHash,
  });

  final Widget widget;
  final int contentHash;
}
