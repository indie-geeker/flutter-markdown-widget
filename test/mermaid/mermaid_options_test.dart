// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_cache.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_options.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_theme.dart';
import 'package:flutter_markdown_widget/src/testing/fake_mermaid_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MermaidOptions defaults', () {
    test('renderer is null, theme is auto, fullscreen enabled', () {
      const opts = MermaidOptions();
      expect(opts.renderer, isNull);
      expect(opts.theme, MermaidTheme.auto);
      expect(opts.enableTapToFullscreen, isTrue);
      expect(opts.renderTimeout, const Duration(seconds: 5));
      expect(opts.cacheCapacity, 32);
      expect(opts.cache, isNull);
      expect(opts.onError, isNull);
      expect(opts.fullscreenBuilder, isNull);
      expect(opts.errorBuilder, isNull);
    });
  });

  group('MermaidOptions copyWith', () {
    test('overrides specific fields', () {
      const original = MermaidOptions();
      final renderer = FakeMermaidRenderer();
      final cache = MermaidCache(capacity: 8);
      final updated = original.copyWith(
        renderer: renderer,
        theme: MermaidTheme.forest,
        enableTapToFullscreen: false,
        renderTimeout: const Duration(seconds: 10),
        cacheCapacity: 64,
        cache: cache,
      );
      expect(updated.renderer, renderer);
      expect(updated.theme, MermaidTheme.forest);
      expect(updated.enableTapToFullscreen, isFalse);
      expect(updated.renderTimeout, const Duration(seconds: 10));
      expect(updated.cacheCapacity, 64);
      expect(updated.cache, cache);
    });

    test('preserves unspecified fields', () {
      final original = const MermaidOptions(
        theme: MermaidTheme.dark,
        cacheCapacity: 16,
      );
      final updated = original.copyWith(theme: MermaidTheme.light);
      expect(updated.theme, MermaidTheme.light);
      expect(updated.cacheCapacity, 16);
    });
  });

  group('MermaidOptions equality', () {
    test('two default instances are equal', () {
      expect(const MermaidOptions(), const MermaidOptions());
    });

    test('different theme produces different equality', () {
      expect(
        const MermaidOptions(theme: MermaidTheme.light),
        isNot(const MermaidOptions(theme: MermaidTheme.dark)),
      );
    });
  });
}
