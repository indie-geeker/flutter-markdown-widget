// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';

/// Performance benchmarks for the streaming markdown library.
void main() {
  const benchmarkProfile = String.fromEnvironment(
    'BENCHMARK_PROFILE',
    defaultValue: 'local',
  );
  final thresholds = _BenchmarkThresholds.forProfile(benchmarkProfile);

  group('Performance Benchmarks', () {
    late IncrementalMarkdownParser parser;

    setUpAll(() {
      debugPrint('Benchmark profile: $benchmarkProfile');
      debugPrint(
        'Thresholds(ms/us): '
        '1KB<${thresholds.parse1KbMs}, '
        '10KB<${thresholds.parse10KbMs}, '
        'incremental<${thresholds.incrementalMs}, '
        'cache<${thresholds.cacheHitMs}, '
        'widgetCache<${thresholds.widgetCacheUs.toStringAsFixed(0)}us, '
        'estimator<${thresholds.dimensionEstimatorUs.toStringAsFixed(0)}us, '
        'toc<${thresholds.tocGenerationMs}',
      );
    });

    setUp(() {
      parser = IncrementalMarkdownParser();
    });

    /// Generates markdown content of approximately the given byte size.
    String generateMarkdown(int targetBytes) {
      final buffer = StringBuffer();
      int currentSize = 0;
      int sectionNum = 1;

      while (currentSize < targetBytes) {
        // Add a heading
        buffer.writeln('## Section $sectionNum\n');

        // Add paragraphs
        for (int i = 0; i < 3; i++) {
          buffer.writeln(
            'This is paragraph $i in section $sectionNum. '
            'It contains some **bold** and *italic* text, '
            'as well as [links](https://example.com) and `inline code`.\n',
          );
        }

        // Add a code block
        buffer.writeln('```dart');
        buffer.writeln('void section$sectionNum() {');
        buffer.writeln('  debugPrint("Hello from section $sectionNum");');
        buffer.writeln('}');
        buffer.writeln('```\n');

        // Add a list
        buffer.writeln('- Item 1');
        buffer.writeln('- Item 2');
        buffer.writeln('- Item 3\n');

        currentSize = buffer.length;
        sectionNum++;
      }

      return buffer.toString();
    }

    test('1KB content benchmark (target: <50ms)', () {
      final content = generateMarkdown(1024);
      final maxMs = thresholds.parse1KbMs;

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(content);
      stopwatch.stop();

      debugPrint('1KB Content Benchmark:');
      debugPrint('  Content size: ${content.length} bytes');
      debugPrint('  Blocks parsed: ${result.blocks.length}');
      debugPrint('  Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(maxMs),
        reason: '1KB content should parse in under 50ms',
      );
    });

    test('10KB content benchmark (target: <100ms)', () {
      final content = generateMarkdown(10 * 1024);
      final maxMs = thresholds.parse10KbMs;

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(content);
      stopwatch.stop();

      debugPrint('10KB Content Benchmark:');
      debugPrint('  Content size: ${content.length} bytes');
      debugPrint('  Blocks parsed: ${result.blocks.length}');
      debugPrint('  Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(maxMs),
        reason: '10KB content should parse in under 100ms',
      );
    });

    test('incremental update benchmark (target: <16ms)', () {
      final content = generateMarkdown(10 * 1024);
      final maxMs = thresholds.incrementalMs;

      // Initial parse
      parser.parse(content);

      // Simulate incremental update (append one paragraph)
      final updatedContent =
          '$content\n\nNew paragraph added during streaming.\n';

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(updatedContent);
      stopwatch.stop();

      debugPrint('Incremental Update Benchmark:');
      debugPrint('  Original size: ${content.length} bytes');
      debugPrint('  Updated size: ${updatedContent.length} bytes');
      debugPrint('  Modified blocks: ${result.modifiedIndices.length}');
      debugPrint('  Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(maxMs),
        reason: 'Incremental update should complete within one frame (16ms)',
      );
    });

    test('cache hit performance', () {
      final content = generateMarkdown(5 * 1024);
      final maxMs = thresholds.cacheHitMs;

      // First parse
      parser.parse(content);

      // Second parse (should hit cache)
      final stopwatch = Stopwatch()..start();
      final result = parser.parse(content);
      stopwatch.stop();

      debugPrint('Cache Hit Benchmark:');
      debugPrint('  Content size: ${content.length} bytes');
      debugPrint('  Has changes: ${result.hasChanges}');
      debugPrint('  Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(result.hasChanges, isFalse);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(maxMs),
        reason: 'Cache hit should be near-instant',
      );
    });

    test('widget cache performance', () {
      final cache = WidgetRenderCache(maxSize: 1000);
      const iterations = 1000;
      final maxUs = thresholds.widgetCacheUs;

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        cache.getOrBuild(i % 100, i * 1000, () => const SizedBox.shrink());
      }
      stopwatch.stop();

      final avgTime = stopwatch.elapsedMicroseconds / iterations;

      debugPrint('Widget Cache Benchmark:');
      debugPrint('  Operations: $iterations');
      debugPrint('  Total time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('  Average per operation: ${avgTime.toStringAsFixed(2)}µs');

      expect(
        avgTime,
        lessThan(maxUs),
        reason: 'Cache operations should be under 100µs',
      );
    });

    test('dimension estimator performance', () {
      final estimator = BlockDimensionEstimator();
      const iterations = 10000;
      final maxUs = thresholds.dimensionEstimatorUs;

      final blocks = List.generate(
        iterations,
        (i) => ContentBlock(
          type: ContentBlockType.values[i % ContentBlockType.values.length],
          rawContent: 'Content $i\n' * (1 + i % 10),
          contentHash: i,
          startLine: i,
          endLine: i + (i % 10),
          headingLevel: i % 6 + 1,
        ),
      );

      final stopwatch = Stopwatch()..start();
      for (final block in blocks) {
        estimator.estimateHeight(block);
      }
      stopwatch.stop();

      final avgTime = stopwatch.elapsedMicroseconds / iterations;

      debugPrint('Dimension Estimator Benchmark:');
      debugPrint('  Estimates: $iterations');
      debugPrint('  Total time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('  Average per estimate: ${avgTime.toStringAsFixed(2)}µs');

      expect(
        avgTime,
        lessThan(maxUs),
        reason: 'Height estimation should be under 50µs',
      );
    });

    test('TOC generation performance', () {
      // Generate a document with many headings
      final buffer = StringBuffer();
      for (int chapter = 1; chapter <= 20; chapter++) {
        buffer.writeln('# Chapter $chapter');
        buffer.writeln();
        for (int section = 1; section <= 5; section++) {
          buffer.writeln('## Section $chapter.$section');
          buffer.writeln();
          buffer.writeln('Content paragraph.');
          buffer.writeln();
          for (int sub = 1; sub <= 3; sub++) {
            buffer.writeln('### Subsection $chapter.$section.$sub');
            buffer.writeln();
            buffer.writeln('More content.');
            buffer.writeln();
          }
        }
      }

      final content = buffer.toString();
      final result = parser.parse(content);
      final maxMs = thresholds.tocGenerationMs;

      final tocGenerator = TocGenerator();

      final stopwatch = Stopwatch()..start();
      final toc = tocGenerator.generate(result.blocks);
      stopwatch.stop();

      debugPrint('TOC Generation Benchmark:');
      debugPrint('  Total blocks: ${result.blocks.length}');
      debugPrint(
        '  Heading count: ${tocGenerator.generateFlat(result.blocks).length}',
      );
      debugPrint('  Top-level entries: ${toc.length}');
      debugPrint('  Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(maxMs),
        reason: 'TOC generation should complete in under 50ms',
      );
    });
  });
}

class _BenchmarkThresholds {
  const _BenchmarkThresholds({
    required this.parse1KbMs,
    required this.parse10KbMs,
    required this.incrementalMs,
    required this.cacheHitMs,
    required this.widgetCacheUs,
    required this.dimensionEstimatorUs,
    required this.tocGenerationMs,
  });

  final int parse1KbMs;
  final int parse10KbMs;
  final int incrementalMs;
  final int cacheHitMs;
  final double widgetCacheUs;
  final double dimensionEstimatorUs;
  final int tocGenerationMs;

  static const _BenchmarkThresholds _local = _BenchmarkThresholds(
    parse1KbMs: 50,
    parse10KbMs: 100,
    incrementalMs: 16,
    cacheHitMs: 5,
    widgetCacheUs: 100,
    dimensionEstimatorUs: 50,
    tocGenerationMs: 50,
  );

  static const _BenchmarkThresholds _ci = _BenchmarkThresholds(
    parse1KbMs: 120,
    parse10KbMs: 220,
    incrementalMs: 40,
    cacheHitMs: 20,
    widgetCacheUs: 160,
    dimensionEstimatorUs: 90,
    tocGenerationMs: 120,
  );

  static _BenchmarkThresholds forProfile(String profile) {
    switch (profile) {
      case 'local':
        return _local;
      case 'ci':
      case 'strict':
        return _ci;
      default:
        throw ArgumentError.value(
          profile,
          'profile',
          'Unsupported BENCHMARK_PROFILE. Use local, ci, or strict.',
        );
    }
  }
}
