# flutter_markdown_widget

High-performance Markdown rendering for Flutter, designed for both static content and AI-style streaming responses.

## Features

- Streaming rendering (`StreamingMarkdownView.fromStream`)
- Incremental parser for low-latency updates
- AST parser for accurate static rendering
- Built-in LaTeX support (`$...$`, `$$...$$`)
- TOC support with jump-to-heading (`MarkdownWidget` + `TocController`)
- Virtual scrolling for large documents
- Configurable render pipeline (`RenderOptions`, custom parser/custom syntax)

## Mermaid diagrams

Mermaid rendering is provided by the companion package
`flutter_markdown_widget_mermaid`.

For published packages:

```bash
flutter pub add flutter_markdown_widget flutter_markdown_widget_mermaid
```

For local development, clone the two repositories side-by-side and use path
dependencies:

```yaml
dependencies:
  flutter_markdown_widget:
    path: ../flutter-markdown-widget
  flutter_markdown_widget_mermaid:
    path: ../flutter-markdown-widget-mermaid
```

Create one renderer, keep `MermaidWebViewHost` above the markdown subtree, and
pass the same renderer through `RenderOptions`:

```dart
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_markdown_widget_mermaid/flutter_markdown_widget_mermaid.dart';

final mermaidRenderer = MermaidWebViewRenderer.shared();

MermaidWebViewHost(
  renderer: mermaidRenderer,
  child: MarkdownWidget(
    data: markdownSource,
    renderOptions: RenderOptions(
      mermaidOptions: MermaidOptions(
        renderer: mermaidRenderer,
      ),
    ),
  ),
);
```

The WebView renderer uses `webview_flutter`. Keep the host alive at app or page
scope so diagrams can share the same WebView-backed renderer instance. The
example app includes static, streaming, themed, and error-state Mermaid demos
and is verified on iOS, Android, and macOS.

## Installation

```bash
flutter pub add flutter_markdown_widget
```

## Quick Start

### Static markdown

```dart
StreamingMarkdownView(
  content: '# Hello\n\nThis is markdown.',
)
```

### Streaming markdown

```dart
StreamingMarkdownView.fromStream(
  stream: responseStream,
  streamingOptions: const StreamingOptions(
    bufferMode: BufferMode.byBlock,
    showTypingCursor: true,
  ),
)
```

### TOC navigation

```dart
final tocController = TocController();

Row(
  children: [
    SizedBox(
      width: 260,
      child: TocListWidget(controller: tocController),
    ),
    Expanded(
      child: MarkdownWidget(
        data: markdown,
        tocController: tocController,
      ),
    ),
  ],
)
```

## Rendering Modes

- `ParserMode.ast`: recommended for static content and maximum structural accuracy
- `ParserMode.incremental`: recommended for streaming/continuous updates

## Performance Notes

- Enable virtual scrolling for long documents (`enableVirtualScrolling: true`)
- For chat-style streams, use `BufferMode.byBlock` or `BufferMode.byInterval`
- Use `MarkdownContent` when embedding markdown in an existing parent scroll view

## Example App

See `/example` for end-to-end demos:

- Feature Showcase
- Streaming Lab
- TOC Navigator
- Editor Preview
- Mermaid Showcase
- Performance

## Contributing

Issues and PRs are welcome: <https://github.com/indie-geeker/flutter-markdown-widget>

## License

BSD-3-Clause (see `LICENSE`)
