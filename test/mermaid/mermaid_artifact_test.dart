// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_artifact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MermaidArtifact', () {
    test('stores svg and intrinsicSize', () {
      const svg = '<svg viewBox="0 0 100 50"></svg>';
      final artifact = MermaidArtifact(
        svg: svg,
        intrinsicSize: const Size(100, 50),
      );
      expect(artifact.svg, svg);
      expect(artifact.intrinsicSize, const Size(100, 50));
    });

    test('intrinsicSize is optional', () {
      final artifact = MermaidArtifact(svg: '<svg></svg>');
      expect(artifact.intrinsicSize, isNull);
    });

    test('parseViewBox extracts width and height', () {
      const svg = '<svg viewBox="0 0 800 400" width="100"></svg>';
      expect(MermaidArtifact.parseViewBox(svg), const Size(800, 400));
    });

    test('parseViewBox tolerates whitespace and decimal values', () {
      const svg = '<svg  viewBox="  0   0   123.5   45.25  "></svg>';
      expect(MermaidArtifact.parseViewBox(svg), const Size(123.5, 45.25));
    });

    test('parseViewBox returns null when viewBox is missing', () {
      expect(MermaidArtifact.parseViewBox('<svg></svg>'), isNull);
    });

    test('parseViewBox returns null on malformed values', () {
      expect(
        MermaidArtifact.parseViewBox('<svg viewBox="0 0 abc def"></svg>'),
        isNull,
      );
    });

    test('parseViewBox returns null when value count is wrong', () {
      expect(
        MermaidArtifact.parseViewBox('<svg viewBox="0 0 100"></svg>'),
        isNull,
      );
    });

    test('equality is based on svg and intrinsicSize', () {
      final a = MermaidArtifact(svg: '<svg/>', intrinsicSize: const Size(1, 2));
      final b = MermaidArtifact(svg: '<svg/>', intrinsicSize: const Size(1, 2));
      final c = MermaidArtifact(
        svg: '<svg/>',
        intrinsicSize: const Size(2, 1),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('rasterPng defaults to null', () {
      final artifact = MermaidArtifact(svg: '<svg/>');
      expect(artifact.rasterPng, isNull);
    });

    test('equality compares rasterPng byte-for-byte', () {
      final png1 = Uint8List.fromList(<int>[1, 2, 3]);
      final png2 = Uint8List.fromList(<int>[1, 2, 3]);
      final png3 = Uint8List.fromList(<int>[1, 2, 4]);
      final a = MermaidArtifact(svg: '<svg/>', rasterPng: png1);
      final b = MermaidArtifact(svg: '<svg/>', rasterPng: png2);
      final c = MermaidArtifact(svg: '<svg/>', rasterPng: png3);
      final d = MermaidArtifact(svg: '<svg/>');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });
  });
}
