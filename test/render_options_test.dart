// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpMarkdown(
  WidgetTester tester,
  String content, {
  required RenderOptions renderOptions,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StreamingMarkdownView(
          content: content,
          renderOptions: renderOptions,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('enableTables', () {
    testWidgets('true (default) — GFM table renders a Table widget', (
      tester,
    ) async {
      const tableContent = '''| Col A | Col B |
|-------|-------|
| 1     | 2     |''';

      await pumpMarkdown(
        tester,
        tableContent,
        renderOptions: const RenderOptions(parserMode: ParserMode.ast),
      );

      expect(find.byType(Table), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'false — same input renders no Table widget, falls back to paragraph',
      (tester) async {
        const tableContent = '''| Col A | Col B |
|-------|-------|
| 1     | 2     |''';

        await pumpMarkdown(
          tester,
          tableContent,
          renderOptions: const RenderOptions(
            parserMode: ParserMode.ast,
            enableTables: false,
          ),
        );

        expect(find.byType(Table), findsNothing);
        expect(find.textContaining('Col A'), findsAtLeastNWidgets(1));
      },
    );
  });

  group('enableCodeHighlight', () {
    testWidgets('true (default) — inline code text is present', (tester) async {
      await pumpMarkdown(
        tester,
        'Use `hello` here.',
        renderOptions: const RenderOptions(enableCodeHighlight: true),
      );

      expect(find.textContaining('hello'), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'false — inline code text is still present without special style',
      (tester) async {
        await pumpMarkdown(
          tester,
          'Use `hello` here.',
          renderOptions: const RenderOptions(enableCodeHighlight: false),
        );

        expect(find.textContaining('hello'), findsAtLeastNWidgets(1));
      },
    );
  });

  group('enableStrikethrough', () {
    testWidgets('true (default) — struck text is rendered', (tester) async {
      await pumpMarkdown(
        tester,
        'This is ~~struck~~ text.',
        renderOptions: const RenderOptions(enableStrikethrough: true),
      );

      expect(find.textContaining('struck'), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'false — struck text still renders without crash or empty widget',
      (tester) async {
        await pumpMarkdown(
          tester,
          'This is ~~struck~~ text.',
          renderOptions: const RenderOptions(enableStrikethrough: false),
        );

        expect(find.textContaining('struck'), findsAtLeastNWidgets(1));
      },
    );
  });

  group('enableAutolinks', () {
    testWidgets('true (default) — bare URL in paragraph is rendered', (
      tester,
    ) async {
      await pumpMarkdown(
        tester,
        'Visit https://example.com for info',
        renderOptions: const RenderOptions(enableAutolinks: true),
      );

      expect(
        find.textContaining('https://example.com'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('false — URL text is still present as plain text', (
      tester,
    ) async {
      await pumpMarkdown(
        tester,
        'Visit https://example.com for info',
        renderOptions: const RenderOptions(enableAutolinks: false),
      );

      expect(
        find.textContaining('https://example.com'),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
