// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TocGenerator', () {
    late TocGenerator generator;

    setUp(() {
      generator = TocGenerator();
    });

    List<ContentBlock> createBlocks(List<(ContentBlockType, int?, String)> definitions) {
      return definitions.asMap().entries.map((entry) {
        final (type, level, content) = entry.value;
        return ContentBlock(
          type: type,
          rawContent: content,
          contentHash: content.hashCode,
          startLine: entry.key,
          endLine: entry.key,
          headingLevel: level,
        );
      }).toList();
    }

    test('generates empty TOC for empty blocks', () {
      final toc = generator.generate([]);
      expect(toc, isEmpty);
    });

    test('generates empty TOC for blocks without headings', () {
      final blocks = createBlocks([
        (ContentBlockType.paragraph, null, 'Some text'),
        (ContentBlockType.codeBlock, null, '```code```'),
      ]);

      final toc = generator.generate(blocks);
      expect(toc, isEmpty);
    });

    test('generates TOC entries for headings', () {
      final blocks = createBlocks([
        (ContentBlockType.heading, 1, '# Title'),
        (ContentBlockType.paragraph, null, 'Content'),
        (ContentBlockType.heading, 2, '## Subtitle'),
      ]);

      final toc = generator.generate(blocks);

      expect(toc, hasLength(1)); // hierarchical: only top-level
      expect(toc[0].title, 'Title');
      expect(toc[0].level, 1);
      expect(toc[0].children, hasLength(1));
      expect(toc[0].children[0].title, 'Subtitle');
    });

    test('generateFlat returns flat list', () {
      final blocks = createBlocks([
        (ContentBlockType.heading, 1, '# Title'),
        (ContentBlockType.heading, 2, '## Subtitle'),
        (ContentBlockType.heading, 3, '### Sub-subtitle'),
      ]);

      final toc = generator.generateFlat(blocks);

      expect(toc, hasLength(3));
      expect(toc[0].level, 1);
      expect(toc[1].level, 2);
      expect(toc[2].level, 3);
    });

    test('respects minLevel config', () {
      final customGenerator = TocGenerator(
        config: const TocConfig(minLevel: 2),
      );

      final blocks = createBlocks([
        (ContentBlockType.heading, 1, '# Title'),
        (ContentBlockType.heading, 2, '## Subtitle'),
        (ContentBlockType.heading, 3, '### Sub-subtitle'),
      ]);

      final toc = customGenerator.generateFlat(blocks);

      expect(toc, hasLength(2));
      expect(toc.every((e) => e.level >= 2), isTrue);
    });

    test('respects maxLevel config', () {
      final customGenerator = TocGenerator(
        config: const TocConfig(maxLevel: 2),
      );

      final blocks = createBlocks([
        (ContentBlockType.heading, 1, '# Title'),
        (ContentBlockType.heading, 2, '## Subtitle'),
        (ContentBlockType.heading, 3, '### Sub-subtitle'),
      ]);

      final toc = customGenerator.generateFlat(blocks);

      expect(toc, hasLength(2));
      expect(toc.every((e) => e.level <= 2), isTrue);
    });

    test('generates anchors when enabled', () {
      final blocks = createBlocks([
        (ContentBlockType.heading, 1, '# Title'),
        (ContentBlockType.heading, 2, '## Subtitle'),
      ]);

      final toc = generator.generateFlat(blocks);

      expect(toc[0].anchor, isNotNull);
      expect(toc[0].anchor, startsWith('heading-'));
      expect(toc[1].anchor, isNotNull);
    });

    test('skips anchors when disabled', () {
      final customGenerator = TocGenerator(
        config: const TocConfig(generateAnchors: false),
      );

      final blocks = createBlocks([
        (ContentBlockType.heading, 1, '# Title'),
      ]);

      final toc = customGenerator.generateFlat(blocks);

      expect(toc[0].anchor, isNull);
    });

    test('extracts heading text correctly', () {
      final blocks = createBlocks([
        (ContentBlockType.heading, 1, '# Hello World'),
        (ContentBlockType.heading, 2, '## With **bold** text'),
      ]);

      final toc = generator.generateFlat(blocks);

      expect(toc[0].title, 'Hello World');
      expect(toc[1].title, 'With **bold** text');
    });

    test('builds correct hierarchy', () {
      final blocks = createBlocks([
        (ContentBlockType.heading, 1, '# Chapter 1'),
        (ContentBlockType.heading, 2, '## Section 1.1'),
        (ContentBlockType.heading, 3, '### Subsection 1.1.1'),
        (ContentBlockType.heading, 2, '## Section 1.2'),
        (ContentBlockType.heading, 1, '# Chapter 2'),
        (ContentBlockType.heading, 2, '## Section 2.1'),
      ]);

      final toc = generator.generate(blocks);

      expect(toc, hasLength(2)); // 2 chapters
      expect(toc[0].title, 'Chapter 1');
      expect(toc[0].children, hasLength(2)); // 2 sections under chapter 1
      expect(toc[0].children[0].children, hasLength(1)); // 1 subsection
      expect(toc[1].title, 'Chapter 2');
      expect(toc[1].children, hasLength(1)); // 1 section under chapter 2
    });

    test('tracks correct block indices', () {
      final blocks = createBlocks([
        (ContentBlockType.paragraph, null, 'Intro'),
        (ContentBlockType.heading, 1, '# Title'),
        (ContentBlockType.paragraph, null, 'Content'),
        (ContentBlockType.heading, 2, '## Subtitle'),
      ]);

      final toc = generator.generateFlat(blocks);

      expect(toc[0].blockIndex, 1); // Title is at index 1
      expect(toc[1].blockIndex, 3); // Subtitle is at index 3
    });
  });

  group('TocEntry', () {
    test('copyWith creates modified copy', () {
      const entry = TocEntry(
        title: 'Original',
        level: 1,
        blockIndex: 0,
      );

      final modified = entry.copyWith(title: 'Modified');

      expect(modified.title, 'Modified');
      expect(modified.level, 1);
      expect(modified.blockIndex, 0);
    });

    test('toString returns readable format', () {
      const entry = TocEntry(
        title: 'Test',
        level: 2,
        blockIndex: 5,
      );

      expect(entry.toString(), contains('level: 2'));
      expect(entry.toString(), contains('Test'));
    });
  });

  group('TocConfig', () {
    test('default values', () {
      const config = TocConfig();

      expect(config.minLevel, 1);
      expect(config.maxLevel, 6);
      expect(config.generateAnchors, isTrue);
      expect(config.buildHierarchy, isTrue);
    });

    test('copyWith preserves unmodified values', () {
      const config = TocConfig(minLevel: 2, maxLevel: 4);
      final modified = config.copyWith(minLevel: 3);

      expect(modified.minLevel, 3);
      expect(modified.maxLevel, 4);
    });
  });
}
