// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/mermaid/mermaid_artifact.dart';

/// Fullscreen viewer for a Mermaid artifact with pan and zoom.
class MermaidFullscreenViewer extends StatelessWidget {
  const MermaidFullscreenViewer({super.key, required this.artifact});

  /// Resolved Mermaid SVG artifact.
  final MermaidArtifact artifact;

  @override
  Widget build(BuildContext context) {
    final png = artifact.rasterPng;
    final Widget content = png != null && png.isNotEmpty
        ? Image.memory(
            png,
            key: const Key('mermaid-fullscreen-png'),
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          )
        : SvgPicture.string(
            artifact.svg,
            key: const Key('mermaid-fullscreen-svg'),
            fit: BoxFit.contain,
          );
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 8.0,
                child: Center(child: content),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
