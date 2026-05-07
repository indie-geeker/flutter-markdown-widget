// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// ignore_for_file: experimental_member_use

import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';

class MermaidDemoScope extends InheritedWidget {
  const MermaidDemoScope({
    super.key,
    required this.renderer,
    required super.child,
  });

  final MermaidRenderer renderer;

  static MermaidRenderer of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw FlutterError('No MermaidDemoScope found in context.');
    }
    return scope.renderer;
  }

  static MermaidDemoScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MermaidDemoScope>();
  }

  @override
  bool updateShouldNotify(MermaidDemoScope oldWidget) {
    return renderer != oldWidget.renderer;
  }
}
