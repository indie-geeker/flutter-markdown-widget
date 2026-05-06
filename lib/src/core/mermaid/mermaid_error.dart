// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Base class for all Mermaid render failures.
sealed class MermaidError {
  const MermaidError({required this.source, required this.stackTrace});

  /// The Mermaid source that failed to render.
  final String source;

  /// Stack trace at the point of failure.
  final StackTrace stackTrace;
}

/// `mermaid.js` reported a parse / syntax error.
class MermaidSyntaxError extends MermaidError {
  const MermaidSyntaxError({
    required super.source,
    required this.message,
    required super.stackTrace,
  });

  /// Human-readable message returned by the renderer.
  final String message;
}

/// The render future did not complete within `MermaidOptions.renderTimeout`.
class MermaidTimeoutError extends MermaidError {
  const MermaidTimeoutError({
    required super.source,
    required this.elapsed,
    required super.stackTrace,
  });

  /// Duration after which the timeout fired.
  final Duration elapsed;
}

/// Renderer threw a non-business exception.
class MermaidRuntimeError extends MermaidError {
  const MermaidRuntimeError({
    required super.source,
    required this.cause,
    required super.stackTrace,
  });

  /// Underlying exception thrown by the renderer.
  final Object cause;
}

/// Renderer returned an SVG payload that could not be parsed/displayed.
class MermaidInvalidOutputError extends MermaidError {
  const MermaidInvalidOutputError({
    required super.source,
    required this.svg,
    required super.stackTrace,
  });

  /// The offending SVG string.
  final String svg;
}

/// Renderer initialization failed permanently.
class MermaidInitializationError extends MermaidError {
  const MermaidInitializationError({
    required super.source,
    required this.cause,
    required super.stackTrace,
  });

  /// Underlying initialization failure.
  final Object cause;
}

/// Context passed to a user-supplied error builder.
@immutable
class MermaidErrorContext {
  const MermaidErrorContext({
    required this.error,
    required this.source,
    required this.retry,
  });

  /// The error that triggered the fallback rendering.
  final MermaidError error;

  /// The original Mermaid source.
  final String source;

  /// Invoke to attempt the render again.
  final VoidCallback retry;
}
