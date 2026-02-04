// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:markdown/markdown.dart' as md;

import 'content_block.dart';

/// Metadata map key for AST-derived data.
const String kAstDataKey = '_ast';

/// Metadata wrapper for AST-derived content.
class AstBlockData {
  const AstBlockData({
    this.inlineNodes,
    this.children,
    this.listData,
    this.tableData,
    this.imageAlt,
    this.imageSrc,
    this.attributes,
  });

  /// Inline nodes for paragraphs/headings/list items.
  final List<md.Node>? inlineNodes;

  /// Child blocks for containers like blockquote or list items.
  final List<ContentBlock>? children;

  /// List-specific data.
  final AstListData? listData;

  /// Table-specific data.
  final AstTableData? tableData;

  /// Image metadata.
  final String? imageAlt;
  final String? imageSrc;

  /// Attributes for custom elements.
  final Map<String, String>? attributes;
}

/// List data parsed from AST.
class AstListData {
  const AstListData({required this.ordered, required this.items, this.start});

  final bool ordered;
  final int? start;
  final List<AstListItem> items;
}

/// List item data.
class AstListItem {
  const AstListItem({
    required this.inlineNodes,
    this.checked,
    this.children = const [],
  });

  final List<md.Node> inlineNodes;
  final bool? checked;
  final List<ContentBlock> children;
}

/// Table alignment for a column.
enum AstTableAlignment { left, center, right }

/// Table data parsed from AST.
class AstTableData {
  const AstTableData({
    required this.headers,
    required this.alignments,
    required this.rows,
  });

  final List<List<md.Node>> headers;
  final List<AstTableAlignment> alignments;
  final List<List<List<md.Node>>> rows;
}
