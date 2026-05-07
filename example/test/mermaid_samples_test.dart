// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_markdown_widget_example/data/mermaid_samples.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MermaidSamples', () {
    test('static showcase contains multiple Mermaid fences', () {
      expect(_mermaidFenceCount(MermaidSamples.staticShowcase),
          greaterThanOrEqualTo(2));
    });

    test('streaming showcase contains one closed Mermaid fence', () {
      expect(_mermaidFenceCount(MermaidSamples.streamingShowcase), 1);
      expect(
          MermaidSamples.streamingShowcase.trimRight().endsWith('```'), isTrue);
    });

    test('error showcase contains one Mermaid fence', () {
      expect(_mermaidFenceCount(MermaidSamples.errorShowcase), 1);
    });
  });
}

int _mermaidFenceCount(String source) {
  return RegExp(r'```mermaid').allMatches(source).length;
}
