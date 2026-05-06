// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'mermaid_artifact.dart';
import 'mermaid_theme.dart';

/// LRU cache for [MermaidArtifact] keyed by content hash, theme, and renderer.
class MermaidCache {
  MermaidCache({this.capacity = 32});

  /// Maximum entries retained. `0` disables caching entirely.
  final int capacity;

  final LinkedHashMap<String, MermaidArtifact> _entries =
      LinkedHashMap<String, MermaidArtifact>();

  /// Builds the canonical cache key.
  static String buildKey({
    required int contentHash,
    required MermaidTheme theme,
    required String rendererVersion,
  }) => '$contentHash:${theme.name}:$rendererVersion';

  /// Returns the artifact at [key], refreshing its LRU position. Null on miss.
  MermaidArtifact? get(String key) {
    final entry = _entries.remove(key);
    if (entry == null) return null;
    _entries[key] = entry;
    return entry;
  }

  /// Stores [artifact] under [key], evicting LRU entries over [capacity].
  void put(String key, MermaidArtifact artifact) {
    if (capacity == 0) return;
    _entries.remove(key);
    _entries[key] = artifact;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Removes all entries whose key starts with [prefix].
  void invalidate(String prefix) {
    _entries.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Removes every entry.
  void clear() => _entries.clear();

  /// Current entry count.
  int get length => _entries.length;
}
