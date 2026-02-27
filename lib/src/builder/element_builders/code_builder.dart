// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../style/markdown_theme.dart';
import '../../widgets/components/code_block_view.dart';
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
    return CodeBlockView(
      code: code,
      language: lang,
      showLineNumbers: showLineNumbers,
      showCopyButton: showCopyButton,
      showLanguageLabel: showLanguageLabel,
      maxHeight: maxHeight,
      onCopy: onCopy != null ? () => onCopy(code) : null,
    );
  }
}
