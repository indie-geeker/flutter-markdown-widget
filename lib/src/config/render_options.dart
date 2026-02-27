// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:markdown/markdown.dart' as md;

import '../core/parser/markdown_parser.dart';

/// Parser mode for markdown rendering.
enum ParserMode {
  /// AST-based parsing (recommended for static content).
  ast,

  /// Incremental parsing (optimized for streaming).
  incremental,
}

/// Configuration for markdown rendering behavior.
@immutable
class RenderOptions {
  /// Creates render options.
  const RenderOptions({
    this.parserMode = ParserMode.ast,
    this.enableLatex = true,
    this.enableCodeHighlight = true,
    this.enableTables = true,
    this.enableTaskLists = true,
    this.enableStrikethrough = true,
    this.enableAutolinks = true,
    this.enableImageLoading = true,
    this.enableVirtualScrolling = true,
    this.selectableText = true,
    this.extensionSet,
    this.customInlineSyntaxes,
    this.customBlockSyntaxes,
    this.parserFactory,
    this.onLinkTap,
    this.onImageTap,
    this.onCodeCopy,
    this.maxImageWidth,
    this.maxImageHeight,
    this.codeBlockMaxHeight,
    this.virtualScrollThreshold = 20,
  });

  /// Default render options.
  static const RenderOptions defaultOptions = RenderOptions();

  /// Parser mode (AST or incremental).
  final ParserMode parserMode;

  /// Whether to enable LaTeX math rendering.
  final bool enableLatex;

  /// Whether to enable code syntax highlighting.
  final bool enableCodeHighlight;

  /// Whether to enable table rendering.
  final bool enableTables;

  /// Whether to enable task list checkboxes.
  final bool enableTaskLists;

  /// Whether to enable strikethrough text.
  final bool enableStrikethrough;

  /// Whether to enable automatic link detection.
  final bool enableAutolinks;

  /// Whether to load and display images.
  final bool enableImageLoading;

  /// Whether to use virtual scrolling for long content.
  final bool enableVirtualScrolling;

  /// Whether text can be selected.
  final bool selectableText;

  /// Optional markdown extension set.
  final md.ExtensionSet? extensionSet;

  /// Custom inline markdown syntaxes.
  final List<md.InlineSyntax>? customInlineSyntaxes;

  /// Custom block markdown syntaxes.
  final List<md.BlockSyntax>? customBlockSyntaxes;

  /// Optional parser factory for swapping parser implementations.
  final MarkdownParser Function(RenderOptions options)? parserFactory;

  /// Callback when a link is tapped.
  final void Function(String url, String? title)? onLinkTap;

  /// Callback when an image is tapped.
  final void Function(String src, String? alt)? onImageTap;

  /// Callback when code is copied.
  final void Function(String code, String? language)? onCodeCopy;

  /// Maximum width for images.
  final double? maxImageWidth;

  /// Maximum height for images.
  final double? maxImageHeight;

  /// Maximum height for code blocks before scrolling.
  final double? codeBlockMaxHeight;

  /// Number of blocks before enabling virtual scrolling.
  final int virtualScrollThreshold;

  /// Creates a copy with optional overrides.
  RenderOptions copyWith({
    ParserMode? parserMode,
    bool? enableLatex,
    bool? enableCodeHighlight,
    bool? enableTables,
    bool? enableTaskLists,
    bool? enableStrikethrough,
    bool? enableAutolinks,
    bool? enableImageLoading,
    bool? enableVirtualScrolling,
    bool? selectableText,
    md.ExtensionSet? extensionSet,
    List<md.InlineSyntax>? customInlineSyntaxes,
    List<md.BlockSyntax>? customBlockSyntaxes,
    MarkdownParser Function(RenderOptions options)? parserFactory,
    void Function(String url, String? title)? onLinkTap,
    void Function(String src, String? alt)? onImageTap,
    void Function(String code, String? language)? onCodeCopy,
    double? maxImageWidth,
    double? maxImageHeight,
    double? codeBlockMaxHeight,
    int? virtualScrollThreshold,
  }) {
    return RenderOptions(
      parserMode: parserMode ?? this.parserMode,
      enableLatex: enableLatex ?? this.enableLatex,
      enableCodeHighlight: enableCodeHighlight ?? this.enableCodeHighlight,
      enableTables: enableTables ?? this.enableTables,
      enableTaskLists: enableTaskLists ?? this.enableTaskLists,
      enableStrikethrough: enableStrikethrough ?? this.enableStrikethrough,
      enableAutolinks: enableAutolinks ?? this.enableAutolinks,
      enableImageLoading: enableImageLoading ?? this.enableImageLoading,
      enableVirtualScrolling:
          enableVirtualScrolling ?? this.enableVirtualScrolling,
      selectableText: selectableText ?? this.selectableText,
      extensionSet: extensionSet ?? this.extensionSet,
      customInlineSyntaxes: customInlineSyntaxes ?? this.customInlineSyntaxes,
      customBlockSyntaxes: customBlockSyntaxes ?? this.customBlockSyntaxes,
      parserFactory: parserFactory ?? this.parserFactory,
      onLinkTap: onLinkTap ?? this.onLinkTap,
      onImageTap: onImageTap ?? this.onImageTap,
      onCodeCopy: onCodeCopy ?? this.onCodeCopy,
      maxImageWidth: maxImageWidth ?? this.maxImageWidth,
      maxImageHeight: maxImageHeight ?? this.maxImageHeight,
      codeBlockMaxHeight: codeBlockMaxHeight ?? this.codeBlockMaxHeight,
      virtualScrollThreshold:
          virtualScrollThreshold ?? this.virtualScrollThreshold,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenderOptions &&
          runtimeType == other.runtimeType &&
          parserMode == other.parserMode &&
          enableLatex == other.enableLatex &&
          enableCodeHighlight == other.enableCodeHighlight &&
          enableTables == other.enableTables &&
          enableTaskLists == other.enableTaskLists &&
          enableStrikethrough == other.enableStrikethrough &&
          enableAutolinks == other.enableAutolinks &&
          enableImageLoading == other.enableImageLoading &&
          enableVirtualScrolling == other.enableVirtualScrolling &&
          selectableText == other.selectableText &&
          extensionSet == other.extensionSet &&
          listEquals(customInlineSyntaxes, other.customInlineSyntaxes) &&
          listEquals(customBlockSyntaxes, other.customBlockSyntaxes) &&
          parserFactory == other.parserFactory &&
          onLinkTap == other.onLinkTap &&
          onImageTap == other.onImageTap &&
          onCodeCopy == other.onCodeCopy &&
          maxImageWidth == other.maxImageWidth &&
          maxImageHeight == other.maxImageHeight &&
          codeBlockMaxHeight == other.codeBlockMaxHeight &&
          virtualScrollThreshold == other.virtualScrollThreshold;

  @override
  int get hashCode => Object.hashAll([
    parserMode,
    enableLatex,
    enableCodeHighlight,
    enableTables,
    enableTaskLists,
    enableStrikethrough,
    enableAutolinks,
    enableImageLoading,
    enableVirtualScrolling,
    selectableText,
    extensionSet,
    Object.hashAll(customInlineSyntaxes ?? const []),
    Object.hashAll(customBlockSyntaxes ?? const []),
    parserFactory,
    onLinkTap,
    onImageTap,
    onCodeCopy,
    maxImageWidth,
    maxImageHeight,
    codeBlockMaxHeight,
    virtualScrollThreshold,
  ]);
}
