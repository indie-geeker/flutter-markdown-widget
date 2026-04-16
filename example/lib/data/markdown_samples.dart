// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class MarkdownSamples {
  static const String featureShowcase = r'''
# Flutter Markdown Widget — Feature Showcase

This page demonstrates **all core features** with a single document.

- **GFM** formatting, tables, task lists
- **Autolinks** and link callbacks
- **Images** with max size controls
- **Code blocks** with syntax highlight + copy
- **LaTeX** inline and block math
- **Selectable text** and virtual scrolling

---

## ✨ Formatting

**Bold**, *italic*, ~~strikethrough~~, `inline code`, and emojis 😄.

Autolinks: https://flutter.dev, https://dart.dev, and email: support@example.com

> “Build fast. Iterate faster.”

---

## ✅ Task Lists

- [x] Streaming rendering for AI apps
- [x] LaTeX math support
- [x] Code highlighting with copy
- [ ] Custom builders (optional)

---

## 📊 Tables

| Feature | API | Notes |
|--------|-----|-------|
| Streaming | `StreamingMarkdownView.fromStream` | Real-time updates |
| TOC | `MarkdownWidget` + `TocController` | Jump to headings |
| Virtual Scroll | `enableVirtualScrolling` | Large docs |

---

## 🧩 Code Blocks

```dart
final options = RenderOptions(
  enableLatex: true,
  enableTables: true,
  onLinkTap: (url, title) {
    debugPrint('Link: $url');
  },
);
```

---

## 🖼️ Images

![Aurora](https://images.unsplash.com/photo-1496307042754-b4aa456c4a2d?auto=format&fit=crop&w=1200&q=80)

---

## 🧮 Math

Inline: $E = mc^2$ and $\sigma = \sqrt{\frac{1}{N}\sum_{i=1}^{N}(x_i-\mu)^2}$

Block:

$$
\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}
$$

---

*Happy building!*
''';

  static const String streamingResponse = r'''
# 🚀 Understanding Flutter State Management

When building Flutter applications, **state management** is one of the most important concepts to master.

## 📚 What is State?

State refers to any data that can change over time and affects your UI. There are two main types:

1. **Ephemeral State** — Local to a single widget
2. **App State** — Shared across multiple widgets

## 🔧 Popular Solutions

### Provider

```dart
class CounterProvider extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}
```

### Riverpod

```dart
final counterProvider = StateNotifierProvider<Counter, int>(
  (ref) => Counter(),
);
```

### BLoC Pattern

- Separates UI from business logic
- Uses streams for reactive updates
- Excellent for testing

---

*Hope this helps! Let me know if you have questions.*
''';

  static const String tocContent = r'''
# 📖 Chapter 1: Introduction

Welcome to this comprehensive guide. This chapter covers the fundamentals you need to get started.

## 1.1 Getting Started

Before diving in, let's set up our environment and understand the basics.

### 1.1.1 Prerequisites

Make sure you have the following installed:
- Flutter SDK 3.10 or higher
- Dart SDK 3.0 or higher
- Your favorite IDE (VS Code, Android Studio)

### 1.1.2 Installation

Run the following command to add the package:

```bash
flutter pub add flutter_markdown_widget
```

---

# 🚀 Chapter 2: Basic Usage

## 2.1 Rendering Static Content

```dart
StreamingMarkdownView(
  content: '# Hello World',
)
```

## 2.2 Streaming Content

```dart
StreamingMarkdownView.fromStream(
  stream: yourStream,
  streamingOptions: StreamingOptions(
    showTypingCursor: true,
    autoScrollToBottom: true,
  ),
)
```

---

# 🎨 Chapter 3: Advanced Features

## 3.1 Custom Theming

```dart
final theme = MarkdownTheme(
  headingSpacing: 24,
  codeBlockPadding: EdgeInsets.all(16),
  blockquoteBorderColor: Colors.indigo,
);
```

## 3.2 TOC Generation

```dart
final tocController = TocController();

Row(
  children: [
    TocListWidget(controller: tocController),
    Expanded(child: MarkdownWidget(data: data, tocController: tocController)),
  ],
)
```

---

# ✅ Chapter 4: Conclusion

Thank you for reading! You're now ready to build amazing markdown experiences.
''';

  static String buildLongDocument({int sections = 18}) {
    final buffer = StringBuffer();
    for (int i = 1; i <= sections; i++) {
      buffer.writeln('# Section $i');
      buffer.writeln(
        'This is a long document section used to showcase virtual scrolling. '
        'It contains repeated paragraphs, lists, and code to build many blocks.',
      );
      buffer.writeln();
      buffer.writeln('- Bullet A');
      buffer.writeln('- Bullet B');
      buffer.writeln('- Bullet C');
      buffer.writeln();
      buffer.writeln('```dart');
      buffer.writeln('final index = $i;');
      buffer.writeln('print("Rendering section $i");');
      buffer.writeln('```');
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Builds a mixed-content document targeting a specific character count.
  ///
  /// Generates headings, paragraphs with inline formatting, lists, code blocks,
  /// tables, LaTeX, and horizontal rules for realistic performance testing.
  static String buildPerformanceDocument({int targetChars = 10000}) {
    final buffer = StringBuffer();
    int section = 0;

    while (buffer.length < targetChars) {
      section++;
      final mod = section % 6;

      buffer.writeln('# Section $section: Performance Test');
      buffer.writeln();

      // Paragraph with inline formatting
      buffer.writeln(
        'This is paragraph **$section** with *italic text*, `inline code`, '
        'and a [link](https://example.com/$section). The quick brown fox jumps '
        'over the lazy dog. Lorem ipsum dolor sit amet, consectetur adipiscing '
        'elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      );
      buffer.writeln();

      if (mod == 0) {
        // Table section
        buffer.writeln('| Column A | Column B | Column C | Column D |');
        buffer.writeln('|----------|----------|----------|----------|');
        for (int row = 1; row <= 4; row++) {
          buffer.writeln('| Cell ${section}x$row | Value $row | Data | Result |');
        }
        buffer.writeln();
      } else if (mod == 1) {
        // Code block
        buffer.writeln('```dart');
        buffer.writeln('class Section$section {');
        buffer.writeln('  final int id = $section;');
        buffer.writeln('  final String name;');
        buffer.writeln('');
        buffer.writeln('  Section$section(this.name);');
        buffer.writeln('');
        buffer.writeln('  String describe() {');
        buffer.writeln("    return 'Section \$id: \$name';");
        buffer.writeln('  }');
        buffer.writeln('}');
        buffer.writeln('```');
        buffer.writeln();
      } else if (mod == 2) {
        // Bullet list
        buffer.writeln('- First item with **bold** emphasis');
        buffer.writeln('- Second item with `code` formatting');
        buffer.writeln('- Third item with *italic* styling');
        buffer.writeln('- Fourth item linking to [docs](https://example.com)');
        buffer.writeln('- Fifth item in section $section');
        buffer.writeln();
      } else if (mod == 3) {
        // Numbered list
        buffer.writeln('1. Step one: Initialize the configuration');
        buffer.writeln('2. Step two: Parse the markdown input');
        buffer.writeln('3. Step three: Build the widget tree');
        buffer.writeln('4. Step four: Render to the screen');
        buffer.writeln();
      } else if (mod == 4) {
        // LaTeX block
        buffer.writeln(r'Inline math: $E = mc^2$ and $\alpha + \beta = \gamma$');
        buffer.writeln();
        buffer.writeln(r'$$');
        buffer.writeln(r'\sum_{i=1}^{n} x_i = \frac{n(n+1)}{2}');
        buffer.writeln(r'$$');
        buffer.writeln();
      } else {
        // Blockquote
        buffer.writeln('> "Performance is not just about speed — it\'s about '
            'consistency. A smooth 60fps experience builds user trust."');
        buffer.writeln('>');
        buffer.writeln('> — Section $section');
        buffer.writeln();
      }

      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }
}
