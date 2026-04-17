// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../style/markdown_theme.dart';
import '../content_builder.dart';

/// Builder for LaTeX formula elements.
class FormulaBuilder extends ElementBuilder {
  /// Creates a formula builder.
  FormulaBuilder({this.isBlock = false});

  /// Whether this is a block-level formula.
  final bool isBlock;

  static final RegExp _blockNewlineRun = RegExp(r'\n\s*');
  static final Map<String, String> _cleanCache = <String, String>{};

  /// Visible for tests — do not use in production code.
  @visibleForTesting
  static String debugCleanLatex(String content, {required bool isBlock}) =>
      _cleanLatex(content, isBlock: isBlock);

  /// Visible for tests — do not use in production code.
  @visibleForTesting
  static void debugClearCleanCache() => _cleanCache.clear();

  static String _cleanLatex(String content, {required bool isBlock}) {
    final cacheKey = isBlock ? 'B:$content' : 'I:$content';
    final cached = _cleanCache[cacheKey];
    if (cached != null) return cached;

    String latex = content.trim();
    if (latex.startsWith(r'$$')) {
      latex = latex.substring(2);
      if (latex.endsWith(r'$$')) {
        latex = latex.substring(0, latex.length - 2);
      }
    } else if (latex.startsWith(r'$')) {
      latex = latex.substring(1);
      if (latex.endsWith(r'$')) {
        latex = latex.substring(0, latex.length - 1);
      }
    }
    latex = latex.trim();

    if (isBlock) {
      latex = latex.replaceAll(_blockNewlineRun, ' ');
    }

    _cleanCache[cacheKey] = latex;
    return latex;
  }

  @override
  Widget build(BuildContext context, String content, MarkdownTheme theme) {
    final latex = _cleanLatex(content, isBlock: isBlock);

    final textColor = theme.textStyle?.color ??
        Theme.of(context).textTheme.bodyMedium?.color;

    try {
      final mathWidget = Math.tex(
        latex,
        textStyle: TextStyle(
          fontSize: isBlock ? 18 : (theme.textStyle?.fontSize ?? 16),
          color: textColor,
        ),
        mathStyle: isBlock ? MathStyle.display : MathStyle.text,
        onErrorFallback: (error) => _buildErrorWidget(context, latex, error),
      );

      if (isBlock) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: theme.blockSpacing ?? 16,
          ),
          child: Center(child: mathWidget),
        );
      }

      return mathWidget;
    } catch (e) {
      return _buildErrorWidget(context, latex, e);
    }
  }

  Widget _buildErrorWidget(BuildContext context, String latex, dynamic error) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: errorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 16, color: errorColor),
              const SizedBox(width: 4),
              Text(
                'LaTeX Error',
                style: TextStyle(
                  color: errorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            latex,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
