// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Output of a successful Mermaid render.
@immutable
class MermaidArtifact {
  /// Creates an artifact with raw SVG payload and an optional intrinsic size.
  const MermaidArtifact({required this.svg, this.intrinsicSize});

  /// Raw SVG XML.
  final String svg;

  /// Intrinsic width/height parsed from the SVG `viewBox`, when available.
  final Size? intrinsicSize;

  /// Parses `<svg ... viewBox="x y w h" ...>` and returns `Size(w, h)`.
  ///
  /// Returns null when the SVG has no valid four-value `viewBox`.
  static Size? parseViewBox(String svg) {
    final match = _viewBoxPattern.firstMatch(svg);
    if (match == null) return null;
    final tokens = match
        .group(1)!
        .trim()
        .split(_whitespacePattern)
        .where((s) => s.isNotEmpty)
        .toList();
    if (tokens.length != 4) return null;
    final width = double.tryParse(tokens[2]);
    final height = double.tryParse(tokens[3]);
    if (width == null || height == null) return null;
    return Size(width, height);
  }

  static final RegExp _viewBoxPattern = RegExp(
    r'viewBox\s*=\s*"([^"]*)"',
    caseSensitive: false,
  );
  static final RegExp _whitespacePattern = RegExp(r'\s+');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MermaidArtifact &&
          svg == other.svg &&
          intrinsicSize == other.intrinsicSize;

  @override
  int get hashCode => Object.hash(svg, intrinsicSize);
}
