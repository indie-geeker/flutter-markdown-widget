# Mermaid Rendering — Design Spec

**Status:** Draft, ready for plan
**Date:** 2026-05-06
**Owner:** indiegeeker
**Project positioning:** `flutter-markdown-widget` remains a read-only renderer. Editor capabilities (block editing, toolbar, live preview) are out of scope and belong to a separate downstream package.
**Sub-project context:** First of 5 prioritized sub-projects under the read-only renderer roadmap. Risk-first ordering: Mermaid → Block ID → LaTeX → Code blocks → Images.

---

## 1. Goal

Add Mermaid diagram rendering to the markdown widget for both static documents and LLM streaming output, without compromising the existing performance baseline (incremental parser, virtual scrolling, widget cache, dimension estimator).

### Success criteria

- ` ```mermaid ` fenced code blocks render as diagrams when a renderer is configured.
- Streaming behavior is deterministic: source code visible until the block closes, then a single transition to the diagram (or a single transition to a code block + error banner on failure).
- Cache hit path produces a stable layout (no height jumps on revisit).
- Zero new runtime dependency in the main package.
- Zero breaking change for existing users (defaults preserve current behavior).

### Non-goals

- Editor / live preview / write capability.
- Pure-Dart Mermaid parser. We rely on `mermaid.js`.
- Web-platform first-class support in the initial release (deferred).
- SVG-equivalence golden tests (too brittle across `mermaid.js` versions).

---

## 2. Architecture

### 2.1 Package layout

```
flutter_markdown_widget/                          # main, zero new runtime deps
├── lib/src/
│   ├── core/parser/                              # unchanged: mermaid arrives as fenced code block
│   ├── builder/element_builders/
│   │   └── (route ` ```mermaid ` to MermaidView in ContentBuilder)
│   ├── widgets/components/
│   │   ├── mermaid_view.dart                     # state machine
│   │   └── mermaid_fullscreen_viewer.dart        # tap-to-fullscreen
│   ├── core/mermaid/
│   │   ├── mermaid_renderer.dart                 # abstract interface
│   │   ├── mermaid_artifact.dart                 # render output + intrinsicSize
│   │   ├── mermaid_cache.dart                    # LRU
│   │   ├── mermaid_options.dart                  # public config
│   │   └── mermaid_error.dart                    # sealed error hierarchy
│   ├── testing/
│   │   └── fake_mermaid_renderer.dart            # exported via testing.dart
│   └── config/render_options.dart                # add mermaidOptions
└── test/...

flutter_markdown_widget_mermaid/                  # separate package
├── lib/
│   └── src/
│       ├── flutter_js_mermaid_renderer.dart      # default impl
│       └── assets/mermaid.min.js                 # bundled, version pinned
└── pubspec.yaml                                  # depends: flutter_js, flutter_markdown_widget
```

The main package never imports `flutter_js`. The boundary is a `MermaidRenderer` interface.

### 2.2 Public API surface (main package)

```dart
abstract class MermaidRenderer {
  Future<MermaidArtifact> render(String source, {required MermaidTheme theme});
  bool get isReady;
  /// Stable identifier for the renderer + underlying mermaid.js version.
  /// Used as part of the cache key (§4.1). Example: "flutter-js-1.0.0+mermaid-10.6.0".
  String get version;
  Future<void> dispose();
}

class MermaidArtifact {
  final String svg;
  final Size? intrinsicSize;     // parsed from SVG viewBox
}

enum MermaidTheme { auto, light, dark, neutral, forest }

class MermaidOptions {
  final MermaidRenderer? renderer;                 // null → degrade to code block
  final MermaidTheme theme;
  final bool enableTapToFullscreen;
  final Duration renderTimeout;                    // default 5s
  final int cacheCapacity;                         // default 32
  final MermaidCache? cache;                       // optional shared instance
  final void Function(MermaidError)? onError;
  final Widget Function(BuildContext, MermaidArtifact)? fullscreenBuilder;
  final Widget Function(BuildContext, MermaidErrorContext)? errorBuilder;
}

sealed class MermaidError {
  final String source;
  final StackTrace stackTrace;
}

class MermaidSyntaxError extends MermaidError { final String message; }
class MermaidTimeoutError extends MermaidError { final Duration elapsed; }
class MermaidRuntimeError extends MermaidError { final Object cause; }
class MermaidInvalidOutputError extends MermaidError { final String svg; }
class MermaidInitializationError extends MermaidError { final Object cause; }

class MermaidErrorContext {
  final MermaidError error;
  final String source;
  final VoidCallback retry;
}
```

`MermaidRenderer` is annotated `@experimental` for its first release cycle.

### 2.3 `MermaidView` state machine

```
┌─ source incomplete (fence not closed)
│   → render as CodeBlockView (existing path)
│
├─ source complete + renderer == null
│   → render as CodeBlockView + grey banner "Mermaid renderer not configured"
│
├─ source complete + renderer != null
│   ├─ cache hit  → MermaidArtifactView (synchronous, stable height)
│   └─ cache miss
│       ├─ initiate render Future
│       ├─ in-flight → CodeBlockView + bottom spinner
│       ├─ success → setState(artifact) + cache.put + estimator.update
│       └─ failure → CodeBlockView + red banner; do NOT cache
```

Concurrency safeguards:

- Each in-flight render holds a monotonic `_requestId`. On completion, it's compared against the current `state._currentRequestId`; mismatched results are dropped.
- `dispose()` does not cancel the future — cache writes still go through. `setState` is gated on `mounted`.

---

## 3. Data flow & lifecycle

### 3.1 Parse

` ```mermaid ` blocks come out of `package:markdown` as fenced code blocks with `language == 'mermaid'`. Both `AstMarkdownParser` and `IncrementalMarkdownParser` already produce these. **No new syntax is introduced.** This is critical for streaming safety.

### 3.2 Build

`ContentBuilder._buildCodeBlock` checks language and routes:

```dart
if (block.language == 'mermaid' && options.mermaidOptions?.renderer != null) {
  return MermaidView(
    source: block.rawContent,
    contentHash: block.contentHash,
    options: options.mermaidOptions!,
    theme: _resolvedMermaidTheme(context),
    cache: options.mermaidOptions!.cache ?? _defaultCache,
    onIntrinsicSize: _dimensionEstimator?.update,
  );
}
return CodeBlockView(...);
```

### 3.3 Cache miss render timeline

```
T0  build()
    ├─ cache.get(key) → miss
    └─ return CodeBlockView + spinner (build returns synchronously)

T0+ε  initState / didUpdateWidget
    └─ start renderer.render(source, theme)
        with timeout = options.renderTimeout

T1  Future resolves
    success:
      ├─ if (mounted && _currentRequestId matches) setState(artifact)
      ├─ cache.put(key, artifact)              # always, even if !mounted
      └─ onIntrinsicSize?.call(blockIndex, computedSize)
    failure:
      ├─ if (mounted && id matches) setState(error)
      ├─ NOT cached
      └─ options.onError?.call(error)
```

### 3.4 Theme switching mid-flight

`didUpdateWidget` detects theme change. The current `_currentRequestId` is incremented (causing in-flight result to be dropped on arrival). A new render is initiated with the new theme. Cache key includes theme, so old SVG is not reused.

### 3.5 Renderer lifecycle (subpackage)

- **Lazy init**: `mermaid.js` is loaded inside `flutter_js` on the **first** `render()` call. `isReady` returns `false` during init.
- **`shared()` per platform**: `FlutterJsMermaidRenderer.shared()` returns a process-global instance on supported platforms (iOS/Android/macOS). On unsupported platforms (Web in M2, also Windows/Linux when `flutter_js` upstream lacks support), it returns a `_UnsupportedRenderer` whose `render()` always throws `MermaidInitializationError` and whose `isReady` is permanently `false`. JsRuntime is expensive (~50MB), so the supported-platform instance is shared across all `MarkdownWidget`s in the app.
- **Concurrent calls during init**: Internal `Completer<void>` ensures only one load happens; concurrent `render()` calls await the same completer.
- **Init failure**: If init fails (e.g., asset not bundled, JsRuntime crash), the completer completes with an error. The renderer's `isReady` stays `false` permanently. All subsequent `render()` calls throw `MermaidInitializationError` synchronously (not pending).
- **Dispose**: not auto-disposed. If the host explicitly calls `dispose()`, JsRuntime is released; subsequent `render()` calls throw `MermaidInitializationError` (treated by `MermaidView` the same as init-failure path).

### 3.6 Theme resolution

```dart
MermaidTheme _resolvedMermaidTheme(BuildContext context) {
  final t = options.mermaidOptions?.theme ?? MermaidTheme.auto;
  if (t != MermaidTheme.auto) return t;
  return Theme.of(context).brightness == Brightness.dark
      ? MermaidTheme.dark
      : MermaidTheme.light;
}
```

---

## 4. Caching & sizing

### 4.1 Cache key

```
{contentHash}:{theme}:{rendererVersion}
```

- `contentHash`: from `ContentBlock.contentHash`, already exists in both parsers.
- `theme`: `MermaidTheme.toString()`.
- `rendererVersion`: read from `MermaidRenderer.version` (see §2.2). Subpackages declare this as `"flutter-js-<pkg-version>+mermaid-<js-version>"`. When the subpackage upgrades `mermaid.js`, the version string changes, invalidating all cached entries on next access (LRU naturally evicts old entries).

### 4.2 Layered design

- **Renderer layer** does **not** cache. `render()` is treated as a pure function; each call goes through `mermaid.js`. Rationale: separation of concerns, predictable subpackage memory.
- **`MermaidCache` layer** lives in the main package and is the only cache. Default capacity 32 (per `MarkdownWidget` instance).

### 4.3 Cache scope

Default: **per `MarkdownWidget` instance**, owned by the inner `ContentBuilder`. Reasons:

- Long documents released → memory reclaimed naturally.
- Documents rarely share Mermaid source.

Override: `MermaidOptions.cache` accepts an external `MermaidCache` instance (e.g., `AppMermaidCache.shared`) for cross-document sharing.

### 4.4 Sizing protocol

Three-phase contract with `BlockDimensionEstimator`:

| Phase | State | Height source |
|-------|-------|---------------|
| A | Source incomplete (streaming) | `CodeBlockView` natural height |
| B | Source complete + render in-flight | `CodeBlockView` natural height (do NOT pre-allocate diagram space) |
| C | Render success | SVG `intrinsicSize` scaled to container width; `estimator.update` called once after first layout |

Cache hit path skips A/B and lands in C synchronously — first layout is already correct.

### 4.5 Intrinsic size extraction

Subpackage parses `<svg viewBox="0 0 W H">` from the rendered SVG and populates `MermaidArtifact.intrinsicSize = Size(W, H)`. `MermaidView` uses `LayoutBuilder` to scale to container width:

```dart
final scale = constraints.maxWidth / intrinsicSize.width;
final renderHeight = intrinsicSize.height * scale;
```

If `viewBox` is missing or unparseable, `intrinsicSize == null` and `BlockDimensionEstimator` falls back to its own measurement after first layout.

### 4.6 Overflow handling

When the rendered SVG would shrink text below readability on narrow viewports, **no automatic horizontal scroll**. The user taps to enter `MermaidFullscreenViewer` for pan/zoom inspection.

---

## 5. Error handling

### 5.1 Failure mode matrix

| # | Scenario | Trigger point | UI behavior | Cached? |
|---|----------|---------------|-------------|---------|
| F1 | `renderer == null` | sync build path | `CodeBlockView` + grey banner "Mermaid renderer not configured. See README." | — |
| F2 | Mermaid syntax error | subpackage catches `mermaid.js` throw | `CodeBlockView` + red bottom banner with error message | No |
| F3 | Render timeout (`renderTimeout` exceeded) | `Future.timeout` | `CodeBlockView` + red banner "Mermaid render timeout" + retry button | No |
| F4 | Other runtime failure (JS engine crash, etc.) | `Future.catchError` | `CodeBlockView` + red banner "Mermaid render failed" + retry button | No |
| F5 | Invalid SVG output (e.g., missing `viewBox`, `flutter_svg` parse error) | SVG parsing in `MermaidArtifactView` | `CodeBlockView` + red banner "Mermaid output invalid" | No |
| F6 | Renderer initialization failure (e.g., `mermaid.js` load failure) | First `render()` call inside subpackage | All Mermaid blocks in this `MarkdownWidget` degrade to F1 behavior for the lifetime of the renderer | — |
| F7 | Stale future (source/theme changed before render completed) | request-id mismatch on resolution | Result silently discarded | No |

### 5.2 Principles

- **Always show something**: every failure path falls back to the source code as a regular code block. No blank states.
- **Failures are isolated**: one block's failure does not affect others. Exception: F6, but it only degrades, never crashes.
- **No automatic retry**: F3/F4 expose a retry button; the library does not auto-retry. LLM streaming may produce intentionally-incorrect source; auto-retry would amplify load.

### 5.3 `onError` hook

Library never throws. All errors are wrapped in `MermaidError` subtypes and routed to:

- The `MermaidView` itself (drives UI).
- `options.onError` (host application; e.g., Sentry).

The host is expected to throttle reporting if appropriate, since failed sources are not cached and may re-trigger on every rebuild.

### 5.4 Initialization waiting state

When `renderer.isReady == false` and no render attempt has yet failed for this `MermaidView`, show a `CodeBlockView` overlaid with a small "Initializing Mermaid…" spinner. This is **not** an error state — it transitions to the normal in-flight state once initialization completes.

**Distinguishing pending init from permanent failure**: `MermaidView` always calls `render()` even when `isReady == false`. If init succeeds, the future resolves with an artifact (success path). If init has failed permanently, `render()` throws `MermaidInitializationError` synchronously (per §3.5), which `MermaidView` catches and routes to the F6 path. This eliminates the "spinner forever" failure mode: a permanently-failed renderer cannot stay in the spinner state because every `render()` call returns immediately with the error.

---

## 6. Testing strategy

### 6.1 Pyramid (per package)

```
                  E2E in example app  (manual smoke)
            ┌─────────────────────────────────────┐
            │ Widget tests (main pkg)             │ ← primary
            │ MermaidView state machine, all paths│
            └─────────────────────────────────────┘
       ┌──────────────────────────────────────────────┐
       │ Unit tests (main pkg, FakeMermaidRenderer)   │ ← primary
       │ Cache, errors, theme, sizing, lifecycle      │
       └──────────────────────────────────────────────┘
  ┌─────────────────────────────────────────────────────┐
  │ Subpackage tests (FlutterJsMermaidRenderer)         │ ← isolated CI
  │ Real flutter_js render contract, lazy init, concurrency│
  └─────────────────────────────────────────────────────┘
```

Main-package CI never depends on `flutter_js`. All main-package tests use `FakeMermaidRenderer`.

### 6.2 `FakeMermaidRenderer`

Exported via `package:flutter_markdown_widget/testing.dart`. Available to host apps for their own widget tests.

```dart
class FakeMermaidRenderer implements MermaidRenderer {
  Duration latency = Duration.zero;
  Object? errorToThrow;
  bool simulateNotReady = false;
  String Function(String source)? svgBuilder;
  final List<MermaidRenderCall> calls = [];

  @override
  Future<MermaidArtifact> render(String source, {required MermaidTheme theme}) async {
    calls.add(MermaidRenderCall(source: source, theme: theme));
    if (latency != Duration.zero) await Future.delayed(latency);
    if (errorToThrow != null) throw errorToThrow!;
    final svg = svgBuilder?.call(source) ?? _defaultSvg(source);
    return MermaidArtifact(svg: svg, intrinsicSize: const Size(800, 400));
  }

  @override
  bool get isReady => !simulateNotReady;

  @override
  String get version => 'fake-1.0.0';

  @override
  Future<void> dispose() async {}
}
```

### 6.3 Required test coverage (main package)

#### A. `MermaidView` state machine (widget tests)

| ID | Input | Expected |
|----|-------|----------|
| A1 | source incomplete (streaming) | renders `CodeBlockView`; renderer never called |
| A2 | source complete + renderer null | `CodeBlockView` + "not configured" banner |
| A3 | source complete + ready + cache miss | spinner shown; renderer called once |
| A4 | source complete + cache hit | SVG shown synchronously; renderer not called |
| A5 | render success | spinner → SVG; cache.put called |
| A6 | render fails with `MermaidSyntaxError` | spinner → CodeBlockView + red banner |
| A7 | render times out | red banner + retry button |
| A8 | retry tapped | renderer called again, no new cache entry on failure |
| A9 | source change via `didUpdateWidget` | old future result discarded; new future started |
| A10 | theme switch (auto + brightness flip) | cache key changes; new render initiated |
| A11 | dispose during in-flight render | no `setState` call; cache write still occurs |
| A12 | `renderer.isReady == false` | "Initializing…" spinner over CodeBlockView |

#### B. `MermaidCache` (unit tests)

- LRU ordering (put/get reorders; oldest evicted)
- `capacity = 0` behaves like a no-op (always miss)
- Key composition stable across runs
- `invalidate(prefix)` clears matching entries

#### C. `ContentBuilder` integration (widget tests)

- ` ```mermaid ` routes to `MermaidView`; ` ```dart ` stays on `CodeBlockView`
- Multiple Mermaid blocks share the same per-widget cache instance
- `RenderOptions.mermaidCache` (when provided) is used in place of the default

#### D. Cross-parser consistency (mandatory; explicit lesson from Block ID plan)

For a fixed input, `AstMarkdownParser` and `IncrementalMarkdownParser` must produce:

- The same `language == 'mermaid'` detection.
- The same `rawContent` (no leading/trailing newline divergence).
- The same `contentHash` (so cache hits across parser modes).

Failure of D would produce silent cache misses or visual drift between modes; this test is non-negotiable.

#### E. Sizing integration (widget tests)

- Cache hit: first layout height = scaled SVG intrinsic size.
- Cache miss phase B: height equals `CodeBlockView` height (no premature pre-allocation).
- Cache miss phase C: `BlockDimensionEstimator.update` invoked exactly once with the post-layout size.

### 6.4 Subpackage tests

Independent CI (heavier dependencies):

- Render contract: fixed source → SVG contains expected node markers. **No full SVG diff.**
- Lazy init: `isReady == false` before first render; `true` after.
- Concurrency: multiple `render()` calls during init resolve in correct order.
- Platform smoke: minimal fixture on iOS / Android / macOS. Linux/Windows/Web marked skip or run on a separate job.

### 6.5 Out of scope for this milestone

- **No SVG golden tests** (too brittle).
- **No `flutter_js` testing in main package** (boundary violation).
- **No fullscreen-viewer gesture tests** (deferred until viewer ships).

### 6.6 Performance baseline

Add `example/test/benchmark_mermaid_test.dart`:

- 1 Mermaid block + 100 paragraphs; measure `build` time.
- Cache hit vs miss baseline.

Not gated in CI; used for regression monitoring.

---

## 7. Rollout

### 7.1 Milestones

#### M1 — Main package infrastructure (no renderer implementation)

Deliverables:

- All public types in §2.2.
- `MermaidView` state machine.
- `ContentBuilder` routing.
- `FakeMermaidRenderer` exported via `testing.dart`.
- All §6.3 tests passing.

Version: main package minor bump (e.g., 0.x.0+1 → 0.(x+1).0). Non-breaking; defaults preserve current behavior.

Standalone value: power users with their own SVG generation (backend, prebuilt) can integrate immediately.

#### M2 — Default renderer subpackage

Deliverables:

- `flutter_markdown_widget_mermaid` package.
- `FlutterJsMermaidRenderer.shared()`.
- Bundled `mermaid.js` (version pinned, recorded in subpackage README).
- iOS / Android / macOS CI green.
- §6.4 subpackage tests passing.

Version: `flutter_markdown_widget_mermaid` 0.1.0 (independent SemVer from main).

#### M3 — Example + docs

Deliverables:

- "Mermaid Showcase" page in example app (streaming + static + error samples).
- README section in main package (covers both integration paths).
- AGENTS.md / claude-mem observation index updated.

### 7.2 Platform matrix (M2)

| Platform | Status | Notes |
|----------|--------|-------|
| iOS | ✅ Supported, CI gate | Primary target |
| Android | ✅ Supported, CI gate | Primary target |
| macOS | ✅ Supported, CI gate | |
| Windows | ⚠️ Best-effort | Depends on `flutter_js` upstream; not gated |
| Linux | ⚠️ Best-effort | Same |
| Web | ❌ Not supported in M2 | `_UnsupportedRenderer` returned by `shared()`; degrades to F1 path. Deferred for native browser-level integration. |

### 7.3 Compatibility

- **Zero breaking change**: `MermaidOptions` is null by default. Existing code is unaffected.
- **Existing ` ```mermaid ` blocks**: render as plain code blocks (current behavior) until a renderer is configured.
- **API stability**: `MermaidRenderer` annotated `@experimental` for first cycle.

---

## 8. Deferred work

In priority order:

1. Web platform native support (`HtmlElementView` or dart:js script injection).
2. Long-press menu (copy source, copy SVG, save as PNG).
3. Inline pinch-zoom (gesture conflict resolution).
4. Mermaid theme variables (`themeVariables`, `themeCSS`) beyond the 4 built-ins.
5. Cross-`MarkdownWidget` cache sharing best practices + factory helpers.
6. `mermaid.js` version injection (host app supplies its own JS string).
7. Pre-rendered / SSR mode (build-time SVG embedded in markdown frontmatter).
8. Renderer running in a Dart isolate (after benchmark proves UI-thread blocking is observable).
9. Error highlight on the offending source line.
10. Special path for SVG → PDF export.

---

## 9. Known risks

| Risk | Mitigation | Trigger response |
|------|------------|------------------|
| `flutter_js` maintenance health declines | Renderer interface is pluggable; main package is decoupled | Switch backing engine (e.g., `js_runtime`) without main-package changes |
| `mermaid.js` minified bundle size growth (~2MB today) | Version pinned in subpackage | Expose JS-string injection (deferred 6) |
| QuickJS crashes on specific Android devices | Subpackage wraps in try/catch; falls into F4 | `onError` lets host report; investigate per device |
| `flutter_svg` cannot render certain Mermaid SVG attributes | F5 fallback is graceful | File `flutter_svg` issue or evaluate `jovial_svg` |
| 32-entry LRU insufficient for some users | `MermaidOptions.cacheCapacity` exposed | Users tune; revisit default if telemetry shows |

---

## 10. Open questions for the implementation plan

These aren't blockers for the spec but should be resolved before/during the plan:

1. Exact `flutter_js` package choice and version (need to verify maintenance status before M2 starts).
2. `mermaid.js` version to bundle in M2 (latest stable at plan time; documented).
3. Whether `MermaidView` should expose a public `revalidate()` method or whether retry is internal-only.
4. Exact telemetry surface for the performance baseline (build duration, cache hit rate).

---

## 11. References

- Block ID plan analysis (lessons learned about cross-parser consistency): `docs/plans/2026-05-06-obsidian-block-ids.md`
- Existing performance infrastructure: `BlockDimensionEstimator`, `WidgetCache`, `SliverVariedExtentList`, `IncrementalMarkdownParser`
- `package:markdown` fenced code parsing (no new syntax required)
