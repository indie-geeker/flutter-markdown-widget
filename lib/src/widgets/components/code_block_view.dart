// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../style/markdown_theme.dart';

/// Widget for displaying code blocks with syntax highlighting.
class CodeBlockView extends StatefulWidget {
  /// Creates a code block view.
  const CodeBlockView({
    super.key,
    required this.code,
    this.language,
    this.showLineNumbers = true,
    this.showCopyButton = true,
    this.showLanguageLabel = true,
    this.maxHeight,
    this.onCopy,
  });

  /// The code to display.
  final String code;

  /// Programming language for syntax highlighting.
  final String? language;

  /// Whether to show line numbers.
  final bool showLineNumbers;

  /// Whether to show copy button.
  final bool showCopyButton;

  /// Whether to show language label.
  final bool showLanguageLabel;

  /// Maximum height before scrolling.
  final double? maxHeight;

  /// Callback when code is copied.
  final VoidCallback? onCopy;

  @override
  State<CodeBlockView> createState() => _CodeBlockViewState();
}

class _CodeBlockViewState extends State<CodeBlockView> {
  bool _copied = false;

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    widget.onCopy?.call();

    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = MarkdownThemeProvider.maybeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = theme?.codeBlockBackground ??
        (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5));
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final codeStyle = theme?.codeBlockStyle ??
        const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.5,
        );

    final lines = widget.code.split('\n');

    return Container(
      margin: EdgeInsets.only(bottom: theme?.blockSpacing ?? 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: theme?.codeBlockBorderRadius ?? BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          if (widget.showLanguageLabel || widget.showCopyButton)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.showLanguageLabel)
                    Text(
                      (widget.language?.isNotEmpty == true
                              ? widget.language!
                              : 'code')
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (widget.showCopyButton) _buildCopyButton(),
                ],
              ),
            ),
          // Code content
          _buildCodeContent(lines, codeStyle),
        ],
      ),
    );
  }

  Widget _buildCopyButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copyCode,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _copied ? Icons.check : Icons.copy,
                size: 16,
                color: _copied ? Colors.green : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                _copied ? 'Copied!' : 'Copy',
                style: TextStyle(
                  fontSize: 12,
                  color: _copied ? Colors.green : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeContent(List<String> lines, TextStyle codeStyle) {
    Widget content;

    if (widget.showLineNumbers) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line numbers
            Container(
              padding: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  lines.length,
                  (i) => Text(
                    '${i + 1}',
                    style: codeStyle.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Code
            SelectableText(
              _sanitizeUtf16(lines.join('\n')),
              style: codeStyle,
            ),
          ],
        ),
      );
    } else {
      content = SelectableText(
        _sanitizeUtf16(lines.join('\n')),
        style: codeStyle,
      );
    }

    Widget scrollable = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: content,
    );

    if (widget.maxHeight != null) {
      scrollable = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: SingleChildScrollView(child: scrollable),
      );
    }

    return scrollable;
  }

  /// Sanitizes a string to ensure it's well-formed UTF-16.
  String _sanitizeUtf16(String text) {
    if (text.isEmpty) return text;
    
    final lastCodeUnit = text.codeUnitAt(text.length - 1);
    if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
      return text.substring(0, text.length - 1);
    }
    
    final firstCodeUnit = text.codeUnitAt(0);
    if (firstCodeUnit >= 0xDC00 && firstCodeUnit <= 0xDFFF) {
      return text.substring(1);
    }
    
    return text;
  }
}
