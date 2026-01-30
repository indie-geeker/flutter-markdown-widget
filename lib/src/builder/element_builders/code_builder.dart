// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../style/markdown_theme.dart';
import '../content_builder.dart';

/// Builder for code block elements.
class CodeBlockBuilder extends ElementBuilder {
  @override
  Widget build(BuildContext context, String content, MarkdownTheme theme) {
    return buildWithOptions(context, content, null, theme);
  }

  /// Builds a code block with additional options.
  Widget buildWithOptions(
    BuildContext context,
    String content,
    String? language,
    MarkdownTheme theme, {
    void Function(String code)? onCopy,
    bool showLineNumbers = true,
    bool showLanguageLabel = true,
    bool showCopyButton = true,
    double? maxHeight,
  }) {
    // Extract language and code content
    String code = content;
    String? lang = language;

    // Parse code fence
    final fenceMatch = RegExp(r'^(`{3,}|~{3,})(\w*)\n?([\s\S]*?)\1?$', dotAll: true)
        .firstMatch(content.trim());
    if (fenceMatch != null) {
      lang ??= fenceMatch.group(2);
      code = fenceMatch.group(3) ?? content;
    }

    // Clean up trailing/leading whitespace
    code = code.trim();
    final lines = code.split('\n');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = theme.codeBlockBackground ??
        (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5));
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      margin: EdgeInsets.only(bottom: theme.blockSpacing ?? 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: theme.codeBlockBorderRadius ?? BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language label and copy button
          if (showLanguageLabel || showCopyButton)
            _buildHeader(
              context,
              lang,
              code,
              showLanguageLabel: showLanguageLabel,
              showCopyButton: showCopyButton,
              onCopy: onCopy,
              borderColor: borderColor,
            ),
          // Code content
          _buildCodeContent(
            context,
            lines,
            theme,
            showLineNumbers: showLineNumbers,
            maxHeight: maxHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String? language,
    String code, {
    required bool showLanguageLabel,
    required bool showCopyButton,
    void Function(String code)? onCopy,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Language label
          if (showLanguageLabel)
            Text(
              (language?.isNotEmpty == true ? language! : 'code').toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            )
          else
            const SizedBox.shrink(),
          // Copy button
          if (showCopyButton)
            _CopyButton(
              code: code,
              onCopy: onCopy,
            ),
        ],
      ),
    );
  }

  Widget _buildCodeContent(
    BuildContext context,
    List<String> lines,
    MarkdownTheme theme, {
    required bool showLineNumbers,
    double? maxHeight,
  }) {
    final codeStyle = theme.codeBlockStyle ?? const TextStyle(
      fontFamily: 'monospace',
      fontSize: 14,
      height: 1.5,
    );

    Widget codeWidget;

    if (showLineNumbers) {
      codeWidget = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line numbers
            Container(
              padding: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  lines.length,
                  (i) => Text(
                    '${i + 1}',
                    style: codeStyle.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Code lines
            SelectableText(
              _sanitizeUtf16(lines.join('\n')),
              style: codeStyle,
            ),
          ],
        ),
      );
    } else {
      codeWidget = SelectableText(
        _sanitizeUtf16(lines.join('\n')),
        style: codeStyle,
      );
    }

    Widget content = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: theme.codeBlockPadding ?? const EdgeInsets.all(16),
      child: codeWidget,
    );

    if (maxHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: content,
        ),
      );
    }

    return content;
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

class _CopyButton extends StatefulWidget {
  const _CopyButton({
    required this.code,
    this.onCopy,
  });

  final String code;
  final void Function(String code)? onCopy;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    widget.onCopy?.call(widget.code);

    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleCopy,
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
}
