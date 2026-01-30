// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../style/markdown_theme.dart';
import '../content_builder.dart';

/// Builder for table elements.
class TableNodeBuilder extends ElementBuilder {
  @override
  Widget build(BuildContext context, String content, MarkdownTheme theme) {
    final parsed = _parseTable(content);
    if (parsed == null) {
      return const SizedBox.shrink();
    }

    final (headers, alignments, rows) = parsed;

    return Container(
      margin: EdgeInsets.only(bottom: theme.blockSpacing ?? 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(
            color: theme.tableBorderColor ?? Colors.grey,
            borderRadius: BorderRadius.circular(4),
          ),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            // Header row
            TableRow(
              decoration: BoxDecoration(
                color: theme.tableHeaderColor,
              ),
              children: headers.asMap().entries.map((entry) {
                return _buildCell(
                  entry.value,
                  theme,
                  isHeader: true,
                  alignment: alignments[entry.key],
                );
              }).toList(),
            ),
            // Data rows
            ...rows.map((row) {
              return TableRow(
                children: row.asMap().entries.map((entry) {
                  return _buildCell(
                    entry.value,
                    theme,
                    alignment: entry.key < alignments.length
                        ? alignments[entry.key]
                        : TextAlign.left,
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(
    String content,
    MarkdownTheme theme, {
    bool isHeader = false,
    TextAlign alignment = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SelectableText(
        _sanitizeUtf16(content.trim()),
        style: isHeader
            ? theme.tableStyle?.copyWith(fontWeight: FontWeight.bold)
            : theme.tableStyle,
        textAlign: alignment,
      ),
    );
  }

  /// Sanitizes a string to ensure it's well-formed UTF-16.
  String _sanitizeUtf16(String text) {
    if (text.isEmpty) return text;
    
    // Check if the last character is a high surrogate without a low surrogate
    final lastCodeUnit = text.codeUnitAt(text.length - 1);
    if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
      return text.substring(0, text.length - 1);
    }
    
    // Check if the first character is a lone low surrogate
    final firstCodeUnit = text.codeUnitAt(0);
    if (firstCodeUnit >= 0xDC00 && firstCodeUnit <= 0xDFFF) {
      return text.substring(1);
    }
    
    return text;
  }

  /// Parses a markdown table string.
  ///
  /// Returns (headers, alignments, rows) or null if parsing fails.
  (List<String>, List<TextAlign>, List<List<String>>)? _parseTable(
    String content,
  ) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 2) return null;

    // Parse header row
    final headers = _parseRow(lines[0]);
    if (headers.isEmpty) return null;

    // Parse alignment row
    List<TextAlign> alignments = [];
    if (lines.length > 1 && _isAlignmentRow(lines[1])) {
      alignments = _parseAlignments(lines[1]);
    }

    // Ensure alignments match header count
    while (alignments.length < headers.length) {
      alignments.add(TextAlign.left);
    }

    // Parse data rows
    final rows = <List<String>>[];
    final startIndex = alignments.isNotEmpty ? 2 : 1;
    for (int i = startIndex; i < lines.length; i++) {
      final row = _parseRow(lines[i]);
      if (row.isNotEmpty) {
        // Pad row to match header count
        while (row.length < headers.length) {
          row.add('');
        }
        rows.add(row);
      }
    }

    return (headers, alignments, rows);
  }

  List<String> _parseRow(String row) {
    // Remove leading/trailing pipes and split
    String cleaned = row.trim();
    if (cleaned.startsWith('|')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.endsWith('|')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }

    return cleaned.split('|').map((cell) => cell.trim()).toList();
  }

  bool _isAlignmentRow(String row) {
    final cells = _parseRow(row);
    return cells.every((cell) {
      final trimmed = cell.trim();
      return RegExp(r'^:?-+:?$').hasMatch(trimmed);
    });
  }

  List<TextAlign> _parseAlignments(String row) {
    final cells = _parseRow(row);
    return cells.map((cell) {
      final trimmed = cell.trim();
      if (trimmed.startsWith(':') && trimmed.endsWith(':')) {
        return TextAlign.center;
      } else if (trimmed.endsWith(':')) {
        return TextAlign.right;
      }
      return TextAlign.left;
    }).toList();
  }
}
