// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';

/// Performance benchmarks for the streaming markdown library.
void main() {
  group('Performance Benchmarks', () {
    late IncrementalMarkdownParser parser;
    final isCi = Platform.environment.containsKey('CI') ||
        Platform.environment.containsKey('GITHUB_ACTIONS');

    setUp(() {
      parser = IncrementalMarkdownParser();
    });

    /// Generates markdown content of approximately the given byte size.
    String _generateMarkdown(int targetBytes) {
      final buffer = StringBuffer();
      int currentSize = 0;
      int sectionNum = 1;

      while (currentSize < targetBytes) {
        // Add a heading
        buffer.writeln('## Section $sectionNum\n');
        
        // Add paragraphs
        for (int i = 0; i < 3; i++) {
          buffer.writeln('This is paragraph $i in section $sectionNum. '
              'It contains some **bold** and *italic* text, '
              'as well as [links](https://example.com) and `inline code`.\n');
        }

        // Add a code block
        buffer.writeln('```dart');
        buffer.writeln('void section$sectionNum() {');
        buffer.writeln('  print("Hello from section $sectionNum");');
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
      final content = _generateMarkdown(1024);
      final maxMs = isCi ? 150 : 50;
      
      final stopwatch = Stopwatch()..start();
      final result = parser.parse(content);
      stopwatch.stop();

      print('1KB Content Benchmark:');
      print('  Content size: ${content.length} bytes');
      print('  Blocks parsed: ${result.blocks.length}');
      print('  Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(maxMs),
          reason: '1KB content should parse in under 50ms');
    });

    test('10KB content benchmark (target: <100ms)', () {
      final content = _generateMarkdown(10 * 1024);
      final maxMs = isCi ? 300 : 100;

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(content);
      stopwatch.stop();

      print('10KB Content Benchmark:');
      print('  Content size: ${content.length} bytes');
      print('  Blocks parsed: ${result.blocks.length}');
      print('  Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(maxMs),
          reason: '10KB content should parse in under 100ms');
    });

    test('incremental update benchmark (target: <16ms)', () {
      final content = _generateMarkdown(10 * 1024);
      final maxMs = isCi ? 60 : 16;
      
      // Initial parse
      parser.parse(content);

      // Simulate incremental update (append one paragraph)
      final updatedContent = '$content\n\nNew paragraph added during streaming.\n';

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(updatedContent);
      stopwatch.stop();

      print('Incremental Update Benchmark:');
      print('  Original size: ${content.length} bytes');
      print('  Updated size: ${updatedContent.length} bytes');
      print('  Modified blocks: ${result.modifiedIndices.length}');
      print('  Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(maxMs),
          reason: 'Incremental update should complete within one frame (16ms)');
    });

    test('cache hit performance', () {
      final content = _generateMarkdown(5 * 1024);
      final maxMs = isCi ? 30 : 5;

      // First parse
      parser.parse(content);

      // Second parse (should hit cache)
      final stopwatch = Stopwatch()..start();
      final result = parser.parse(content);
      stopwatch.stop();

      print('Cache Hit Benchmark:');
      print('  Content size: ${content.length} bytes');
      print('  Has changes: ${result.hasChanges}');
      print('  Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(result.hasChanges, isFalse);
      expect(stopwatch.elapsedMilliseconds, lessThan(maxMs),
          reason: 'Cache hit should be near-instant');
    });

    test('widget cache performance', () {
      final cache = WidgetRenderCache(maxSize: 1000);
      const iterations = 1000;
      final maxUs = isCi ? 200 : 100;

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        cache.getOrBuild(i % 100, i * 1000, () => const SizedBox.shrink());
      }
      stopwatch.stop();

      final avgTime = stopwatch.elapsedMicroseconds / iterations;

      print('Widget Cache Benchmark:');
      print('  Operations: $iterations');
      print('  Total time: ${stopwatch.elapsedMilliseconds}ms');
      print('  Average per operation: ${avgTime.toStringAsFixed(2)}µs');

      expect(avgTime, lessThan(maxUs),
          reason: 'Cache operations should be under 100µs');
    });

    test('dimension estimator performance', () {
      final estimator = BlockDimensionEstimator();
      const iterations = 10000;
      final maxUs = isCi ? 120 : 50;

      final blocks = List.generate(iterations, (i) => ContentBlock(
        type: ContentBlockType.values[i % ContentBlockType.values.length],
        rawContent: 'Content $i\n' * (1 + i % 10),
        contentHash: i,
        startLine: i,
        endLine: i + (i % 10),
        headingLevel: i % 6 + 1,
      ));

      final stopwatch = Stopwatch()..start();
      for (final block in blocks) {
        estimator.estimateHeight(block);
      }
      stopwatch.stop();

      final avgTime = stopwatch.elapsedMicroseconds / iterations;

      print('Dimension Estimator Benchmark:');
      print('  Estimates: $iterations');
      print('  Total time: ${stopwatch.elapsedMilliseconds}ms');
      print('  Average per estimate: ${avgTime.toStringAsFixed(2)}µs');

      expect(avgTime, lessThan(maxUs),
          reason: 'Height estimation should be under 50µs');
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
      final maxMs = isCi ? 150 : 50;

      final tocGenerator = TocGenerator();

      final stopwatch = Stopwatch()..start();
      final toc = tocGenerator.generate(result.blocks);
      stopwatch.stop();

      print('TOC Generation Benchmark:');
      print('  Total blocks: ${result.blocks.length}');
      print('  Heading count: ${tocGenerator.generateFlat(result.blocks).length}');
      print('  Top-level entries: ${toc.length}');
      print('  Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(maxMs),
          reason: 'TOC generation should complete in under 50ms');
    });
  });
}
