// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_cache.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_error.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_options.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_theme.dart';
import 'package:flutter_markdown_widget/src/testing/fake_mermaid_renderer.dart';
import 'package:flutter_markdown_widget/src/widgets/components/mermaid_artifact_view.dart';
import 'package:flutter_markdown_widget/src/widgets/components/mermaid_view.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 400, child: child)),
);

void main() {
  testWidgets('A7: render exceeds timeout -> red banner with Retry', (
    tester,
  ) async {
    final fake = FakeMermaidRenderer()..latency = const Duration(seconds: 30);
    await tester.pumpWidget(
      _wrap(
        MermaidView(
          source: 'graph LR\nA-->B',
          contentHash: 1,
          sourceComplete: true,
          options: MermaidOptions(
            renderer: fake,
            renderTimeout: const Duration(milliseconds: 50),
          ),
          cache: MermaidCache(capacity: 4),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.byKey(const Key('mermaid-error-banner')), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
  });

  testWidgets('A8: tapping Retry triggers a second render call', (
    tester,
  ) async {
    final fake = FakeMermaidRenderer()
      ..errorToThrow = MermaidRuntimeError(
        source: 'x',
        cause: StateError('boom'),
        stackTrace: StackTrace.current,
      );
    await tester.pumpWidget(
      _wrap(
        MermaidView(
          source: 'x',
          contentHash: 1,
          sourceComplete: true,
          options: MermaidOptions(renderer: fake),
          cache: MermaidCache(capacity: 4),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(fake.calls, hasLength(1));
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(fake.calls, hasLength(2));
  });

  testWidgets('A9: source change discards old future and triggers new render', (
    tester,
  ) async {
    final fake = FakeMermaidRenderer()
      ..latency = const Duration(milliseconds: 30);
    final cache = MermaidCache(capacity: 4);

    Widget makeView(String source, int hash) => _wrap(
      MermaidView(
        source: source,
        contentHash: hash,
        sourceComplete: true,
        options: MermaidOptions(renderer: fake),
        cache: cache,
      ),
    );

    await tester.pumpWidget(makeView('source-a', 1));
    await tester.pump();
    await tester.pumpWidget(makeView('source-b', 2));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    expect(fake.calls, hasLength(2));
    expect(find.byType(MermaidArtifactView), findsOneWidget);
  });

  testWidgets('A10: theme change invalidates current artifact and re-renders', (
    tester,
  ) async {
    final fake = FakeMermaidRenderer();
    final cache = MermaidCache(capacity: 4);

    Widget makeView(MermaidTheme theme) => _wrap(
      MermaidView(
        source: 'g',
        contentHash: 1,
        sourceComplete: true,
        options: MermaidOptions(renderer: fake, theme: theme),
        cache: cache,
      ),
    );

    await tester.pumpWidget(makeView(MermaidTheme.light));
    await tester.pump();
    await tester.pump();
    expect(fake.calls, hasLength(1));
    expect(fake.calls.last.theme, MermaidTheme.light);

    await tester.pumpWidget(makeView(MermaidTheme.dark));
    await tester.pump();
    await tester.pump();
    expect(fake.calls, hasLength(2));
    expect(fake.calls.last.theme, MermaidTheme.dark);
  });

  testWidgets(
    'A11: unmount during in-flight render does not throw and writes cache',
    (tester) async {
      final fake = FakeMermaidRenderer()
        ..latency = const Duration(milliseconds: 30);
      final cache = MermaidCache(capacity: 4);

      await tester.pumpWidget(
        _wrap(
          MermaidView(
            source: 'graph LR\nA-->B',
            contentHash: 1,
            sourceComplete: true,
            options: MermaidOptions(renderer: fake),
            cache: cache,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(_wrap(const SizedBox()));
      await tester.pump(const Duration(milliseconds: 60));

      expect(tester.takeException(), isNull);
      expect(cache.length, 1);
    },
  );
}
