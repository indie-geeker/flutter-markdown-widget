// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// Buffer for handling streaming text input.
///
/// Accumulates incoming text chunks and provides methods
/// to extract complete blocks for parsing.
class TextChunkBuffer {
  /// Creates a text buffer with optional initial content.
  TextChunkBuffer({String? initialContent}) {
    if (initialContent != null) {
      _buffer.write(initialContent);
    }
  }

  final StringBuffer _buffer = StringBuffer();
  final StreamController<String> _textController =
      StreamController<String>.broadcast();

  /// Stream of accumulated text updates.
  Stream<String> get textStream => _textController.stream;

  /// Current accumulated text content.
  String get content => _buffer.toString();

  /// Current length of accumulated content.
  int get length => _buffer.length;

  /// Whether the buffer is empty.
  bool get isEmpty => _buffer.isEmpty;

  /// Whether the buffer has content.
  bool get isNotEmpty => _buffer.isNotEmpty;

  /// Whether the buffer has trailing incomplete content.
  ///
  /// This indicates there is remaining text that does not end with a newline.
  bool get hasIncomplete => getTrailingContent().isNotEmpty;

  /// Appends a chunk of text to the buffer.
  void append(String chunk) {
    _buffer.write(chunk);
    _textController.add(_buffer.toString());
  }

  /// Appends a line of text with newline character.
  void appendLine(String line) {
    _buffer.writeln(line);
    _textController.add(_buffer.toString());
  }

  /// Clears all buffer content.
  void clear() {
    _buffer.clear();
    _textController.add('');
  }

  /// Replaces all content with new text.
  void replaceAll(String newContent) {
    _buffer.clear();
    _buffer.write(newContent);
    _textController.add(_buffer.toString());
  }

  /// Extracts complete lines from the buffer.
  ///
  /// Returns a list of complete lines (ending with newline).
  /// Incomplete trailing content remains in the buffer.
  List<String> extractCompleteLines() {
    final text = _buffer.toString();
    final lastNewline = text.lastIndexOf('\n');

    if (lastNewline == -1) {
      return [];
    }

    final completeText = text.substring(0, lastNewline + 1);
    final remainder = text.substring(lastNewline + 1);

    _buffer.clear();
    _buffer.write(remainder);

    return completeText.split('\n').where((l) => l.isNotEmpty).toList();
  }

  /// Gets the trailing incomplete content.
  ///
  /// Returns content after the last newline, or all content
  /// if there are no newlines.
  String getTrailingContent() {
    final text = _buffer.toString();
    final lastNewline = text.lastIndexOf('\n');

    if (lastNewline == -1) {
      return text;
    }

    return text.substring(lastNewline + 1);
  }

  /// Checks if the buffer ends with incomplete block markers.
  ///
  /// Returns true if content appears to be mid-block
  /// (e.g., unclosed code fence or LaTeX delimiter).
  bool hasIncompleteBlock() {
    final text = _buffer.toString();

    // Check for unclosed code fence
    final codeFenceMatches = RegExp(r'^```', multiLine: true).allMatches(text);
    if (codeFenceMatches.length.isOdd) {
      return true;
    }

    // Check for unclosed LaTeX block
    final latexBlockMatches =
        RegExp(r'^\$\$', multiLine: true).allMatches(text);
    if (latexBlockMatches.length.isOdd) {
      return true;
    }

    return false;
  }

  /// Disposes the buffer and closes streams.
  void dispose() {
    _textController.close();
  }
}

/// Configuration for buffer behavior.
class BufferConfig {
  /// Creates buffer configuration.
  const BufferConfig({
    this.flushThresholdLines = 10,
    this.flushThresholdMs = 100,
    this.preserveIncompleteBlocks = true,
  });

  /// Number of complete lines before triggering flush.
  final int flushThresholdLines;

  /// Milliseconds of inactivity before flushing.
  final int flushThresholdMs;

  /// Whether to preserve incomplete blocks during flush.
  final bool preserveIncompleteBlocks;

  /// Default buffer configuration.
  static const BufferConfig defaultConfig = BufferConfig();
}
