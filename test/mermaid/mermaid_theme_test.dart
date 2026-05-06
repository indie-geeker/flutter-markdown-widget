// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MermaidTheme', () {
    test('exposes all five canonical values', () {
      expect(MermaidTheme.values, hasLength(5));
      expect(
        MermaidTheme.values,
        containsAll([
          MermaidTheme.auto,
          MermaidTheme.light,
          MermaidTheme.dark,
          MermaidTheme.neutral,
          MermaidTheme.forest,
        ]),
      );
    });

    test('resolveAuto returns dark for Brightness.dark', () {
      expect(MermaidTheme.auto.resolveAuto(Brightness.dark), MermaidTheme.dark);
    });

    test('resolveAuto returns light for Brightness.light', () {
      expect(
        MermaidTheme.auto.resolveAuto(Brightness.light),
        MermaidTheme.light,
      );
    });

    test('resolveAuto returns self for non-auto themes', () {
      expect(
        MermaidTheme.forest.resolveAuto(Brightness.light),
        MermaidTheme.forest,
      );
      expect(
        MermaidTheme.neutral.resolveAuto(Brightness.dark),
        MermaidTheme.neutral,
      );
    });
  });
}
