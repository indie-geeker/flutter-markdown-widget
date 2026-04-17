// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_markdown_widget/src/builder/element_builders/formula_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cleanLatex returns identical string for repeated input',
      (tester) async {
    FormulaBuilder.debugClearCleanCache();

    final a = FormulaBuilder.debugCleanLatex(r'$$ a \n  b \n c $$', isBlock: true);
    final b = FormulaBuilder.debugCleanLatex(r'$$ a \n  b \n c $$', isBlock: true);

    // Same string value…
    expect(a, b);
    // …AND same object identity (cache hit).
    expect(identical(a, b), isTrue);
  });

  testWidgets('cleanLatex strips \$\$ delimiters and collapses newlines for block',
      (tester) async {
    FormulaBuilder.debugClearCleanCache();

    final cleaned =
        FormulaBuilder.debugCleanLatex('\$\$\nx = 1\n\$\$', isBlock: true);

    expect(cleaned, 'x = 1');
  });

  testWidgets('cleanLatex strips \$ delimiters for inline',
      (tester) async {
    FormulaBuilder.debugClearCleanCache();

    final cleaned =
        FormulaBuilder.debugCleanLatex(r'$x^2$', isBlock: false);

    expect(cleaned, 'x^2');
  });
}
