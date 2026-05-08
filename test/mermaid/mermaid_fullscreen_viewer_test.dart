// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_artifact.dart';
import 'package:flutter_markdown_widget/src/widgets/components/mermaid_fullscreen_viewer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _validSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 400"><rect width="800" height="400" fill="#aaa"/></svg>';

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
  testWidgets('shows InteractiveViewer with the SVG and a close button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MermaidFullscreenViewer(
          artifact: const MermaidArtifact(
            svg: _validSvg,
            intrinsicSize: Size(800, 400),
          ),
        ),
      ),
    );

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets(
    'prefers Image.memory when artifact carries rasterPng',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MermaidFullscreenViewer(
            artifact: MermaidArtifact(
              svg: _validSvg,
              intrinsicSize: const Size(800, 400),
              rasterPng: _onePixelPng,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('mermaid-fullscreen-png')), findsOneWidget);
      expect(find.byKey(const Key('mermaid-fullscreen-svg')), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    },
  );

  testWidgets(
    'falls back to SvgPicture when rasterPng is absent',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MermaidFullscreenViewer(
            artifact: const MermaidArtifact(
              svg: _validSvg,
              intrinsicSize: Size(800, 400),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('mermaid-fullscreen-svg')), findsOneWidget);
      expect(find.byKey(const Key('mermaid-fullscreen-png')), findsNothing);
    },
  );

  testWidgets('tapping the close button pops the route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MermaidFullscreenViewer(
                    artifact: const MermaidArtifact(svg: _validSvg),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(MermaidFullscreenViewer), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(MermaidFullscreenViewer), findsNothing);
  });
}
