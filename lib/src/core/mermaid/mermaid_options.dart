// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'mermaid_artifact.dart';
import 'mermaid_cache.dart';
import 'mermaid_error.dart';
import 'mermaid_renderer.dart';
import 'mermaid_theme.dart';

/// Public configuration for Mermaid rendering inside a `MarkdownWidget`.
@immutable
class MermaidOptions {
  const MermaidOptions({
    this.renderer,
    this.theme = MermaidTheme.auto,
    this.enableTapToFullscreen = true,
    this.renderTimeout = const Duration(seconds: 5),
    this.cacheCapacity = 32,
    this.cache,
    this.onError,
    this.fullscreenBuilder,
    this.errorBuilder,
  });

  /// The renderer that converts Mermaid source into SVG.
  @experimental
  final MermaidRenderer? renderer;

  /// Theme passed to the renderer.
  final MermaidTheme theme;

  /// When true, tapping a rendered diagram opens fullscreen.
  final bool enableTapToFullscreen;

  /// Maximum time to wait for a single render.
  final Duration renderTimeout;

  /// Default LRU capacity when [cache] is not explicitly provided.
  final int cacheCapacity;

  /// Optional shared cache instance.
  final MermaidCache? cache;

  /// Diagnostics hook invoked for every [MermaidError].
  final void Function(MermaidError error)? onError;

  /// Optional override for fullscreen presentation.
  final Widget Function(BuildContext context, MermaidArtifact artifact)?
  fullscreenBuilder;

  /// Optional override for inline error presentation.
  final Widget Function(BuildContext context, MermaidErrorContext context_)?
  errorBuilder;

  MermaidOptions copyWith({
    MermaidRenderer? renderer,
    MermaidTheme? theme,
    bool? enableTapToFullscreen,
    Duration? renderTimeout,
    int? cacheCapacity,
    MermaidCache? cache,
    void Function(MermaidError error)? onError,
    Widget Function(BuildContext, MermaidArtifact)? fullscreenBuilder,
    Widget Function(BuildContext, MermaidErrorContext)? errorBuilder,
  }) {
    return MermaidOptions(
      renderer: renderer ?? this.renderer,
      theme: theme ?? this.theme,
      enableTapToFullscreen:
          enableTapToFullscreen ?? this.enableTapToFullscreen,
      renderTimeout: renderTimeout ?? this.renderTimeout,
      cacheCapacity: cacheCapacity ?? this.cacheCapacity,
      cache: cache ?? this.cache,
      onError: onError ?? this.onError,
      fullscreenBuilder: fullscreenBuilder ?? this.fullscreenBuilder,
      errorBuilder: errorBuilder ?? this.errorBuilder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MermaidOptions &&
          renderer == other.renderer &&
          theme == other.theme &&
          enableTapToFullscreen == other.enableTapToFullscreen &&
          renderTimeout == other.renderTimeout &&
          cacheCapacity == other.cacheCapacity &&
          cache == other.cache &&
          onError == other.onError &&
          fullscreenBuilder == other.fullscreenBuilder &&
          errorBuilder == other.errorBuilder;

  @override
  int get hashCode => Object.hash(
    renderer,
    theme,
    enableTapToFullscreen,
    renderTimeout,
    cacheCapacity,
    cache,
    onError,
    fullscreenBuilder,
    errorBuilder,
  );
}
