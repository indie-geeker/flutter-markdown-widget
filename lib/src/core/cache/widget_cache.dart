// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// LRU cache for rendered widgets, keyed by content hash.
///
/// Uses content-addressed keys so that shifted blocks (e.g. after an insert
/// at the top) still hit the cache — the content hash is unchanged even if
/// the positional index moves.
class WidgetRenderCache {
  /// Creates a widget cache with specified maximum size.
  WidgetRenderCache({this.maxSize = 100});

  /// Maximum number of cached widgets.
  final int maxSize;

  final Map<int, Widget> _cache = {};
  final List<int> _accessOrder = [];

  /// Number of cached widgets.
  int get size => _cache.length;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Whether the cache has entries.
  bool get isNotEmpty => _cache.isNotEmpty;

  /// Gets a cached widget by content hash.
  ///
  /// Returns null if not cached.
  Widget? get(int contentHash) {
    if (_cache.containsKey(contentHash)) {
      _updateAccessOrder(contentHash);
      return _cache[contentHash];
    }
    return null;
  }

  /// Gets or builds a widget for the given content hash.
  ///
  /// If a cached widget exists for [contentHash], returns it.
  /// Otherwise, builds a new widget and caches it.
  Widget getOrBuild(int contentHash, Widget Function() builder) {
    if (_cache.containsKey(contentHash)) {
      _updateAccessOrder(contentHash);
      return _cache[contentHash]!;
    }
    final widget = builder();
    _put(contentHash, widget);
    return widget;
  }

  void _put(int contentHash, Widget widget) {
    while (_cache.length >= maxSize) {
      _evictLeastRecentlyUsed();
    }
    _cache[contentHash] = widget;
    _updateAccessOrder(contentHash);
  }

  /// Caches a widget for the given content hash.
  void put(int contentHash, Widget widget) => _put(contentHash, widget);

  /// Removes the cached widget for the given content hash.
  void invalidate(int contentHash) {
    _cache.remove(contentHash);
    _accessOrder.remove(contentHash);
  }

  /// Invalidates all cached widgets.
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Returns true if there is a cached widget for [contentHash].
  bool containsValid(int contentHash) => _cache.containsKey(contentHash);

  void _updateAccessOrder(int contentHash) {
    _accessOrder.remove(contentHash);
    _accessOrder.add(contentHash);
  }

  void _evictLeastRecentlyUsed() {
    if (_accessOrder.isNotEmpty) {
      final lru = _accessOrder.removeAt(0);
      _cache.remove(lru);
    }
  }
}
