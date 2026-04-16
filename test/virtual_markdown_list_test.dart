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

    testWidgets('records actual heights in estimator after layout', (tester) async {
      final blocks = makeBlocks(3);
      final estimator = BlockDimensionEstimator();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: VirtualMarkdownList(
                blocks: blocks,
                dimensionEstimator: estimator,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // After layout, the estimator should have recorded actual heights
      // for at least the visible blocks
      bool anyRecorded = false;
      for (final block in blocks) {
        if (estimator.getActualHeight(block.contentHash) != null) {
          anyRecorded = true;
          break;
        }
      }
      expect(anyRecorded, isTrue);
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
