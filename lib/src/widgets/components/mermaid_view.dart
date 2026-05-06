// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/mermaid/mermaid_artifact.dart';
import '../../core/mermaid/mermaid_cache.dart';
import '../../core/mermaid/mermaid_error.dart';
import '../../core/mermaid/mermaid_options.dart';
import '../../core/mermaid/mermaid_renderer.dart';
import '../../core/mermaid/mermaid_theme.dart';
import 'mermaid_artifact_view.dart';
import 'mermaid_fullscreen_viewer.dart';

/// State-machine widget that orchestrates Mermaid rendering.
class MermaidView extends StatefulWidget {
  const MermaidView({
    super.key,
    required this.source,
    required this.contentHash,
    required this.sourceComplete,
    required this.options,
    required this.cache,
    this.onIntrinsicSize,
  });

  /// Mermaid source code with the fence stripped.
  final String source;

  /// Stable hash from `ContentBlock.contentHash`.
  final int contentHash;

  /// Whether the fenced code block has closed.
  final bool sourceComplete;

  /// Mermaid rendering options.
  final MermaidOptions options;

  /// LRU cache to consult and populate.
  final MermaidCache cache;

  /// Invoked when the artifact intrinsic size becomes known.
  final void Function(Size size)? onIntrinsicSize;

  @override
  State<MermaidView> createState() => _MermaidViewState();
}

class _MermaidViewState extends State<MermaidView> {
  MermaidArtifact? _artifact;
  MermaidError? _error;
  bool _inFlight = false;
  int _currentRequestId = 0;
  String? _activeSignature;

