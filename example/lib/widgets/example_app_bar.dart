// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ExampleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ExampleAppBar({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    this.actions,
    this.showBack = true,
  });

  final String title;
  final IconData icon;
  final List<Color> gradient;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBack ? const _BackButton() : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      centerTitle: true,
      actions: actions,
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
