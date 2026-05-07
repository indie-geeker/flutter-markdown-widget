// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/mermaid/mermaid_artifact.dart';

/// Pure-display widget for a resolved [MermaidArtifact].
class MermaidArtifactView extends StatelessWidget {
  const MermaidArtifactView({
    super.key,
    required this.artifact,
    this.onTap,
    this.onLaidOutSize,
  });

  /// Resolved Mermaid SVG artifact.
  final MermaidArtifact artifact;

  /// Optional tap callback, commonly used to open fullscreen.
  final VoidCallback? onTap;

  /// Invoked after layout with the size used to display the artifact.
  final ValueChanged<Size>? onLaidOutSize;

  static const double _fallbackAspectRatio = 16 / 9;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspect =
            artifact.intrinsicSize != null &&
                artifact.intrinsicSize!.width > 0 &&
                artifact.intrinsicSize!.height > 0
            ? artifact.intrinsicSize!.width / artifact.intrinsicSize!.height
            : _fallbackAspectRatio;
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (artifact.intrinsicSize?.width ?? 600.0);
        final height = width / aspect;
        final laidOutSize = Size(width, height);

        if (onLaidOutSize != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onLaidOutSize?.call(laidOutSize);
          });
        }

        Widget content = SizedBox(
          key: const Key('mermaid-artifact-sized-box'),
          width: width,
          height: height,
          child: SvgPicture.string(
            artifact.svg,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => const SizedBox.shrink(),
          ),
        );
        if (onTap != null) {
          content = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: content,
          );
        }
        return content;
      },
    );
  }
}
