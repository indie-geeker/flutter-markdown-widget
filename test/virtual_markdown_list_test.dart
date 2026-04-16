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
