// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/src/builder/content_builder.dart';
import 'package:flutter_markdown_widget/src/config/render_options.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_options.dart';
import 'package:flutter_markdown_widget/src/core/parser/content_block.dart';
import 'package:flutter_markdown_widget/src/testing/fake_mermaid_renderer.dart';
import 'package:flutter_markdown_widget/src/widgets/components/code_block_view.dart';
import 'package:flutter_markdown_widget/src/widgets/components/mermaid_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'language == "mermaid" routes to MermaidView when renderer configured',
    (tester) async {
      final fake = FakeMermaidRenderer();
      final builder = ContentBuilder(
        renderOptions: RenderOptions(
          mermaidOptions: MermaidOptions(renderer: fake),
        ),
      );
      const block = ContentBlock(
        type: ContentBlockType.codeBlock,
        rawContent: 'graph LR\nA-->B',
        contentHash: 1,
        language: 'mermaid',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) => builder.buildBlock(ctx, block)),
          ),
        ),
      );
      expect(find.byType(MermaidView), findsOneWidget);
    },
  );

  testWidgets(
    'language == "mermaid" with renderer null routes to MermaidView',
    (tester) async {
      final builder = ContentBuilder(
        renderOptions: const RenderOptions(mermaidOptions: MermaidOptions()),
      );
      const block = ContentBlock(
        type: ContentBlockType.codeBlock,
        rawContent: 'graph LR',
        contentHash: 2,
        language: 'mermaid',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) => builder.buildBlock(ctx, block)),
          ),
        ),
      );
      expect(find.byType(MermaidView), findsOneWidget);
    },
  );

  testWidgets(
    'language == "mermaid" with mermaidOptions == null falls back to CodeBlockView',
    (tester) async {
      final builder = ContentBuilder(renderOptions: const RenderOptions());
      const block = ContentBlock(
        type: ContentBlockType.codeBlock,
        rawContent: 'graph LR',
        contentHash: 3,
        language: 'mermaid',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) => builder.buildBlock(ctx, block)),
          ),
        ),
      );
      expect(find.byType(MermaidView), findsNothing);
      expect(find.byType(CodeBlockView), findsOneWidget);
    },
  );

  testWidgets('language == "dart" never routes to MermaidView', (tester) async {
    final fake = FakeMermaidRenderer();
    final builder = ContentBuilder(
      renderOptions: RenderOptions(
        mermaidOptions: MermaidOptions(renderer: fake),
      ),
    );
    const block = ContentBlock(
      type: ContentBlockType.codeBlock,
      rawContent: 'void main() {}',
      contentHash: 4,
      language: 'dart',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(builder: (ctx) => builder.buildBlock(ctx, block)),
        ),
      ),
    );
    expect(find.byType(MermaidView), findsNothing);
    expect(find.byType(CodeBlockView), findsOneWidget);
  });
}
