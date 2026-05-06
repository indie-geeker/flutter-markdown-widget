// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Visual theme requested for a Mermaid diagram.
///
/// [auto] resolves to [light] or [dark] based on the ambient brightness. The
/// other values are passed through to the underlying renderer.
enum MermaidTheme {
  /// Track the ambient [Brightness].
  auto,

  /// Light background, dark foreground.
  light,

  /// Dark background, light foreground.
  dark,

  /// Mermaid's neutral palette.
  neutral,

  /// Mermaid's forest palette.
  forest;

  /// Resolves [auto] to a concrete theme based on ambient brightness.
  ///
  /// Non-auto values return themselves unchanged.
  MermaidTheme resolveAuto(Brightness brightness) {
    if (this != MermaidTheme.auto) return this;
    return brightness == Brightness.dark
        ? MermaidTheme.dark
        : MermaidTheme.light;
  }
}
