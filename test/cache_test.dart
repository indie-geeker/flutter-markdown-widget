// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WidgetRenderCache', () {
    late WidgetRenderCache cache;

    setUp(() {
      cache = WidgetRenderCache();
    });

    tearDown(() {
      cache.clear();
    });

    test('stores and retrieves widget', () {
      const widget = Text('Hello');
      final result = cache.getOrBuild(0, 12345, () => widget);

      expect(result, equals(widget));
      expect(cache.size, 1);
    });

    test('returns cached widget on second call', () {
      int buildCount = 0;
      Widget builder() {
        buildCount++;
        return const Text('Hello');
      }

      cache.getOrBuild(0, 12345, builder);
      cache.getOrBuild(0, 12345, builder);

      expect(buildCount, 1);
    });

    test('rebuilds when hash changes', () {
      int buildCount = 0;
      Widget builder() {
        buildCount++;
        return const Text('Hello');
      }

      cache.getOrBuild(0, 12345, builder);
      cache.getOrBuild(0, 54321, builder);

      expect(buildCount, 2);
    });

    test('invalidates specific index', () {
      cache.getOrBuild(0, 111, () => const Text('A'));
      cache.getOrBuild(1, 222, () => const Text('B'));
      cache.getOrBuild(2, 333, () => const Text('C'));

      cache.invalidate(1);

      expect(cache.size, 2);
    });

    test('invalidates from index', () {
      cache.getOrBuild(0, 111, () => const Text('A'));
      cache.getOrBuild(1, 222, () => const Text('B'));
      cache.getOrBuild(2, 333, () => const Text('C'));

      cache.invalidateFrom(1);

      expect(cache.size, 1);
    });

    test('clear removes all', () {
      cache.getOrBuild(0, 111, () => const Text('A'));
      cache.getOrBuild(1, 222, () => const Text('B'));

      cache.clear();

      expect(cache.size, 0);
    });

    test('respects max size', () {
      final smallCache = WidgetRenderCache(maxSize: 3);

      smallCache.getOrBuild(0, 111, () => const Text('A'));
      smallCache.getOrBuild(1, 222, () => const Text('B'));
      smallCache.getOrBuild(2, 333, () => const Text('C'));
      smallCache.getOrBuild(3, 444, () => const Text('D'));

      expect(smallCache.size, 3);
    });
  });

  group('BlockDimensionEstimator', () {
    late BlockDimensionEstimator estimator;

    setUp(() {
      estimator = BlockDimensionEstimator();
    });

    test('estimates paragraph height', () {
      final block = ContentBlock(
        type: ContentBlockType.paragraph,
        rawContent: 'Short text',
        contentHash: 1,
        startLine: 0,
        endLine: 0,
      );

      final height = estimator.estimateHeight(block);
      expect(height, greaterThan(0));
    });

    test('estimates heading height by level', () {
      final h1 = ContentBlock(
        type: ContentBlockType.heading,
        rawContent: '# Title',
        contentHash: 1,
        startLine: 0,
        endLine: 0,
        headingLevel: 1,
      );

      final h3 = ContentBlock(
        type: ContentBlockType.heading,
        rawContent: '### Subtitle',
        contentHash: 2,
        startLine: 1,
        endLine: 1,
        headingLevel: 3,
      );

      final h1Height = estimator.estimateHeight(h1);
      final h3Height = estimator.estimateHeight(h3);

      expect(h1Height, greaterThan(h3Height));
    });

    test('estimates code block height based on lines', () {
      final shortCode = ContentBlock(
        type: ContentBlockType.codeBlock,
        rawContent: '```\nline1\n```',
        contentHash: 1,
        startLine: 0,
        endLine: 2,
      );

      final longCode = ContentBlock(
        type: ContentBlockType.codeBlock,
        rawContent: '```\n${List.generate(20, (i) => 'line$i').join('\n')}\n```',
        contentHash: 2,
        startLine: 0,
        endLine: 21,
      );

      final shortHeight = estimator.estimateHeight(shortCode);
      final longHeight = estimator.estimateHeight(longCode);

      expect(longHeight, greaterThan(shortHeight));
    });

    test('records and uses actual height', () {
      estimator.recordActualHeight(123, 150.0);

      final recorded = estimator.getActualHeight(123);
      expect(recorded, 150.0);
    });

    test('returns null for unrecorded hash', () {
      final height = estimator.getActualHeight(999);
      expect(height, isNull);
    });
  });

  group('TextChunkBuffer', () {
    late TextChunkBuffer buffer;

    setUp(() {
      buffer = TextChunkBuffer();
    });

    tearDown(() {
      buffer.dispose();
    });

    test('appends text chunks', () {
      buffer.append('Hello');
      buffer.append(' World');

      expect(buffer.content, 'Hello World');
    });

    test('extracts complete lines', () {
      buffer.append('Line 1\nLine 2\nPartial');

      final lines = buffer.extractCompleteLines();

      expect(lines, ['Line 1', 'Line 2']);
      expect(buffer.hasIncomplete, isTrue);
    });

    test('isEmpty returns true for empty buffer', () {
      expect(buffer.isEmpty, isTrue);

      buffer.append('text');
      expect(buffer.isEmpty, isFalse);
    });

    test('clear removes all content', () {
      buffer.append('Some text');
      buffer.clear();

      expect(buffer.isEmpty, isTrue);
      expect(buffer.content, '');
    });

    test('length returns correct value', () {
      buffer.append('Hello');
      expect(buffer.length, 5);

      buffer.append(' World');
      expect(buffer.length, 11);
    });
  });
}
