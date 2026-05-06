// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_error.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_theme.dart';
import 'package:flutter_markdown_widget/src/testing/fake_mermaid_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeMermaidRenderer', () {
    test('returns a default artifact and records calls', () async {
      final fake = FakeMermaidRenderer();
      final artifact = await fake.render(
        'graph LR\nA-->B',
        theme: MermaidTheme.light,
      );
      expect(artifact.svg, contains('<svg'));
      expect(artifact.intrinsicSize, const Size(800, 400));
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.source, 'graph LR\nA-->B');
      expect(fake.calls.single.theme, MermaidTheme.light);
    });

    test('honors svgBuilder override', () async {
      final fake = FakeMermaidRenderer()
        ..svgBuilder = (src) => '<svg data-src="$src"></svg>';
      final artifact = await fake.render('foo', theme: MermaidTheme.dark);
      expect(artifact.svg, '<svg data-src="foo"></svg>');
    });

    test('throws errorToThrow synchronously when set', () async {
      final fake = FakeMermaidRenderer()
        ..errorToThrow = MermaidSyntaxError(
          source: 'x',
          message: 'fake fail',
          stackTrace: StackTrace.current,
        );
      await expectLater(
        () => fake.render('x', theme: MermaidTheme.light),
        throwsA(isA<MermaidSyntaxError>()),
      );
    });

    test('respects latency before resolving', () async {
      final fake = FakeMermaidRenderer()
        ..latency = const Duration(milliseconds: 50);
      final stopwatch = Stopwatch()..start();
      await fake.render('x', theme: MermaidTheme.light);
      stopwatch.stop();
      expect(
        stopwatch.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 40)),
      );
    });

    test('isReady reflects simulateNotReady', () {
      final fake = FakeMermaidRenderer();
      expect(fake.isReady, isTrue);
      fake.simulateNotReady = true;
      expect(fake.isReady, isFalse);
    });

    test('version is a non-empty stable string', () {
      final fake = FakeMermaidRenderer();
      expect(fake.version, isNotEmpty);
      expect(FakeMermaidRenderer().version, fake.version);
    });

    test('dispose completes without throwing', () async {
      final fake = FakeMermaidRenderer();
      await expectLater(fake.dispose(), completes);
    });
  });
}
