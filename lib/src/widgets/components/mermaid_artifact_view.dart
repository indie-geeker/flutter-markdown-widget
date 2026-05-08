// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/mermaid/mermaid_artifact.dart';

const Key _mermaidArtifactImageKey = Key('mermaid-artifact-png');
const Key _mermaidArtifactSvgKey = Key('mermaid-artifact-svg');

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

  /// Default cap on the inline display height when the parent imposes no
  /// finite `maxHeight`. Prevents tall flowcharts from blowing past the
  /// viewport — users can tap to fullscreen for the full diagram.
  static const double _defaultInlineMaxHeight = 480;

  /// Maximum upscale factor relative to the artifact's intrinsic (viewBox)
  /// size. The browser-rasterized PNG has fixed resolution; stretching beyond
  /// this multiple produces visible blur, so we cap and let extra column
  /// width stay empty rather than amplifying pixel noise.
  static const double _maxUpscale = 2.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final intrinsic = artifact.intrinsicSize;
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (intrinsic?.width ?? 600.0);
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : _defaultInlineMaxHeight;

        double width;
        double height;
        if (intrinsic != null &&
            intrinsic.width > 0 &&
            intrinsic.height > 0) {
          final aspect = intrinsic.width / intrinsic.height;
          // Fit-by-width first, then shrink by height if it would overflow.
          width = maxW;
          height = width / aspect;
          if (height > maxH) {
            height = maxH;
            width = height * aspect;
          }
          // Cap upscale relative to intrinsic so the PNG stays crisp.
          final maxByNatural = intrinsic.width * _maxUpscale;
          if (width > maxByNatural) {
            width = maxByNatural;
            height = width / aspect;
          }
        } else {
          width = maxW;
          height = width / _fallbackAspectRatio;
        }

        final laidOutSize = Size(width, height);

        if (onLaidOutSize != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onLaidOutSize?.call(laidOutSize);
          });
        }

        final png = artifact.rasterPng;
        // Wrap in Align so the inner SizedBox can shrink below the parent's
        // (often tight) width constraint when the upscale cap kicks in.
        // Without this the SizedBox would be forced to fill the parent width
        // and the cap would never visibly take effect.
        Widget content = Align(
          alignment: Alignment.center,
          child: SizedBox(
            key: const Key('mermaid-artifact-sized-box'),
            width: width,
            height: height,
            child: png != null && png.isNotEmpty
                ? Image.memory(
                    png,
                    key: _mermaidArtifactImageKey,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                  )
                : SvgPicture.string(
                    artifact.svg,
                    key: _mermaidArtifactSvgKey,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => const SizedBox.shrink(),
                  ),
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
