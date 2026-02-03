// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.pageBackground(isDark),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowBlob(
              size: 280,
              color: isDark
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF93C5FD),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: _GlowBlob(
              size: 260,
              color: isDark
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFFA5F3FC),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
