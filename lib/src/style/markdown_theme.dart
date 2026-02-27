// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Theme data for markdown styling.
///
/// Defines text styles, colors, and spacing for all
/// markdown elements.
@immutable
class MarkdownTheme {
  /// Creates a markdown theme.
  const MarkdownTheme({
    this.textStyle,
    this.h1Style,
    this.h2Style,
    this.h3Style,
    this.h4Style,
    this.h5Style,
    this.h6Style,
    this.codeStyle,
    this.codeBlockStyle,
    this.blockquoteStyle,
    this.linkStyle,
    this.listBulletStyle,
    this.tableStyle,
    this.tableBorderColor,
    this.tableHeaderColor,
    this.codeBlockBackground,
    this.codeBlockBorderRadius,
    this.blockquoteBorderColor,
    this.blockquoteBackground,
    this.horizontalRuleColor,
    this.paragraphSpacing,
    this.headingSpacing,
    this.blockSpacing,
    this.listIndent,
    this.codeBlockPadding,
    this.blockquotePadding,
  });

  /// Creates a theme from Flutter ThemeData.
  factory MarkdownTheme.fromTheme(ThemeData theme) {
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return MarkdownTheme(
      textStyle: textTheme.bodyMedium,
      h1Style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
      h2Style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      h3Style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      h4Style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      h5Style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      h6Style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      codeStyle: TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLow,
      ),
      codeBlockStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        height: 1.5,
      ),
      blockquoteStyle: textTheme.bodyMedium?.copyWith(
        fontStyle: FontStyle.italic,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      linkStyle: TextStyle(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      listBulletStyle: textTheme.bodyMedium,
      tableStyle: textTheme.bodyMedium,
      tableBorderColor: colorScheme.outline,
      tableHeaderColor: colorScheme.surfaceContainerHighest,
      codeBlockBackground:
          isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
      codeBlockBorderRadius: BorderRadius.circular(8),
      blockquoteBorderColor: colorScheme.primary.withValues(alpha: 0.5),
      blockquoteBackground: colorScheme.primary.withValues(alpha: 0.05),
      horizontalRuleColor: colorScheme.outline,
      paragraphSpacing: 16.0,
      headingSpacing: 24.0,
      blockSpacing: 16.0,
      listIndent: 24.0,
      codeBlockPadding: const EdgeInsets.all(16),
      blockquotePadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// Creates a light theme.
  factory MarkdownTheme.light() {
    return MarkdownTheme.fromTheme(ThemeData.light());
  }

  /// Creates a dark theme.
  factory MarkdownTheme.dark() {
    return MarkdownTheme.fromTheme(ThemeData.dark());
  }

  // Text styles
  final TextStyle? textStyle;
  final TextStyle? h1Style;
  final TextStyle? h2Style;
  final TextStyle? h3Style;
  final TextStyle? h4Style;
  final TextStyle? h5Style;
  final TextStyle? h6Style;
  final TextStyle? codeStyle;
  final TextStyle? codeBlockStyle;
  final TextStyle? blockquoteStyle;
  final TextStyle? linkStyle;
  final TextStyle? listBulletStyle;
  final TextStyle? tableStyle;

  // Colors
  final Color? tableBorderColor;
  final Color? tableHeaderColor;
  final Color? codeBlockBackground;
  final BorderRadius? codeBlockBorderRadius;
  final Color? blockquoteBorderColor;
  final Color? blockquoteBackground;
  final Color? horizontalRuleColor;

  // Spacing
  final double? paragraphSpacing;
  final double? headingSpacing;
  final double? blockSpacing;
  final double? listIndent;
  final EdgeInsets? codeBlockPadding;
  final EdgeInsets? blockquotePadding;

  /// Gets heading style by level.
  TextStyle? headingStyle(int level) {
    return switch (level) {
      1 => h1Style,
      2 => h2Style,
      3 => h3Style,
      4 => h4Style,
      5 => h5Style,
      6 => h6Style,
      _ => h6Style,
    };
  }

  /// Creates a copy with optional overrides.
  MarkdownTheme copyWith({
    TextStyle? textStyle,
    TextStyle? h1Style,
    TextStyle? h2Style,
    TextStyle? h3Style,
    TextStyle? h4Style,
    TextStyle? h5Style,
    TextStyle? h6Style,
    TextStyle? codeStyle,
    TextStyle? codeBlockStyle,
    TextStyle? blockquoteStyle,
    TextStyle? linkStyle,
    TextStyle? listBulletStyle,
    TextStyle? tableStyle,
    Color? tableBorderColor,
    Color? tableHeaderColor,
    Color? codeBlockBackground,
    BorderRadius? codeBlockBorderRadius,
    Color? blockquoteBorderColor,
    Color? blockquoteBackground,
    Color? horizontalRuleColor,
    double? paragraphSpacing,
    double? headingSpacing,
    double? blockSpacing,
    double? listIndent,
    EdgeInsets? codeBlockPadding,
    EdgeInsets? blockquotePadding,
  }) {
    return MarkdownTheme(
      textStyle: textStyle ?? this.textStyle,
      h1Style: h1Style ?? this.h1Style,
      h2Style: h2Style ?? this.h2Style,
      h3Style: h3Style ?? this.h3Style,
      h4Style: h4Style ?? this.h4Style,
      h5Style: h5Style ?? this.h5Style,
      h6Style: h6Style ?? this.h6Style,
      codeStyle: codeStyle ?? this.codeStyle,
      codeBlockStyle: codeBlockStyle ?? this.codeBlockStyle,
      blockquoteStyle: blockquoteStyle ?? this.blockquoteStyle,
      linkStyle: linkStyle ?? this.linkStyle,
      listBulletStyle: listBulletStyle ?? this.listBulletStyle,
      tableStyle: tableStyle ?? this.tableStyle,
      tableBorderColor: tableBorderColor ?? this.tableBorderColor,
      tableHeaderColor: tableHeaderColor ?? this.tableHeaderColor,
      codeBlockBackground: codeBlockBackground ?? this.codeBlockBackground,
      codeBlockBorderRadius:
          codeBlockBorderRadius ?? this.codeBlockBorderRadius,
      blockquoteBorderColor:
          blockquoteBorderColor ?? this.blockquoteBorderColor,
      blockquoteBackground: blockquoteBackground ?? this.blockquoteBackground,
      horizontalRuleColor: horizontalRuleColor ?? this.horizontalRuleColor,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      headingSpacing: headingSpacing ?? this.headingSpacing,
      blockSpacing: blockSpacing ?? this.blockSpacing,
      listIndent: listIndent ?? this.listIndent,
      codeBlockPadding: codeBlockPadding ?? this.codeBlockPadding,
      blockquotePadding: blockquotePadding ?? this.blockquotePadding,
    );
  }

  /// Merges this theme with another theme.
  /// Only non-null values from [other] will override values in this theme.
  MarkdownTheme merge(MarkdownTheme? other) {
    if (other == null) return this;
    return MarkdownTheme(
      textStyle: other.textStyle ?? textStyle,
      h1Style: other.h1Style ?? h1Style,
      h2Style: other.h2Style ?? h2Style,
      h3Style: other.h3Style ?? h3Style,
      h4Style: other.h4Style ?? h4Style,
      h5Style: other.h5Style ?? h5Style,
      h6Style: other.h6Style ?? h6Style,
      codeStyle: other.codeStyle ?? codeStyle,
      codeBlockStyle: other.codeBlockStyle ?? codeBlockStyle,
      blockquoteStyle: other.blockquoteStyle ?? blockquoteStyle,
      linkStyle: other.linkStyle ?? linkStyle,
      listBulletStyle: other.listBulletStyle ?? listBulletStyle,
      tableStyle: other.tableStyle ?? tableStyle,
      tableBorderColor: other.tableBorderColor ?? tableBorderColor,
      tableHeaderColor: other.tableHeaderColor ?? tableHeaderColor,
      codeBlockBackground: other.codeBlockBackground ?? codeBlockBackground,
      codeBlockBorderRadius: other.codeBlockBorderRadius ?? codeBlockBorderRadius,
      blockquoteBorderColor: other.blockquoteBorderColor ?? blockquoteBorderColor,
      blockquoteBackground: other.blockquoteBackground ?? blockquoteBackground,
      horizontalRuleColor: other.horizontalRuleColor ?? horizontalRuleColor,
      paragraphSpacing: other.paragraphSpacing ?? paragraphSpacing,
      headingSpacing: other.headingSpacing ?? headingSpacing,
      blockSpacing: other.blockSpacing ?? blockSpacing,
      listIndent: other.listIndent ?? listIndent,
      codeBlockPadding: other.codeBlockPadding ?? codeBlockPadding,
      blockquotePadding: other.blockquotePadding ?? blockquotePadding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkdownTheme &&
          runtimeType == other.runtimeType &&
          textStyle == other.textStyle &&
          h1Style == other.h1Style &&
          h2Style == other.h2Style &&
          h3Style == other.h3Style &&
          h4Style == other.h4Style &&
          h5Style == other.h5Style &&
          h6Style == other.h6Style &&
          codeStyle == other.codeStyle &&
          codeBlockStyle == other.codeBlockStyle &&
          blockquoteStyle == other.blockquoteStyle &&
          linkStyle == other.linkStyle &&
          listBulletStyle == other.listBulletStyle &&
          tableStyle == other.tableStyle &&
          tableBorderColor == other.tableBorderColor &&
          tableHeaderColor == other.tableHeaderColor &&
          codeBlockBackground == other.codeBlockBackground &&
          codeBlockBorderRadius == other.codeBlockBorderRadius &&
          blockquoteBorderColor == other.blockquoteBorderColor &&
          blockquoteBackground == other.blockquoteBackground &&
          horizontalRuleColor == other.horizontalRuleColor &&
          paragraphSpacing == other.paragraphSpacing &&
          headingSpacing == other.headingSpacing &&
          blockSpacing == other.blockSpacing &&
          listIndent == other.listIndent &&
          codeBlockPadding == other.codeBlockPadding &&
          blockquotePadding == other.blockquotePadding;

  @override
  int get hashCode => Object.hashAll([
    textStyle,
    h1Style,
    h2Style,
    h3Style,
    h4Style,
    h5Style,
    h6Style,
    codeStyle,
    codeBlockStyle,
    blockquoteStyle,
    linkStyle,
    listBulletStyle,
    tableStyle,
    tableBorderColor,
    tableHeaderColor,
    codeBlockBackground,
    codeBlockBorderRadius,
    blockquoteBorderColor,
    blockquoteBackground,
    horizontalRuleColor,
    paragraphSpacing,
    headingSpacing,
    blockSpacing,
    listIndent,
    codeBlockPadding,
    blockquotePadding,
  ]);
}

/// Inherited widget for markdown theme.
class MarkdownThemeProvider extends InheritedWidget {
  /// Creates a markdown theme provider.
  const MarkdownThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  /// The markdown theme.
  final MarkdownTheme theme;

  /// Gets the current markdown theme from context.
  static MarkdownTheme of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<MarkdownThemeProvider>();
    return provider?.theme ?? MarkdownTheme.fromTheme(Theme.of(context));
  }

  /// Gets the current markdown theme from context, or null.
  static MarkdownTheme? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<MarkdownThemeProvider>();
    return provider?.theme;
  }

  @override
  bool updateShouldNotify(MarkdownThemeProvider oldWidget) {
    return theme != oldWidget.theme;
  }
}
