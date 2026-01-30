// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';

class StreamingDemoPage extends StatefulWidget {
  const StreamingDemoPage({super.key});

  @override
  State<StreamingDemoPage> createState() => _StreamingDemoPageState();
}

class _StreamingDemoPageState extends State<StreamingDemoPage> {
  StreamController<String>? _streamController;
  bool _isStreaming = false;
  bool _disposed = false;
  double _speed = 2.0;
  String _accumulatedContent = '';

  static const _aiResponse = '''
# 🚀 Understanding Flutter State Management

When building Flutter applications, **state management** is one of the most important concepts to master. Let me explain the key concepts.

## 📚 What is State?

State refers to any data that can change over time and affects your UI. There are two main types:

1. **Ephemeral State** — Local to a single widget
2. **App State** — Shared across multiple widgets

## 🔧 Popular Solutions

### Provider

The simplest approach for most apps:

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

A more modern, type-safe approach:

```dart
final counterProvider = StateNotifierProvider<Counter, int>(
  (ref) => Counter(),
);
```

### BLoC Pattern

Great for complex business logic:

- Separates UI from business logic
- Uses streams for reactive updates
- Excellent for testing

## ✅ Recommendation

For most applications, I recommend starting with **Provider** or **Riverpod**:

| Solution | Learning Curve | Flexibility |
|----------|---------------|-------------|
| Provider | Easy | Good |
| Riverpod | Medium | Excellent |
| BLoC | Steep | Maximum |

---

*Hope this helps! Let me know if you have questions.* 🎉
''';

  void _startStreaming() {
    setState(() {
      _isStreaming = true;
      _accumulatedContent = '';
      _streamController = StreamController<String>();
    });

    _simulateStreaming();
  }

  Future<void> _simulateStreaming() async {
    // Use runes to properly iterate over Unicode characters (not code units)
    // This prevents splitting multi-byte characters like emoji
    final chunks = _aiResponse.runes.map((r) => String.fromCharCode(r)).toList();
    int delay = (20 / _speed).round();

    for (int i = 0; i < chunks.length; i++) {
      // Check _disposed flag to handle widget disposal during streaming
      if (_disposed || !_isStreaming || _streamController == null) break;

      _accumulatedContent += chunks[i];
      _streamController!.add(chunks[i]);
      
      // Vary delay based on character
      if (chunks[i] == '\n') {
        await Future.delayed(Duration(milliseconds: delay * 4));
      } else if (chunks[i] == ' ') {
        await Future.delayed(Duration(milliseconds: delay ~/ 2));
      } else {
        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    // Only call _stopStreaming if widget is not disposed
    if (!_disposed) {
      _stopStreaming();
    }
  }

  void _stopStreaming() {
    // Always update the flag to ensure the streaming loop breaks
    _isStreaming = false;
    // Only call setState if not disposed
    if (!_disposed) {
      setState(() {});
    }
    _streamController?.close();
    _streamController = null;
  }

  void _reset() {
    _stopStreaming();
    if (!_disposed) {
      setState(() {
        _accumulatedContent = '';
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _isStreaming = false;
    _streamController?.close();
    _streamController = null;
    super.dispose();
  }

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
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('AI Streaming'),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_isStreaming)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.stop_rounded, size: 18, color: Colors.red),
                ),
                onPressed: _stopStreaming,
              ),
            )
          else if (_accumulatedContent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onPressed: _reset,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Speed control bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.speed_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Speed',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF8B5CF6),
                      inactiveTrackColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      thumbColor: const Color(0xFF8B5CF6),
                      overlayColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: _speed,
                      min: 0.5,
                      max: 5.0,
                      divisions: 9,
                      onChanged: (v) => setState(() => _speed = v),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_speed.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content area
          Expanded(
            child: Container(
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
                child: _streamController != null
                    ? StreamingMarkdownView.fromStream(
                        stream: _streamController!.stream,
                        padding: const EdgeInsets.all(24),
                        streamingOptions: const StreamingOptions(
                          showTypingCursor: true,
                          autoScrollToBottom: true,
                          bufferMode: BufferMode.byCharacter,
                        ),
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
                      )
                    : _accumulatedContent.isNotEmpty
                        ? StreamingMarkdownView(
                            content: _accumulatedContent,
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
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                        const Color(0xFF6366F1).withValues(alpha: 0.1),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.smart_toy_outlined,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Ready to Stream',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Press the button below to start AI streaming',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !_isStreaming && _accumulatedContent.isEmpty
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                onPressed: _startStreaming,
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                elevation: 8,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Start Streaming',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
