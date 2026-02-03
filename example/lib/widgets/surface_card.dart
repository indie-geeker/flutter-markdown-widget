// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C2E) : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
