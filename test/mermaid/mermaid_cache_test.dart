// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_artifact.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_cache.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_theme.dart';
import 'package:flutter_test/flutter_test.dart';

MermaidArtifact _artifact(String svg) => MermaidArtifact(svg: svg);

void main() {
  group('MermaidCache.buildKey', () {
    test('combines contentHash, theme, and rendererVersion', () {
      expect(
        MermaidCache.buildKey(
          contentHash: 12345,
          theme: MermaidTheme.dark,
          rendererVersion: 'flutter-js-1.0+mermaid-10',
        ),
        '12345:dark:flutter-js-1.0+mermaid-10',
      );
    });

    test('different themes produce different keys', () {
      final k1 = MermaidCache.buildKey(
        contentHash: 1,
        theme: MermaidTheme.light,
        rendererVersion: 'v1',
      );
      final k2 = MermaidCache.buildKey(
        contentHash: 1,
        theme: MermaidTheme.dark,
        rendererVersion: 'v1',
      );
      expect(k1, isNot(k2));
    });
  });

  group('MermaidCache LRU', () {
    test('put/get returns stored artifact', () {
      final cache = MermaidCache(capacity: 4);
      final a = _artifact('A');
      cache.put('k1', a);
      expect(cache.get('k1'), same(a));
    });

    test('returns null on miss', () {
      final cache = MermaidCache(capacity: 4);
      expect(cache.get('missing'), isNull);
    });

    test('evicts least-recently-used when over capacity', () {
      final cache = MermaidCache(capacity: 2);
      cache.put('k1', _artifact('A'));
      cache.put('k2', _artifact('B'));
      cache.put('k3', _artifact('C')); // should evict k1
      expect(cache.get('k1'), isNull);
      expect(cache.get('k2'), isNotNull);
      expect(cache.get('k3'), isNotNull);
    });

    test('get refreshes recency', () {
      final cache = MermaidCache(capacity: 2);
      cache.put('k1', _artifact('A'));
      cache.put('k2', _artifact('B'));
      cache.get('k1'); // k1 is now most recent
      cache.put('k3', _artifact('C')); // should evict k2, not k1
      expect(cache.get('k1'), isNotNull);
      expect(cache.get('k2'), isNull);
      expect(cache.get('k3'), isNotNull);
    });

    test('capacity == 0 always misses', () {
      final cache = MermaidCache(capacity: 0);
      cache.put('k1', _artifact('A'));
      expect(cache.get('k1'), isNull);
    });

    test('invalidate(prefix) removes matching keys', () {
      final cache = MermaidCache(capacity: 8);
      cache.put('h1:dark:v1', _artifact('A'));
      cache.put('h1:light:v1', _artifact('B'));
      cache.put('h2:dark:v1', _artifact('C'));
      cache.invalidate('h1:');
      expect(cache.get('h1:dark:v1'), isNull);
      expect(cache.get('h1:light:v1'), isNull);
      expect(cache.get('h2:dark:v1'), isNotNull);
    });

    test('clear empties the cache', () {
      final cache = MermaidCache(capacity: 4);
      cache.put('k1', _artifact('A'));
      cache.put('k2', _artifact('B'));
      cache.clear();
      expect(cache.get('k1'), isNull);
      expect(cache.get('k2'), isNull);
      expect(cache.length, 0);
    });

    test('length reflects entries', () {
      final cache = MermaidCache(capacity: 4);
      expect(cache.length, 0);
      cache.put('k1', _artifact('A'));
      cache.put('k2', _artifact('B'));
      expect(cache.length, 2);
    });
  });
}
