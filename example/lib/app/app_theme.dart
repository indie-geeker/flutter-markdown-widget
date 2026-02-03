// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';

class AppPalette {
  static const Color brand = Color(0xFF0EA5E9);
  static const Color brandDark = Color(0xFF0284C7);
  static const Color accent = Color(0xFFF97316);
  static const Color mint = Color(0xFF10B981);
  static const Color indigo = Color(0xFF6366F1);

  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCanvas = Color(0xFFF8FAFC);
  static const Color lightCanvasAlt = Color(0xFFE2E8F0);

  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkCanvas = Color(0xFF0B1220);
  static const Color darkCanvasAlt = Color(0xFF111827);
}

class AppGradients {
  static LinearGradient pageBackground(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [AppPalette.darkCanvas, AppPalette.darkCanvasAlt]
          : const [AppPalette.lightCanvas, AppPalette.lightCanvasAlt],
    );
  }

  static const List<Color> blue = [Color(0xFF38BDF8), Color(0xFF0EA5E9)];
  static const List<Color> violet = [Color(0xFF818CF8), Color(0xFF6366F1)];
  static const List<Color> emerald = [Color(0xFF34D399), Color(0xFF10B981)];
  static const List<Color> amber = [Color(0xFFFBBF24), Color(0xFFF59E0B)];
  static const List<Color> coral = [Color(0xFFFB7185), Color(0xFFF43F5E)];
  static const List<Color> ocean = [Color(0xFF22D3EE), Color(0xFF0EA5E9)];
}

class ExampleTheme {
  static const String fontFamily = 'SF Pro Display';

  static ThemeData light() {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.brand,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.brand,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static MarkdownTheme markdownTheme(
    BuildContext context, {
    Color? accent,
    bool dense = false,
  }) {
    final base = MarkdownTheme.fromTheme(Theme.of(context));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = accent ?? Theme.of(context).colorScheme.primary;

    return base.copyWith(
      textStyle: base.textStyle?.copyWith(
        fontSize: dense ? 14 : 15,
        height: dense ? 1.6 : 1.75,
      ),
      headingSpacing: dense ? 20 : 28,
      blockSpacing: dense ? 14 : 18,
      paragraphSpacing: dense ? 12 : 16,
      codeBlockBackground:
          isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9),
      codeBlockBorderRadius: BorderRadius.circular(14),
      blockquoteBorderColor: accentColor,
      blockquoteBackground: accentColor.withValues(alpha: isDark ? 0.16 : 0.08),
    );
  }
}
