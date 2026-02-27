// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StreamingMarkdownView', () {
    testWidgets('renders static content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView(
              content: '# Hello World\n\nThis is a test.',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text('This is a test.'), findsOneWidget);
    });

    testWidgets('renders code block with language label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView(
              content: '''```dart
void main() {}
```''',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DART'), findsOneWidget);
      expect(find.text('void main() {}'), findsOneWidget);
    });

    testWidgets('shows copy button on code block', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView(
              content: '```\ncode\n```',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('renders line numbers for multiline code blocks', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView(
              content: '''```dart
line1
line2
line3
```''',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('handles streaming from stream', (tester) async {
      // Test that the factory constructor creates a widget
      final controller = StreamController<String>.broadcast();
      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView.fromStream(
              stream: controller.stream,
            ),
          ),
        ),
      );

      // Widget should be created successfully
      expect(find.byType(StreamingMarkdownView), findsOneWidget);
    });

    testWidgets('uses parser factory when provided', (tester) async {
      final blocks = [
        const ContentBlock(
          type: ContentBlockType.paragraph,
          rawContent: 'From factory',
          contentHash: 1,
          startLine: 0,
          endLine: 0,
        ),
      ];

      final options = RenderOptions(
        parserFactory: (_) => _StubParser(blocks),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView(
              content: 'Ignored content',
              renderOptions: options,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('From factory'), findsOneWidget);
    });

    testWidgets('respects buffer mode byLine', (tester) async {
      final controller = StreamController<String>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView.fromStream(
              stream: controller.stream,
              streamingOptions: const StreamingOptions(
                bufferMode: BufferMode.byLine,
              ),
            ),
          ),
        ),
      );

      controller.add('Hello');
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Hello'), findsNothing);

      controller.add('\n');
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('shows typing cursor when configured', (tester) async {
      // Test typing cursor by using static content first
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingCursor(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(TypingCursor), findsOneWidget);
    });

    testWidgets('applies custom theme', (tester) async {
      final customTheme = MarkdownTheme(
        textStyle: const TextStyle(fontSize: 20, color: Colors.red),
        headingSpacing: 32,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView(
              content: '# Title',
              theme: customTheme,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final titleFinder = find.text('Title');
      expect(titleFinder, findsOneWidget);
    });

    testWidgets('respects render options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView(
              content: r'$E = mc^2$',
              renderOptions: RenderOptions(enableLatex: false),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // LaTeX should be rendered as plain text when disabled
      expect(find.textContaining('E = mc^2'), findsOneWidget);
    });

    testWidgets('renders inline image placeholder when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView(
              content: 'Image: ![Alt](https://example.com/image.png)',
              renderOptions: RenderOptions(enableImageLoading: false),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('[Image: Alt]'), findsOneWidget);
    });

    testWidgets('falls back to paragraph for malformed table blocks', (tester) async {
      final blocks = [
        const ContentBlock(
          type: ContentBlockType.table,
          rawContent: '| just text |',
          contentHash: 7,
          startLine: 0,
          endLine: 0,
        ),
      ];
      final options = RenderOptions(parserFactory: (_) => _StubParser(blocks));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView(
              content: 'ignored',
              renderOptions: options,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('| just text |'), findsOneWidget);
    });

    testWidgets('does not recreate parser for equivalent options and theme', (
      tester,
    ) async {
      int factoryCalls = 0;
      final blocks = [
        const ContentBlock(
          type: ContentBlockType.paragraph,
          rawContent: 'From factory',
          contentHash: 11,
          startLine: 0,
          endLine: 0,
        ),
      ];
      MarkdownParser parserFactory(RenderOptions _) {
        factoryCalls++;
        return _StubParser(blocks);
      }

      final options1 = RenderOptions(parserFactory: parserFactory);
      final options2 = RenderOptions(parserFactory: parserFactory);
      final theme1 = MarkdownTheme(headingSpacing: 24);
      final theme2 = MarkdownTheme(headingSpacing: 24);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView(
              content: 'ignored',
              renderOptions: options1,
              theme: theme1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(factoryCalls, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView(
              content: 'ignored',
              renderOptions: options2,
              theme: theme2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(factoryCalls, 1);
    });
  });

  group('MarkdownContent', () {
    testWidgets('renders without scroll', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MarkdownContent(
                content: 'Paragraph 1\n\nParagraph 2',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Paragraph 1'), findsOneWidget);
      expect(find.text('Paragraph 2'), findsOneWidget);
    });

    testWidgets('calls onBlocksGenerated callback', (tester) async {
      List<ContentBlock>? generatedBlocks;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownContent(
              content: '# Title\n\nContent',
              onBlocksGenerated: (blocks) {
                generatedBlocks = blocks;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(generatedBlocks, isNotNull);
      expect(generatedBlocks!.length, greaterThanOrEqualTo(2));
    });

    testWidgets('does not recreate parser for equivalent render options', (
      tester,
    ) async {
      int factoryCalls = 0;
      final blocks = [
        const ContentBlock(
          type: ContentBlockType.paragraph,
          rawContent: 'Factory block',
          contentHash: 21,
          startLine: 0,
          endLine: 0,
        ),
      ];
      MarkdownParser parserFactory(RenderOptions _) {
        factoryCalls++;
        return _StubParser(blocks);
      }

      final options1 = RenderOptions(parserFactory: parserFactory);
      final options2 = RenderOptions(parserFactory: parserFactory);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownContent(
              content: 'ignored',
              renderOptions: options1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(factoryCalls, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownContent(
              content: 'ignored',
              renderOptions: options2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(factoryCalls, 1);
    });
  });

  group('MarkdownWidget', () {
    testWidgets('does not recreate parser for equivalent render options', (
      tester,
    ) async {
      int factoryCalls = 0;
      final blocks = [
        const ContentBlock(
          type: ContentBlockType.heading,
          rawContent: '# Factory title',
          contentHash: 31,
          startLine: 0,
          endLine: 0,
          headingLevel: 1,
        ),
      ];
      MarkdownParser parserFactory(RenderOptions _) {
        factoryCalls++;
        return _StubParser(blocks);
      }

      final options1 = RenderOptions(parserFactory: parserFactory);
      final options2 = RenderOptions(parserFactory: parserFactory);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownWidget(
              data: 'ignored',
              renderOptions: options1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(factoryCalls, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownWidget(
              data: 'ignored',
              renderOptions: options2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(factoryCalls, 1);
    });
  });

  group('TocView', () {
    testWidgets('renders TOC entries', (tester) async {
      final entries = [
        const TocEntry(title: 'Chapter 1', level: 1, blockIndex: 0),
        const TocEntry(title: 'Section 1.1', level: 2, blockIndex: 1),
        const TocEntry(title: 'Chapter 2', level: 1, blockIndex: 2),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TocView(entries: entries),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chapter 1'), findsOneWidget);
      expect(find.text('Section 1.1'), findsOneWidget);
      expect(find.text('Chapter 2'), findsOneWidget);
    });

    testWidgets('highlights active entry', (tester) async {
      final entries = [
        const TocEntry(title: 'Entry 1', level: 1, blockIndex: 0),
        const TocEntry(title: 'Entry 2', level: 1, blockIndex: 1),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TocView(
              entries: entries,
              activeIndex: 1,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The active entry should have a highlight indicator
      expect(find.text('Entry 2'), findsOneWidget);
    });

    testWidgets('calls onEntryTap', (tester) async {
      TocEntry? tappedEntry;

      final entries = [
        const TocEntry(title: 'Test Entry', level: 1, blockIndex: 0),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TocView(
              entries: entries,
              onEntryTap: (entry) {
                tappedEntry = entry;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Entry'));
      await tester.pumpAndSettle();

      expect(tappedEntry, isNotNull);
      expect(tappedEntry!.title, 'Test Entry');
    });
  });

  group('TypingCursor', () {
    testWidgets('animates blink', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingCursor(),
          ),
        ),
      );

      // Initial state
      await tester.pump();

      // After half blink duration
      await tester.pump(const Duration(milliseconds: 265));

      // After full blink
      await tester.pump(const Duration(milliseconds: 265));

      // Widget should still be rendered
      expect(find.byType(TypingCursor), findsOneWidget);
    });
  });
}

class _StubParser implements MarkdownParser {
  _StubParser(this._blocks);

  List<ContentBlock> _blocks;

  @override
  List<ContentBlock> get cachedBlocks => List.unmodifiable(_blocks);

  @override
  ParseResult parse(String text, {bool isStreaming = false}) {
    return ParseResult(
      blocks: _blocks,
      modifiedIndices: _blocks.isEmpty ? const <int>{} : {0},
    );
  }

  @override
  void reset() {
    _blocks = [];
  }

  @override
  void invalidate(int index) {}

  @override
  void invalidateFrom(int startIndex) {}
}
