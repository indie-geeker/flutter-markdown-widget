// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import 'app_theme.dart';

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Markdown Widget Demo',
      debugShowCheckedModeBanner: false,
      theme: ExampleTheme.light(),
      darkTheme: ExampleTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
