// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_widget_example/app/example_app.dart';
import 'package:flutter_markdown_widget_example/mermaid/mermaid_demo_scope.dart';

void main() {
  testWidgets('ExampleApp exposes a shared Mermaid renderer scope', (
    tester,
  ) async {
    final renderer = FakeMermaidRenderer();

    await tester.pumpWidget(ExampleApp(mermaidRenderer: renderer));

    MermaidDemoScope? scope;
    await tester.pumpWidget(
      ExampleApp(
        mermaidRenderer: renderer,
        home: Builder(
          builder: (context) {
            scope =
                context.dependOnInheritedWidgetOfExactType<MermaidDemoScope>();
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(scope, isNotNull);
    expect(scope!.renderer, same(renderer));
  });
}
