// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../style/markdown_theme.dart';

/// Widget for displaying LaTeX formulas.
class FormulaView extends StatelessWidget {
  /// Creates a formula view.
  const FormulaView({
    super.key,
    required this.latex,
    this.isBlock = false,
    this.textStyle,
  });

  /// LaTeX source.
  final String latex;

  /// Whether this is a block-level formula.
  final bool isBlock;

  /// Optional text style override.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = MarkdownThemeProvider.maybeOf(context);
    final defaultStyle = theme?.textStyle ?? DefaultTextStyle.of(context).style;
    final effectiveStyle = textStyle ?? defaultStyle;

    String cleanLatex = latex.trim();
    // Remove surrounding $$ or $
    if (cleanLatex.startsWith(r'$$')) {
      cleanLatex = cleanLatex.substring(2);
      if (cleanLatex.endsWith(r'$$')) {
        cleanLatex = cleanLatex.substring(0, cleanLatex.length - 2);
      }
    } else if (cleanLatex.startsWith(r'$')) {
      cleanLatex = cleanLatex.substring(1);
      if (cleanLatex.endsWith(r'$')) {
        cleanLatex = cleanLatex.substring(0, cleanLatex.length - 1);
      }
    }
    cleanLatex = cleanLatex.trim();

    try {
      final mathWidget = Math.tex(
        cleanLatex,
        textStyle: effectiveStyle,
        mathStyle: isBlock ? MathStyle.display : MathStyle.text,
        onErrorFallback: (error) => _buildError(context, cleanLatex, error),
      );

      if (isBlock) {
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: theme?.blockSpacing ?? 16,
          ),
          child: Center(child: mathWidget),
        );
      }

      return mathWidget;
    } catch (e) {
      return _buildError(context, cleanLatex, e);
    }
  }

  Widget _buildError(BuildContext context, String latex, dynamic error) {
    final errorColor = Theme.of(context).colorScheme.error;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        latex,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: errorColor,
        ),
      ),
    );
  }
}
