// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';

class StaticDemoPage extends StatelessWidget {
  const StaticDemoPage({super.key});

  static const _demoContent = '''
# Welcome to Flutter Markdown Widget

This is a **powerful** and *beautiful* markdown rendering library designed for modern Flutter applications.

---

## ✨ Features

This library supports all standard **GFM (GitHub Flavored Markdown)** features:

- **Bold** and *italic* text formatting
- ~~Strikethrough~~ for deleted content
- Inline `code` and code blocks
- [Hyperlinks](https://flutter.dev) with tap handling
- Task lists with interactive checkboxes

### 📝 Code Blocks

Syntax highlighted code with line numbers and copy button:

```dart
class MarkdownWidget extends StatelessWidget {
  final String content;
  
  const MarkdownWidget({required this.content});
  
  @override
  Widget build(BuildContext context) {
    return StreamingMarkdownView(
      content: content,
      renderOptions: RenderOptions(
        enableLatex: true,
        enableCodeHighlight: true,
      ),
    );
  }
}
```

### 📋 Lists

**Ordered List:**

1. First step - Initialize the widget
2. Second step - Configure options
3. Third step - Enjoy beautiful rendering!

**Unordered List:**

- 🚀 High performance rendering
- 🎨 Fully customizable themes
- 📱 Mobile-friendly responsive layout

### 💬 Blockquotes

> "The best way to predict the future is to create it."
> 
> — Peter Drucker

### 📊 Tables

| Feature | Status | Priority |
|---------|--------|----------|
| Streaming | ✅ Done | High |
| Virtual Scroll | ✅ Done | High |
| LaTeX Math | ✅ Done | Medium |
| TOC Generator | ✅ Done | Medium |

---

## 🧮 Mathematics

Inline math: The famous equation \$E = mc^2\$ relates energy and mass.

Block equation for the Gaussian integral:

\$\$
\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}
\$\$

---

*Built with ❤️ for the Flutter community*
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
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.article_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Static Markdown'),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
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
          child: StreamingMarkdownView(
            content: _demoContent,
            padding: const EdgeInsets.all(24),
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
              codeBlockPadding: const EdgeInsets.all(20),
              blockquoteBorderColor: const Color(0xFF6366F1),
              blockquoteBackground: isDark
                  ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                  : const Color(0xFF6366F1).withValues(alpha: 0.05),
            ),
            renderOptions: const RenderOptions(
              enableLatex: true,
              enableCodeHighlight: true,
              enableTables: true,
              selectableText: true,
            ),
          ),
        ),
      ),
    );
  }
}
