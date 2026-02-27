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
- Performance

## Contributing

Issues and PRs are welcome: <https://github.com/indie-geeker/flutter-markdown-widget>

## License

BSD-3-Clause (see `LICENSE`)
