// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// ignore_for_file: experimental_member_use

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_markdown_widget_mermaid/flutter_markdown_widget_mermaid.dart';

import '../mermaid/mermaid_demo_scope.dart';
import '../pages/home_page.dart';
import 'app_theme.dart';

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key, this.mermaidRenderer, this.home});

  final MermaidRenderer? mermaidRenderer;
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    final renderer = mermaidRenderer ?? MermaidWebViewRenderer.shared();

    return MaterialApp(
      title: 'Flutter Markdown Widget Demo',
      debugShowCheckedModeBanner: false,
      theme: ExampleTheme.light(),
      darkTheme: ExampleTheme.dark(),
      themeMode: ThemeMode.system,
      home: home ?? const HomePage(),
      builder: (context, child) {
        final body = child ?? const SizedBox.shrink();
        return MermaidDemoScope(
          renderer: renderer,
          child: MermaidWebViewHost(renderer: renderer, child: body),
        );
      },
    );
  }
}
