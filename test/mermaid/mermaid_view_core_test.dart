// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_artifact.dart';
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
  testWidgets('A1: incomplete source renders fallback (no renderer call)', (
    tester,
  ) async {
    final fake = FakeMermaidRenderer();
    await tester.pumpWidget(
      _wrap(
        MermaidView(
          source: 'graph LR',
          contentHash: 1,
          sourceComplete: false,
          options: MermaidOptions(renderer: fake),
          cache: MermaidCache(capacity: 4),
        ),
      ),
    );
    expect(fake.calls, isEmpty);
    expect(find.byType(MermaidArtifactView), findsNothing);
    expect(find.text('graph LR'), findsOneWidget);
  });

  testWidgets('A2: renderer null -> not-configured banner + source visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MermaidView(
          source: 'graph LR\nA-->B',
          contentHash: 2,
          sourceComplete: true,
          options: const MermaidOptions(),
          cache: MermaidCache(capacity: 4),
        ),
      ),
    );
    expect(
      find.byKey(const Key('mermaid-not-configured-banner')),
      findsOneWidget,
    );
    expect(find.text('graph LR\nA-->B'), findsOneWidget);
  });

  testWidgets(
    'A4: cache hit renders artifact synchronously, renderer not called',
    (tester) async {
      final fake = FakeMermaidRenderer();
      final cache = MermaidCache(capacity: 4);
      cache.put(
        MermaidCache.buildKey(
          contentHash: 42,
          theme: MermaidTheme.light,
          rendererVersion: fake.version,
        ),
        const MermaidArtifact(
          svg:
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 50"></svg>',
          intrinsicSize: Size(100, 50),
        ),
      );
      await tester.pumpWidget(
        _wrap(
          MermaidView(
            source: 'graph LR\nA-->B',
            contentHash: 42,
            sourceComplete: true,
            options: MermaidOptions(renderer: fake, theme: MermaidTheme.light),
            cache: cache,
          ),
        ),
      );
      expect(find.byType(MermaidArtifactView), findsOneWidget);
      expect(fake.calls, isEmpty);
    },
  );

  testWidgets(
    'A3 -> A5: cache miss shows spinner then transitions to artifact',
    (tester) async {
      final fake = FakeMermaidRenderer()
        ..latency = const Duration(milliseconds: 30);
      final cache = MermaidCache(capacity: 4);
      await tester.pumpWidget(
        _wrap(
          MermaidView(
            source: 'graph LR\nA-->B',
            contentHash: 7,
            sourceComplete: true,
            options: MermaidOptions(renderer: fake, theme: MermaidTheme.light),
            cache: cache,
          ),
        ),
      );
      expect(find.byKey(const Key('mermaid-inflight-spinner')), findsOneWidget);
      expect(fake.calls, hasLength(1));

      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();
      expect(find.byType(MermaidArtifactView), findsOneWidget);
      expect(cache.length, 1);
    },
  );

  testWidgets(
    'A6: syntax error degrades to fallback + red banner; not cached',
    (tester) async {
      final fake = FakeMermaidRenderer()
        ..errorToThrow = MermaidSyntaxError(
          source: 'bad',
          message: 'parse fail',
          stackTrace: StackTrace.current,
        );
      final cache = MermaidCache(capacity: 4);
      await tester.pumpWidget(
        _wrap(
          MermaidView(
            source: 'bad',
            contentHash: 8,
            sourceComplete: true,
            options: MermaidOptions(renderer: fake),
            cache: cache,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('mermaid-error-banner')), findsOneWidget);
      expect(find.textContaining('parse fail'), findsOneWidget);
      expect(cache.length, 0);
    },
  );

  testWidgets('A12: !isReady shows initializing spinner over fallback', (
    tester,
  ) async {
    final fake = FakeMermaidRenderer()
      ..simulateNotReady = true
      ..latency = const Duration(milliseconds: 30);
    final cache = MermaidCache(capacity: 4);
    await tester.pumpWidget(
      _wrap(
        MermaidView(
          source: 'graph LR\nA-->B',
          contentHash: 9,
          sourceComplete: true,
          options: MermaidOptions(renderer: fake),
          cache: cache,
        ),
      ),
    );
    expect(
      find.byKey(const Key('mermaid-initializing-spinner')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
  });
}
