// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_artifact.dart';
import 'package:flutter_markdown_widget/src/widgets/components/mermaid_artifact_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _validSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 400"><rect width="800" height="400" fill="#abc"/></svg>';

// Minimal 1x1 transparent PNG.
final Uint8List _onePixelPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54,
  0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x00, 0x05,
  0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4,
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

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

  testWidgets(
    'prefers Image.memory when artifact carries rasterPng',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              child: MermaidArtifactView(
                artifact: MermaidArtifact(
                  svg: _validSvg,
                  intrinsicSize: const Size(800, 400),
                  rasterPng: _onePixelPng,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('mermaid-artifact-png')), findsOneWidget);
      expect(find.byKey(const Key('mermaid-artifact-svg')), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    },
  );

  testWidgets(
    'falls back to SvgPicture when rasterPng is null',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
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

      expect(find.byKey(const Key('mermaid-artifact-svg')), findsOneWidget);
      expect(find.byKey(const Key('mermaid-artifact-png')), findsNothing);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    },
  );

  testWidgets(
    'falls back to SvgPicture when rasterPng is empty',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              child: MermaidArtifactView(
                artifact: MermaidArtifact(
                  svg: _validSvg,
                  intrinsicSize: const Size(800, 400),
                  rasterPng: Uint8List(0),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('mermaid-artifact-svg')), findsOneWidget);
      expect(find.byKey(const Key('mermaid-artifact-png')), findsNothing);
    },
  );

  testWidgets(
    'caps a tall diagram by inline maxHeight rather than overflowing',
    (tester) async {
      // viewBox 159 x 300 (taller than wide) under a 700 x 480 box would
      // naturally render at ~700 x 1320 if only width were honored. The
      // height cap should kick in so the height stays at 480 and the width
      // shrinks to keep aspect. Align gives loose constraints so the inner
      // ConstrainedBox carries the exact max we want to test against.
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700, maxHeight: 480),
              child: MermaidArtifactView(
                artifact: MermaidArtifact(
                  svg: _validSvg,
                  intrinsicSize: const Size(159, 300),
                  rasterPng: _onePixelPng,
                ),
              ),
            ),
          ),
        ),
      );

      final box = tester.getSize(
        find.byKey(const Key('mermaid-artifact-sized-box')),
      );
      expect(box.height, lessThanOrEqualTo(480.0 + 0.1));
      // width must respect aspect ratio, so it should shrink with the height.
      expect(box.width, closeTo(480 * 159 / 300, 0.5));
    },
  );

  testWidgets(
    'caps upscale at 2x intrinsic so PNG stays crisp in wide columns',
    (tester) async {
      // 100 x 50 in a 600-wide column would naturally render at 600 x 300
      // (6x upscale) and look pixelated. Cap should pin width at 200 (2x)
      // and let the parent column carry empty whitespace beside it.
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 600,
              child: MermaidArtifactView(
                artifact: MermaidArtifact(
                  svg: _validSvg,
                  intrinsicSize: const Size(100, 50),
                  rasterPng: _onePixelPng,
                ),
              ),
            ),
          ),
        ),
      );

      final box = tester.getSize(
        find.byKey(const Key('mermaid-artifact-sized-box')),
      );
      expect(box.width, closeTo(200, 0.1));
      expect(box.height, closeTo(100, 0.1));
    },
  );

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
