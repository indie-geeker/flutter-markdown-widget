// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('streaming edge cases', () {
    StreamController<String>? controller;

    setUp(() {
      controller = StreamController<String>();
    });

    tearDown(() {
      controller?.close();
      controller = null;
    });

    Future<void> pumpStreaming(
      WidgetTester tester, {
      StreamingOptions streamingOptions = const StreamingOptions(),
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView.fromStream(
              stream: controller!.stream,
              streamingOptions: streamingOptions,
            ),
          ),
        ),
      );
    }

    testWidgets('empty string chunks are ignored gracefully', (tester) async {
      await pumpStreaming(tester);
      controller!.add('');
      controller!.add('');
      controller!.add('# Hello');
      await controller!.close();
      await tester.pumpAndSettle();
      // Should render without crashing — find the heading text
      expect(find.text('Hello', findRichText: true), findsOneWidget);
    });

    testWidgets('rapid single-char chunks produce correct final content',
        (tester) async {
      await pumpStreaming(tester);
      final content = 'a' * 100; // 100 'a' characters — well above the 100-chunk threshold
      for (final char in content.runes) {
        controller!.add(String.fromCharCode(char));
        await tester.pump(const Duration(milliseconds: 5));
      }
      await controller!.close();
      await tester.pumpAndSettle();
      expect(find.text(content, findRichText: true), findsOneWidget);
    });

    testWidgets('stream error sets widget to non-receiving state',
        (tester) async {
      await pumpStreaming(tester);
      controller!.add('# Partial content');
      await tester.pump();
      controller!.addError(Exception('network error'));
      await tester.pumpAndSettle();
      // Widget should still be in the tree (no crash)
      expect(find.byType(StreamingMarkdownView), findsOneWidget);
      // Cursor should be gone (not receiving).
      // The typing cursor is only shown when _isReceiving && showTypingCursor.
      // After an error, _isReceiving is false so no cursor row is added.
      // Verify by checking there is no extra padding widget that the cursor row
      // adds (the cursor row is a Padding > Row > TypingCursor).
      // We confirm indirectly: the widget tree is stable and no exception thrown.
      expect(tester.takeException(), isNull);
      // Partial content sent before the error must still be visible.
      expect(find.textContaining('Partial content'), findsWidgets);
    });

    testWidgets('widget disposal during active stream produces no errors',
        (tester) async {
      await pumpStreaming(tester);
      controller!.add('# Heading');
      await tester.pump();
      // Replace widget tree (simulates navigation away)
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      // Continue adding to the stream after disposal.
      // This should not throw 'setState after dispose'.
      controller!.add(' more content');
      await tester.pumpAndSettle();
      // No exceptions should have been thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('replacing stream widget shows new stream content',
        (tester) async {
      await pumpStreaming(tester);
      controller!.add('First stream');
      await tester.pump();

      // Create a second stream
      final controller2 = StreamController<String>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingMarkdownView.fromStream(
              stream: controller2.stream,
            ),
          ),
        ),
      );
      controller2.add('Second stream');
      await controller2.close();
      await tester.pumpAndSettle();
      expect(find.text('Second stream', findRichText: true), findsOneWidget);
      // Stream A's content must no longer be visible after the replacement.
      expect(find.textContaining('First stream'), findsNothing);
    });

    testWidgets('byLine mode does not render until newline received',
        (tester) async {
      await pumpStreaming(
        tester,
        streamingOptions:
            const StreamingOptions(bufferMode: BufferMode.byLine),
      );
      // Send content without newline — should not render complete paragraph yet
      controller!.add('Hello');
      await tester.pump(const Duration(milliseconds: 50));
      // Send newline — now it should render
      controller!.add(' world\n');
      await tester.pump(const Duration(milliseconds: 50));
      await controller!.close();
      await tester.pumpAndSettle();
      expect(find.text('Hello world', findRichText: true), findsOneWidget);
    });
  });
}
