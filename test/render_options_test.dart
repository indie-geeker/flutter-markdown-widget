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

/// Recursively walks all [InlineSpan]s in [span], including container spans
/// whose [TextSpan.text] is null (which [InlineSpan.visitChildren] skips).
/// Returns true if [predicate] matches any span.
bool _anySpan(InlineSpan span, bool Function(TextSpan) predicate) {
  if (span is TextSpan) {
    if (predicate(span)) return true;
    for (final child in span.children ?? <InlineSpan>[]) {
      if (_anySpan(child, predicate)) return true;
    }
  }
  return false;
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

      // Positive companion: monospace font MUST be applied when enabled.
      // The widget uses SelectableText.rich, so walk SelectableText spans.
      final selectableTexts =
          tester.widgetList<SelectableText>(find.byType(SelectableText));
      bool foundMonospace = false;
      for (final st in selectableTexts) {
        st.textSpan?.visitChildren((span) {
          if (span is TextSpan && span.style?.fontFamily == 'monospace') {
            foundMonospace = true;
          }
          return true;
        });
      }
      expect(foundMonospace, isTrue,
          reason: 'inline code should use monospace font when enableCodeHighlight is true');
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

        // When enableCodeHighlight is false, the code span has no codeStyle
        // applied (no monospace font or background color).
        final richTexts = tester.widgetList<RichText>(find.byType(RichText));
        bool foundMonospace = false;
        for (final rt in richTexts) {
          rt.text.visitChildren((span) {
            if (span is TextSpan && span.style?.fontFamily == 'monospace') {
              foundMonospace = true;
            }
            return true;
          });
        }
        expect(foundMonospace, isFalse,
            reason: 'No monospace style should be applied when enableCodeHighlight is false');
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

      // Positive companion: lineThrough decoration MUST be present when enabled.
      // The widget uses SelectableText.rich. The decoration is on a container
      // span (text=null), so use _anySpan which visits all spans recursively.
      final selectableTexts =
          tester.widgetList<SelectableText>(find.byType(SelectableText));
      final foundLineThrough = selectableTexts.any(
        (st) =>
            st.textSpan != null &&
            _anySpan(
              st.textSpan!,
              (s) => s.style?.decoration == TextDecoration.lineThrough,
            ),
      );
      expect(foundLineThrough, isTrue,
          reason: 'struck text should have lineThrough decoration when enableStrikethrough is true');
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

        // When enableStrikethrough is false, the del element's children are
        // rendered as plain text with no lineThrough decoration.
        final richTexts = tester.widgetList<RichText>(find.byType(RichText));
        bool foundLineThrough = false;
        for (final rt in richTexts) {
          rt.text.visitChildren((span) {
            if (span is TextSpan &&
                span.style?.decoration == TextDecoration.lineThrough) {
              foundLineThrough = true;
            }
            return true;
          });
        }
        expect(foundLineThrough, isFalse,
            reason: 'No lineThrough decoration should be present when enableStrikethrough is false');
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

      // Positive companion: underline decoration MUST be present when enabled.
      // The widget uses SelectableText.rich, so walk SelectableText spans.
      final selectableTexts =
          tester.widgetList<SelectableText>(find.byType(SelectableText));
      bool foundUnderline = false;
      for (final st in selectableTexts) {
        st.textSpan?.visitChildren((span) {
          if (span is TextSpan &&
              span.style?.decoration == TextDecoration.underline) {
            foundUnderline = true;
          }
          return true;
        });
      }
      expect(foundUnderline, isTrue,
          reason: 'autolinked URL should have underline decoration when enableAutolinks is true');
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

      // When enableAutolinks is false, the URL is plain text with no link
      // style (no underline decoration).
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      bool foundUnderline = false;
      for (final rt in richTexts) {
        rt.text.visitChildren((span) {
          if (span is TextSpan &&
              span.style?.decoration == TextDecoration.underline) {
            foundUnderline = true;
          }
          return true;
        });
      }
      expect(foundUnderline, isFalse,
          reason: 'No underline decoration should be present when enableAutolinks is false');
    });
  });
}
