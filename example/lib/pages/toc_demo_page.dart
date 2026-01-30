// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';

class TocDemoPage extends StatefulWidget {
  const TocDemoPage({super.key});

  @override
  State<TocDemoPage> createState() => _TocDemoPageState();
}

class _TocDemoPageState extends State<TocDemoPage> {
  // This is all you need for TOC functionality!
  final _tocController = TocController();

  @override
  void dispose() {
    _tocController.dispose();
    super.dispose();
  }

  static const _content = '''
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

## 1.2 Core Concepts

Understanding these concepts is essential for effective usage of the library.

---

# 🚀 Chapter 2: Basic Usage

This chapter covers the fundamental patterns you'll use every day.

## 2.1 Rendering Static Content

The simplest way to render markdown:

```dart
StreamingMarkdownView(
  content: '# Hello World',
)
```

## 2.2 Streaming Content

For AI chat applications with real-time updates:

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

Explore the powerful capabilities of this library.

## 3.1 Custom Theming

Create a custom theme to match your app's design:

```dart
final theme = MarkdownTheme(
  headingSpacing: 24,
  codeBlockPadding: EdgeInsets.all(16),
  blockquoteBorderColor: Colors.purple,
);
```

## 3.2 TOC Generation

Generate a table of contents dynamically:

```dart
final tocController = TocController();

Widget buildTocWidget() => TocListWidget(controller: tocController);

Widget buildMarkdown() => MarkdownWidget(data: data, tocController: tocController);
```

## 3.3 Virtual Scrolling

Enable virtual scrolling for long documents:

```dart
StreamingMarkdownView(
  content: longContent,
  renderOptions: RenderOptions(
    enableVirtualScrolling: true,
  ),
)
```

---

# ✅ Chapter 4: Conclusion

Thank you for reading! You're now ready to build amazing markdown experiences.
''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('TOC Navigation'),
          ],
        ),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // TOC Sidebar - using TocListWidget with TocController
          Container(
            width: 280,
            margin: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.toc_rounded,
                          size: 18,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Contents',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15),
                ),
                // Simply use TocListWidget - it handles everything!
                Expanded(
                  child: TocListWidget(
                    controller: _tocController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    activeBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
          
          // Content area - using MarkdownWidget with same TocController
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                // Simply use MarkdownWidget with tocController!
                child: MarkdownWidget(
                  data: _content,
                  tocController: _tocController,
                  padding: const EdgeInsets.all(32),
                  theme: MarkdownTheme(
                    textStyle: TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                    headingSpacing: 28,
                    blockSpacing: 18,
                    codeBlockBackground: isDark 
                        ? const Color(0xFF0F172A) 
                        : const Color(0xFFF1F5F9),
                    codeBlockBorderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
