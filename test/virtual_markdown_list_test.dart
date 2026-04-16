// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VirtualMarkdownList', () {
    List<ContentBlock> makeBlocks(int count) {
      return List.generate(count, (i) {
        return ContentBlock(
          type: ContentBlockType.paragraph,
          rawContent: 'Paragraph $i with some text content.',
          contentHash: i,
          startLine: i,
          endLine: i,
        );
      });
    }

    testWidgets('renders blocks in a scrollable list', (tester) async {
      final blocks = makeBlocks(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: VirtualMarkdownList(
                blocks: blocks,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // At least some blocks should be rendered
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('lets children take their natural height (no forced extent)',
        (tester) async {
      // Regression test for RenderFlex overflow caused by forcing children to
      // an estimated height via SliverVariedExtentList. Blocks with the same
      // type but very different content lengths must each lay out at their
      // own natural height without clipping or overflow.
      final blocks = [
        ContentBlock(
          type: ContentBlockType.paragraph,
          rawContent: 'short',
          contentHash: 1,
          startLine: 0,
          endLine: 0,
        ),
        ContentBlock(
          type: ContentBlockType.paragraph,
          rawContent: List.filled(40, 'word').join(' '),
          contentHash: 2,
          startLine: 1,
          endLine: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: VirtualMarkdownList(blocks: blocks),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No rendering exceptions (overflow would surface as an exception).
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'does not reuse widget instances across blocks with duplicate contentHash',
        (tester) async {
      // Regression test for a latent GlobalKey-duplication bug.
      //
      // When the same content appears at multiple positions, the blocks
      // share a contentHash. If VirtualMarkdownList serves cached widget
      // instances from WidgetRenderCache by contentHash, the same instance
      // is mounted at two tree positions at once. Any GlobalKey inside that
      // widget (e.g. flutter_math_fork's Math.tex internal keys) then
      // triggers "Duplicate GlobalKeys detected in widget tree".
      //
      // We verify the fix structurally: when an external cache is passed,
      // the build path must not populate it. A zero miss count after render
      // proves cache.getOrBuild was never called during block builds.
      const sharedHash = 777;
      final blocks = [
        ContentBlock(
          type: ContentBlockType.paragraph,
          rawContent: 'Repeated content',
          contentHash: sharedHash,
          startLine: 0,
          endLine: 0,
        ),
        ContentBlock(
          type: ContentBlockType.paragraph,
          rawContent: 'Repeated content',
          contentHash: sharedHash,
          startLine: 1,
          endLine: 1,
        ),
      ];
      final cache = WidgetRenderCache();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: VirtualMarkdownList(
                blocks: blocks,
                widgetCache: cache,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(cache.size, 0,
          reason: 'Cache must not be populated from the render path.');
      expect(cache.misses, 0,
          reason: 'cache.getOrBuild must not be called during block builds.');
    });

    testWidgets('handles empty blocks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: VirtualMarkdownList(
                blocks: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
