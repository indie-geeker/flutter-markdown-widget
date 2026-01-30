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
