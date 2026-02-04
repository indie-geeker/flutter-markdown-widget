// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';

import '../app/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/example_app_bar.dart';
import '../widgets/surface_card.dart';

class EditorPreviewPage extends StatefulWidget {
  const EditorPreviewPage({super.key});

  @override
  State<EditorPreviewPage> createState() => _EditorPreviewPageState();
}

class _EditorPreviewPageState extends State<EditorPreviewPage> {
  static const String _initialMarkdown = r'''# Markdown Editor

Type on the left and preview on the right.

## Supported Syntax

- **Bold**, *italic*, `inline code`
- [Links](https://flutter.dev)
- Task lists:
  - [x] Live preview
  - [ ] Add your own content

```dart
void main() {
  runApp(const MyApp());
}
```

| Feature | Status |
| --- | --- |
| Tables | Ready |
| Code Highlight | Ready |
''';

  final TextEditingController _controller = TextEditingController(
    text: _initialMarkdown,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reset() {
    _controller.value = const TextEditingValue(
      text: _initialMarkdown,
      selection: TextSelection.collapsed(offset: _initialMarkdown.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;
    final markdownTheme = ExampleTheme.markdownTheme(
      context,
      accent: AppPalette.accent,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ExampleAppBar(
        title: 'Editor Preview',
        icon: Icons.edit_note_rounded,
        gradient: AppGradients.amber,
        actions: [
          IconButton(
            onPressed: _reset,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            20,
            24,
          ),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final markdown = value.text;
              final preview = markdown.trim().isEmpty
                  ? '_Type markdown in the editor to preview it._'
                  : markdown;

              final editorPane = _EditorPane(controller: _controller);
              final previewPane = _PreviewPane(
                content: preview,
                theme: markdownTheme,
                charCount: markdown.length,
              );
              final splitLayout = Row(
                children: [
                  Expanded(child: editorPane),
                  const SizedBox(width: 16),
                  Expanded(child: previewPane),
                ],
              );

              if (isWide) {
                return splitLayout;
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 980,
                  child: splitLayout,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EditorPane extends StatelessWidget {
  const _EditorPane({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      radius: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            const _PaneHeader(
              title: 'Editor',
              subtitle: 'Write markdown content',
              icon: Icons.edit_rounded,
            ),
            Container(height: 1, color: Theme.of(context).dividerColor),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(20),
                  hintText: 'Write markdown here...',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.55,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({
    required this.content,
    required this.theme,
    required this.charCount,
  });

  final String content;
  final MarkdownTheme theme;
  final int charCount;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      radius: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _PaneHeader(
              title: 'Preview',
              subtitle: '$charCount chars',
              icon: Icons.visibility_rounded,
            ),
            Container(height: 1, color: Theme.of(context).dividerColor),
            Expanded(
              child: MarkdownWidget(
                data: content,
                padding: const EdgeInsets.all(24),
                theme: theme,
                renderOptions: const RenderOptions(
                  enableTables: true,
                  enableTaskLists: true,
                  enableCodeHighlight: true,
                  enableLatex: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaneHeader extends StatelessWidget {
  const _PaneHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
