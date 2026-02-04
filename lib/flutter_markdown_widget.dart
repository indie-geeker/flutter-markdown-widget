// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A high-performance streaming Markdown rendering library for Flutter.
///
/// This library provides:
/// - Streaming rendering for AI chat scenarios
/// - Virtual scrolling for long documents
/// - Built-in LaTeX support
/// - Enhanced code block highlighting
///
/// Basic usage:
/// ```dart
/// import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
///
/// // Static rendering
/// StreamingMarkdownView(
///   content: '# Hello World',
/// )
///
/// // Streaming rendering
/// StreamingMarkdownView.fromStream(
///   stream: aiResponseStream,
/// )
/// ```

// Core exports
export 'src/core/parser/markdown_parser.dart';
export 'src/core/parser/incremental_parser.dart';
export 'src/core/parser/ast_markdown_parser.dart';
export 'src/core/parser/text_buffer.dart';
export 'src/core/parser/content_block.dart';
export 'src/core/cache/widget_cache.dart';
export 'src/core/cache/dimension_estimator.dart';

// Widget exports
export 'src/widgets/streaming_markdown_view.dart';
export 'src/widgets/markdown_content.dart';
export 'src/widgets/virtual_markdown_list.dart';
export 'src/widgets/components/code_block_view.dart';
export 'src/widgets/components/formula_view.dart';
export 'src/widgets/components/typing_cursor.dart';

// Style exports
export 'src/style/markdown_theme.dart';

// Builder exports
export 'src/builder/content_builder.dart';
export 'src/builder/element_builders/formula_builder.dart';
export 'src/builder/element_builders/code_builder.dart';
export 'src/builder/element_builders/table_builder.dart';

// Configuration exports
export 'src/config/streaming_options.dart';
export 'src/config/render_options.dart';

// TOC exports
export 'src/toc/toc_generator.dart';
export 'src/toc/toc_view.dart';
export 'src/toc/toc_controller.dart';
export 'src/widgets/markdown_widget.dart';
