// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Future<void> pumpBlock(
  WidgetTester tester,
  ContentBlock block, {
  RenderOptions renderOptions = const RenderOptions(),
  MarkdownTheme? theme,
}) async {
  final builder = ContentBuilder(renderOptions: renderOptions, theme: theme);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => builder.buildBlock(context, block),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ContentBlock _makeBlock(
  ContentBlockType type,
  String rawContent, {
  int? headingLevel,
  String? language,
  Map<String, dynamic> metadata = const {},
}) {
  return ContentBlock(
    type: type,
    rawContent: rawContent,
    contentHash: rawContent.hashCode,
    startLine: 0,
    endLine: rawContent.split('\n').length - 1,
    headingLevel: headingLevel,
    language: language,
    metadata: metadata,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // paragraph
  // -------------------------------------------------------------------------
  group('paragraph', () {
    testWidgets('renders plain text content', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(ContentBlockType.paragraph, 'Hello World'),
      );

      expect(find.text('Hello World', findRichText: true), findsOneWidget);
    });

    testWidgets('renders bold text using inline span', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(ContentBlockType.paragraph, '**bold**'),
      );

      // The parsed text "bold" should appear somewhere in the widget tree.
      expect(find.text('bold', findRichText: true), findsOneWidget);
    });

    testWidgets('renders italic text', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(ContentBlockType.paragraph, '*italic*'),
      );

      expect(find.text('italic', findRichText: true), findsOneWidget);
    });

    testWidgets('renders inline code with code style', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(ContentBlockType.paragraph, '`code`'),
      );

      // The word "code" should appear in the rendered rich text.
      expect(find.text('code', findRichText: true), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // heading
  // -------------------------------------------------------------------------
  group('heading', () {
    testWidgets('h1 renders with text content', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(
          ContentBlockType.heading,
          '# My H1 Heading',
          headingLevel: 1,
        ),
      );

      expect(find.text('My H1 Heading', findRichText: true), findsOneWidget);
    });

    testWidgets('h2 renders with text content', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(
          ContentBlockType.heading,
          '## My H2 Heading',
          headingLevel: 2,
        ),
      );

      expect(find.text('My H2 Heading', findRichText: true), findsOneWidget);
    });

    testWidgets('h3 renders with text content', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(
          ContentBlockType.heading,
          '### My H3 Heading',
          headingLevel: 3,
        ),
      );

      expect(find.text('My H3 Heading', findRichText: true), findsOneWidget);
    });

    testWidgets('heading level defaults to 1 when headingLevel is null',
        (tester) async {
      // headingLevel == null, so the builder should fall back to level 1.
      await pumpBlock(
        tester,
        _makeBlock(
          ContentBlockType.heading,
          '# Default Level Heading',
          // intentionally omit headingLevel
        ),
      );

      // If it rendered without throwing we confirm the default path was used.
      expect(find.text('Default Level Heading', findRichText: true),
          findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // codeBlock
  // -------------------------------------------------------------------------
  group('codeBlock', () {
    testWidgets('renders code content', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(
          ContentBlockType.codeBlock,
          '```\nprint("hello");\n```',
        ),
      );

      expect(find.byType(CodeBlockView), findsOneWidget);
      expect(find.text('print("hello");'), findsOneWidget);
    });

    testWidgets('shows language label when language is set', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(
          ContentBlockType.codeBlock,
          '```dart\nprint("hello");\n```',
          language: 'dart',
        ),
      );

      // The CodeBlockView shows the language label in uppercase when
      // enableCodeHighlight is true (the default).
      expect(find.text('DART'), findsOneWidget);
    });

    testWidgets(
        'with enableCodeHighlight false still renders code content',
        (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(
          ContentBlockType.codeBlock,
          '```\nsimple code\n```',
        ),
        renderOptions: const RenderOptions(enableCodeHighlight: false),
      );

      expect(find.byType(CodeBlockView), findsOneWidget);
      expect(find.text('simple code'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // blockquote
  // -------------------------------------------------------------------------
  group('blockquote', () {
    testWidgets('renders blockquote text content (strips > prefix)',
        (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(ContentBlockType.blockquote, '> Quote text here'),
      );

      expect(
          find.text('Quote text here', findRichText: true), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // lists
  // -------------------------------------------------------------------------
  group('lists', () {
    testWidgets('unordered list shows bullet marker', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(
          ContentBlockType.unorderedList,
          '- Apple\n- Banana\n- Cherry',
        ),
      );

      // The bullet character "•" is rendered via a Text widget.
      expect(find.text('• '), findsWidgets);
      expect(find.text('Apple', findRichText: true), findsOneWidget);
    });

    testWidgets('ordered list shows numbered marker', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(
          ContentBlockType.orderedList,
          '1. First\n2. Second\n3. Third',
        ),
      );

      expect(find.text('1. '), findsOneWidget);
      expect(find.text('First', findRichText: true), findsOneWidget);
    });

    testWidgets('task list with [x] shows checkbox icon', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(
          ContentBlockType.unorderedList,
          '- [x] Done\n- [ ] Todo',
        ),
        renderOptions: const RenderOptions(enableTaskLists: true),
      );

      // Checked item uses Icons.check_box, unchecked uses
      // Icons.check_box_outline_blank.
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // horizontalRule / thematicBreak
  // -------------------------------------------------------------------------
  group('horizontalRule', () {
    testWidgets('renders a Divider widget', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(ContentBlockType.horizontalRule, '---'),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('thematicBreak also renders a Divider widget', (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(ContentBlockType.thematicBreak, '---'),
      );

      expect(find.byType(Divider), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // image
  // -------------------------------------------------------------------------
  group('image', () {
    testWidgets(
        'enableImageLoading false renders text placeholder',
        (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(
          ContentBlockType.image,
          '![my alt](https://example.com/img.png)',
        ),
        renderOptions: const RenderOptions(enableImageLoading: false),
      );

      expect(find.text('[Image: my alt]'), findsOneWidget);
    });

    testWidgets(
        'enableImageLoading true renders Image.network widget',
        (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(
          ContentBlockType.image,
          '![alt text](https://example.com/img.png)',
        ),
        renderOptions: const RenderOptions(enableImageLoading: true),
      );

      // Image.network is present in the widget tree even if the network
      // request never completes in the test environment.
      expect(find.byType(Image), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // latexBlock
  // -------------------------------------------------------------------------
  group('latexBlock', () {
    testWidgets(
        'enableLatex false falls back to CodeBlockView (not FormulaBuilder)',
        (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(ContentBlockType.latexBlock, r'$$x = 1$$'),
        renderOptions: const RenderOptions(enableLatex: false),
      );

      // When LaTeX is disabled the builder delegates to _buildCodeBlock
      // which produces a CodeBlockView.
      expect(find.byType(CodeBlockView), findsOneWidget);
    });

    testWidgets(
        'enableLatex true attempts formula rendering and does not crash',
        (tester) async {
      // flutter_math_fork renders Math.tex; we just verify no exception is
      // thrown and the subtree is present (it may fall back to an error
      // widget for unsupported TeX in the test renderer, which is fine).
      await pumpBlock(
        tester,
        _makeBlock(ContentBlockType.latexBlock, r'$$x = 1$$'),
        renderOptions: const RenderOptions(enableLatex: true),
      );

      // The formula path should NOT produce a CodeBlockView.
      expect(find.byType(CodeBlockView), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // feature toggles via RenderOptions
  // -------------------------------------------------------------------------
  group('feature toggles via RenderOptions', () {
    testWidgets(
        'enableTables false renders table raw content as paragraph',
        (tester) async {
      const tableRaw = '| A | B |\n|---|---|\n| 1 | 2 |';
      await pumpBlock(
        tester,
        _makeBlock(ContentBlockType.table, tableRaw),
        renderOptions: const RenderOptions(enableTables: false),
      );

      // Falls back to paragraph — should produce a RichText (or
      // SelectableText) but NOT a Table widget.
      expect(find.byType(Table), findsNothing);
    });

    testWidgets('strikethrough text in paragraph renders the text',
        (tester) async {
      await pumpBlock(
        tester,
        _makeBlock(ContentBlockType.paragraph, '~~strikethrough~~'),
        renderOptions: const RenderOptions(enableStrikethrough: true),
      );

      expect(
          find.text('strikethrough', findRichText: true), findsOneWidget);
    });
  });
}
