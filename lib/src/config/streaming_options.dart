// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Buffer strategy for streaming content.
enum BufferMode {
  /// Buffer by line - flush on newline.
  byLine,

  /// Buffer by character count.
  byCharacter,

  /// Buffer by time interval.
  byInterval,

  /// Buffer complete blocks only.
  byBlock,
}

/// Configuration for streaming markdown rendering.
@immutable
class StreamingOptions {
  /// Creates streaming options.
  const StreamingOptions({
    this.bufferMode = BufferMode.byBlock,
    this.throttleMs = 16,
    this.showTypingCursor = true,
    this.cursorBlinkRate = const Duration(milliseconds: 530),
    this.renderIncompleteBlocks = false,
    this.incompleteBlockOpacity = 0.5,
    this.autoScrollToBottom = true,
    this.scrollAnimationDuration = const Duration(milliseconds: 150),
    this.finalizeWithAst = true,
  });

  /// Default streaming options.
  static const StreamingOptions defaultOptions = StreamingOptions();

  /// Buffer mode for incoming content.
  final BufferMode bufferMode;

  /// Minimum milliseconds between render updates.
  final int throttleMs;

  /// Whether to show typing cursor during streaming.
  final bool showTypingCursor;

  /// Cursor blink rate.
  final Duration cursorBlinkRate;

  /// Whether to render incomplete blocks (faded).
  final bool renderIncompleteBlocks;

  /// Opacity for incomplete block rendering.
  final double incompleteBlockOpacity;

  /// Whether to auto-scroll to bottom during streaming.
  final bool autoScrollToBottom;

  /// Duration for auto-scroll animation.
  final Duration scrollAnimationDuration;

  /// Whether to re-parse with AST when streaming completes.
  final bool finalizeWithAst;

  /// Creates a copy with optional overrides.
  StreamingOptions copyWith({
    BufferMode? bufferMode,
    int? throttleMs,
    bool? showTypingCursor,
    Duration? cursorBlinkRate,
    bool? renderIncompleteBlocks,
    double? incompleteBlockOpacity,
    bool? autoScrollToBottom,
    Duration? scrollAnimationDuration,
    bool? finalizeWithAst,
  }) {
    return StreamingOptions(
      bufferMode: bufferMode ?? this.bufferMode,
      throttleMs: throttleMs ?? this.throttleMs,
      showTypingCursor: showTypingCursor ?? this.showTypingCursor,
      cursorBlinkRate: cursorBlinkRate ?? this.cursorBlinkRate,
      renderIncompleteBlocks:
          renderIncompleteBlocks ?? this.renderIncompleteBlocks,
      incompleteBlockOpacity:
          incompleteBlockOpacity ?? this.incompleteBlockOpacity,
      autoScrollToBottom: autoScrollToBottom ?? this.autoScrollToBottom,
      scrollAnimationDuration:
          scrollAnimationDuration ?? this.scrollAnimationDuration,
      finalizeWithAst: finalizeWithAst ?? this.finalizeWithAst,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamingOptions &&
          runtimeType == other.runtimeType &&
          bufferMode == other.bufferMode &&
          throttleMs == other.throttleMs &&
          showTypingCursor == other.showTypingCursor &&
          renderIncompleteBlocks == other.renderIncompleteBlocks &&
          autoScrollToBottom == other.autoScrollToBottom &&
          finalizeWithAst == other.finalizeWithAst;

  @override
  int get hashCode => Object.hash(
    bufferMode,
    throttleMs,
    showTypingCursor,
    renderIncompleteBlocks,
    autoScrollToBottom,
    finalizeWithAst,
  );
}
