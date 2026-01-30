// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Animated typing cursor for streaming mode.
class TypingCursor extends StatefulWidget {
  /// Creates a typing cursor.
  const TypingCursor({
    super.key,
    this.color,
    this.width = 2,
    this.height = 18,
    this.blinkDuration = const Duration(milliseconds: 530),
  });

  /// Cursor color. Defaults to theme primary color.
  final Color? color;

  /// Cursor width.
  final double width;

  /// Cursor height.
  final double height;

  /// Blink animation duration.
  final Duration blinkDuration;

  @override
  State<TypingCursor> createState() => _TypingCursorState();
}

class _TypingCursorState extends State<TypingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.blinkDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cursorColor =
        widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: cursorColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}

/// Inline typing cursor that follows text.
class InlineTypingCursor extends StatelessWidget {
  /// Creates an inline typing cursor.
  const InlineTypingCursor({
    super.key,
    this.color,
    this.blinkDuration = const Duration(milliseconds: 530),
  });

  /// Cursor color.
  final Color? color;

  /// Blink duration.
  final Duration blinkDuration;

  @override
  Widget build(BuildContext context) {
    return TypingCursor(
      color: color,
      width: 2,
      height: 16,
      blinkDuration: blinkDuration,
    );
  }
}
