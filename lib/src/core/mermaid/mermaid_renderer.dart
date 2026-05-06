// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'mermaid_artifact.dart';
import 'mermaid_error.dart';
import 'mermaid_theme.dart';

/// Renders Mermaid source into an SVG artifact.
///
/// Implementations must be deterministic: the same `(source, theme, version)`
/// triple must always produce equivalent SVG output, so cache entries stay
/// valid for the lifetime of [version].
@experimental
abstract class MermaidRenderer {
  /// Renders [source] under [theme]. Implementations should:
  /// - throw [MermaidSyntaxError] for Mermaid parse errors
  /// - throw [MermaidInitializationError] when the engine could not be prepared
  /// - allow the caller to apply a timeout via `Future.timeout`
  Future<MermaidArtifact> render(
    String source, {
    required MermaidTheme theme,
  });

  /// Whether the renderer is ready to serve requests.
  bool get isReady;

  /// Stable identifier for the renderer and underlying Mermaid version.
  String get version;

  /// Releases held resources.
  Future<void> dispose();
}
