// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_artifact.dart';
import 'package:flutter_markdown_widget/src/widgets/components/mermaid_fullscreen_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

const _validSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 400"><rect width="800" height="400" fill="#aaa"/></svg>';

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
