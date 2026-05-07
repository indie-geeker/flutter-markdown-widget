// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/src/widgets/components/mermaid_view.dart';
import 'package:flutter_markdown_widget/testing.dart';
import 'package:flutter_markdown_widget_example/data/demo_entries.dart';
import 'package:flutter_markdown_widget_example/mermaid/mermaid_demo_scope.dart';
import 'package:flutter_markdown_widget_example/pages/mermaid_showcase_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home demo entries include Mermaid Showcase', () {
    expect(
      demoEntries.map((entry) => entry.title),
      contains('Mermaid Showcase'),
    );
  });

  testWidgets('MermaidShowcasePage renders static Mermaid diagrams', (
    tester,
  ) async {
    final renderer = FakeMermaidRenderer();

    await tester.pumpWidget(
      MermaidDemoScope(
        renderer: renderer,
        child: const MaterialApp(home: MermaidShowcasePage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Mermaid Showcase'), findsWidgets);
    expect(find.byType(MermaidView), findsWidgets);
    expect(renderer.calls, isNotEmpty);
    expect(
      renderer.calls.map((call) => call.source),
      anyElement(contains('flowchart')),
    );
  });
}
