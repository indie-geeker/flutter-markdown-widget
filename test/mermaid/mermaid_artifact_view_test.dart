// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_artifact.dart';
import 'package:flutter_markdown_widget/src/widgets/components/mermaid_artifact_view.dart';
import 'package:flutter_test/flutter_test.dart';

const _validSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 400"><rect width="800" height="400" fill="#abc"/></svg>';

void main() {
  testWidgets(
    'renders an SVG inside a SizedBox sized to scaled intrinsicSize',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              child: MermaidArtifactView(
                artifact: const MermaidArtifact(
                  svg: _validSvg,
                  intrinsicSize: Size(800, 400),
                ),
              ),
            ),
          ),
        ),
      );

      final sizedBoxFinder = find.byKey(
        const Key('mermaid-artifact-sized-box'),
      );
      expect(sizedBoxFinder, findsOneWidget);
      final box = tester.getSize(sizedBoxFinder);
      expect(box.width, closeTo(400, 0.1));
      expect(box.height, closeTo(200, 0.1));
    },
  );

  testWidgets(
    'falls back to a 16:9 placeholder ratio when intrinsicSize is null',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              child: MermaidArtifactView(
                artifact: const MermaidArtifact(svg: _validSvg),
              ),
            ),
          ),
        ),
      );

      final box = tester.getSize(
        find.byKey(const Key('mermaid-artifact-sized-box')),
      );
      expect(box.width, closeTo(320, 0.1));
      expect(box.height, closeTo(320 * 9 / 16, 0.5));
    },
  );

  testWidgets('invokes onTap when tapped and onTap is provided', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            child: MermaidArtifactView(
              artifact: const MermaidArtifact(
                svg: _validSvg,
                intrinsicSize: Size(100, 50),
              ),
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('mermaid-artifact-sized-box')));
    expect(taps, 1);
  });

  testWidgets('reports the laid out artifact size', (tester) async {
    Size? laidOutSize;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            child: MermaidArtifactView(
              artifact: const MermaidArtifact(
                svg: _validSvg,
                intrinsicSize: Size(800, 400),
              ),
              onLaidOutSize: (size) => laidOutSize = size,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(laidOutSize, isNotNull);
    expect(laidOutSize!.width, closeTo(400, 0.1));
    expect(laidOutSize!.height, closeTo(200, 0.1));
  });
}