  MermaidTheme get _resolvedTheme =>
      widget.options.theme.resolveAuto(Theme.of(context).brightness);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureRenderStarted();
  }

  @override
  void didUpdateWidget(covariant MermaidView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final inputChanged =
        oldWidget.source != widget.source ||
        oldWidget.contentHash != widget.contentHash ||
        oldWidget.sourceComplete != widget.sourceComplete ||
        oldWidget.options.theme != widget.options.theme ||
        oldWidget.options.renderer != widget.options.renderer ||
        oldWidget.options.renderTimeout != widget.options.renderTimeout;
    if (inputChanged) {
      _resetRenderState();
      _ensureRenderStarted();
    }
  }

  void _resetRenderState() {
    _currentRequestId++;
    _activeSignature = null;
    _artifact = null;
    _error = null;
    _inFlight = false;
  }

  String? _cacheKey(MermaidTheme theme) {
    final renderer = widget.options.renderer;
    if (renderer == null) return null;
    return MermaidCache.buildKey(
      contentHash: widget.contentHash,
      theme: theme,
      rendererVersion: renderer.version,
    );
  }

  void _ensureRenderStarted() {
    if (!widget.sourceComplete) return;
    final renderer = widget.options.renderer;
    if (renderer == null) return;

    final theme = _resolvedTheme;
    final cacheKey = _cacheKey(theme)!;
    final signature = '${widget.source}|$cacheKey';
    if (_activeSignature == signature &&
        (_artifact != null || _error != null || _inFlight)) {
      return;
    }

    final cached = widget.cache.get(cacheKey);
    _activeSignature = signature;
    if (cached != null) {
      _artifact = cached;
      _error = null;
      _inFlight = false;
      _notifyIntrinsicSize(cached);
      return;
    }

    _startRender(renderer, cacheKey, theme, notifyState: false);
  }

  void _startRender(
    MermaidRenderer renderer,
    String cacheKey,
    MermaidTheme theme, {
    required bool notifyState,
  }) {
    final requestId = ++_currentRequestId;
    void markInFlight() {
      _inFlight = true;
      _error = null;
      _artifact = null;
    }

    if (notifyState) {
      setState(markInFlight);
    } else {
      markInFlight();
    }

    Future<MermaidArtifact> future = Future<MermaidArtifact>.sync(
      () => renderer.render(widget.source, theme: theme),
    );
    if (widget.options.renderTimeout > Duration.zero) {
      final start = DateTime.now();
      future = future.timeout(
        widget.options.renderTimeout,
        onTimeout: () {
          throw MermaidTimeoutError(
            source: widget.source,
            elapsed: DateTime.now().difference(start),
            stackTrace: StackTrace.current,
          );
        },
      );
    }

    future.then(
      (artifact) {
        widget.cache.put(cacheKey, artifact);
        if (!mounted || requestId != _currentRequestId) return;
        setState(() {
          _artifact = artifact;
          _error = null;
          _inFlight = false;
        });
        _notifyIntrinsicSize(artifact);
      },
      onError: (Object error, StackTrace stackTrace) {
        final wrapped = _wrapError(error, stackTrace);
        widget.options.onError?.call(wrapped);
        if (!mounted || requestId != _currentRequestId) return;
        setState(() {
          _error = wrapped;
          _artifact = null;
          _inFlight = false;
        });
      },
    );
  }

  MermaidError _wrapError(Object error, StackTrace stackTrace) {
    if (error is MermaidError) return error;
    return MermaidRuntimeError(
      source: widget.source,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  void _notifyIntrinsicSize(MermaidArtifact artifact) {
    final size = artifact.intrinsicSize;
    if (size != null) widget.onIntrinsicSize?.call(size);
  }

  void _retry() {
    final renderer = widget.options.renderer;
    if (renderer == null) return;
    final theme = _resolvedTheme;
    final cacheKey = _cacheKey(theme);
    if (cacheKey == null) return;
    _activeSignature = '${widget.source}|$cacheKey';
    _startRender(renderer, cacheKey, theme, notifyState: true);
  }

  void _openFullscreen(MermaidArtifact artifact) {
    final builder = widget.options.fullscreenBuilder;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => builder != null
            ? builder(ctx, artifact)
            : MermaidFullscreenViewer(artifact: artifact),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget fallback() => _SourceFallback(source: widget.source);

    if (!widget.sourceComplete) {
      return fallback();
    }

    if (widget.options.renderer == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [const _NotConfiguredBanner(), fallback()],
      );
    }

    if (_artifact != null) {
      return MermaidArtifactView(
        artifact: _artifact!,
        onTap: widget.options.enableTapToFullscreen
            ? () => _openFullscreen(_artifact!)
            : null,
      );
    }

    if (_error != null) {
      final context_ = MermaidErrorContext(
        error: _error!,
        source: widget.source,
        retry: _retry,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          fallback(),
          widget.options.errorBuilder?.call(context, context_) ??
              _ErrorBanner(context_: context_),
        ],
      );
    }

    final initializing = !widget.options.renderer!.isReady;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        fallback(),
        if (_inFlight && !initializing)
          const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              key: Key('mermaid-inflight-spinner'),
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (initializing)
          const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              key: Key('mermaid-initializing-spinner'),
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

class _SourceFallback extends StatelessWidget {
  const _SourceFallback({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SelectableText(
        source,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }
}

class _NotConfiguredBanner extends StatelessWidget {
  const _NotConfiguredBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mermaid-not-configured-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.grey.shade300,
      child: const Text(
        'Mermaid renderer not configured. See README.',
        style: TextStyle(fontSize: 12),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.context_});

  final MermaidErrorContext context_;

  String get _label {
    final error = context_.error;
    if (error is MermaidSyntaxError) {
      return 'Mermaid syntax error: ${error.message}';
    }
    if (error is MermaidTimeoutError) {
      return 'Mermaid render timeout (${error.elapsed.inMilliseconds}ms)';
    }
    if (error is MermaidInvalidOutputError) return 'Mermaid output invalid';
    if (error is MermaidInitializationError) {
      return 'Mermaid initialization failed';
    }
    return 'Mermaid render failed';
  }

  bool get _showRetry =>
      context_.error is MermaidTimeoutError ||
      context_.error is MermaidRuntimeError ||
      context_.error is MermaidInvalidOutputError;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mermaid-error-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _label,
              style: TextStyle(fontSize: 12, color: Colors.red.shade900),
            ),
          ),
          if (_showRetry)
            TextButton(onPressed: context_.retry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
