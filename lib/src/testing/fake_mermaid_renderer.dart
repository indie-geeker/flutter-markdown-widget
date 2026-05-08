// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../core/mermaid/mermaid_artifact.dart';
import '../core/mermaid/mermaid_renderer.dart';
import '../core/mermaid/mermaid_theme.dart';

/// Records a single [FakeMermaidRenderer.render] invocation.
@immutable
class MermaidRenderCall {
  const MermaidRenderCall({required this.source, required this.theme});

  /// Mermaid source passed to [FakeMermaidRenderer.render].
  final String source;

  /// Theme passed to [FakeMermaidRenderer.render].
  final MermaidTheme theme;
}

/// Test double for [MermaidRenderer].
class FakeMermaidRenderer implements MermaidRenderer {
  /// Synthetic delay applied before each [render] resolves.
  Duration latency = Duration.zero;

  /// When non-null, [render] throws this object instead of resolving.
  Object? errorToThrow;

  /// When true, [isReady] returns false.
  bool simulateNotReady = false;

  /// Optional source-to-SVG override. Default produces a minimal valid SVG.
  String Function(String source)? svgBuilder;

  /// Optional source-to-PNG override. When set, the artifact returned by
  /// [render] carries the produced bytes in [MermaidArtifact.rasterPng];
  /// otherwise `rasterPng` stays null and consumers fall back to the SVG path.
  Uint8List? Function(String source)? pngBuilder;

  /// Recorded calls in order.
  final List<MermaidRenderCall> calls = <MermaidRenderCall>[];

  @override
  Future<MermaidArtifact> render(
    String source, {
    required MermaidTheme theme,
  }) async {
    calls.add(MermaidRenderCall(source: source, theme: theme));
    if (latency != Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    final svg =
        svgBuilder?.call(source) ??
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 400"><rect width="800" height="400" fill="#eee"/></svg>';
    return MermaidArtifact(
      svg: svg,
      intrinsicSize: const Size(800, 400),
      rasterPng: pngBuilder?.call(source),
    );
  }

  @override
  bool get isReady => !simulateNotReady;

  @override
  String get version => 'fake-1.0.0';

  @override
  Future<void> dispose() async {}
}
