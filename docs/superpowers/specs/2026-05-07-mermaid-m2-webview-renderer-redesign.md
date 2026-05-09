# Mermaid M2 WebView Renderer Redesign Spec

**Status:** Draft, ready for replan
**Date:** 2026-05-07
**Owner:** indiegeeker
**Supersedes:** [`2026-05-06-mermaid-m2-subpackage-design.md`](./2026-05-06-mermaid-m2-subpackage-design.md) implementation sections that depend on `flutter_js`
**Keeps:** M1 public contract, subpackage boundary, bundled Mermaid asset, theme directive, SVG background post-processing, asset integrity, cross-repo publish order

---

## 1. Root Cause

Task 15 real-platform smoke proved that `mermaid.min.js@10.9.5` cannot run in
the planned pure `flutter_js` runtime. The initialization failure was:

```text
ERROR: Can't find variable: document
```

This is expected. Mermaid's browser render path uses DOM APIs. The bundled file
contains many references to `document`, `window`, `createElement`, `getBBox`,
and `getComputedStyle`. The official Mermaid `render` API creates or uses DOM
containers, and the public examples insert the returned SVG into the document.

Conclusion: M2 needs a browser-backed runtime, not a JavaScript-only runtime.

References:

- Mermaid render API: https://www.mintlify.com/mermaid-js/mermaid/api/methods/render
- webview_flutter package: https://pub.dev/packages/webview_flutter
- webview_flutter platform support: Android, iOS, macOS
- webview_flutter 4.x API: `WebViewController`, `runJavaScript`, `runJavaScriptReturningResult`
- flutter_inappwebview platform requirements: https://pub.dev/packages/flutter_inappwebview
- webview_windows package: https://pub.dev/packages/webview_windows

---

## 2. Revised Goal

Ship `flutter_markdown_widget_mermaid` as an independent package that provides a
default Mermaid renderer backed by a real browser DOM. The first backend is
`webview_flutter` for Android, iOS, and macOS. The renderer must isolate the
backend behind an internal engine interface so later releases can add
`flutter_inappwebview` or `webview_windows` without changing the public renderer
API or M1's `MermaidRenderer` contract.

### Success Criteria

- A host app can configure Mermaid with one renderer object and no direct
  WebView code.
- Mermaid renders on Android, iOS, and macOS using a browser DOM.
- The public renderer API is not tied to `webview_flutter`; backend choice is an
  internal detail.
- Existing completed M2 utilities remain useful: asset loader, theme directive,
  SVG postprocessor, unsupported stub, boundary test, version generator.
- Future Windows support is a new backend implementation, not a public API
  rewrite.

### Non-goals

- Windows support in 0.1.0. The architecture must allow it, but M2.3 ships
  Android/iOS/macOS.
- Linux support in 0.1.0.
- Web platform native support.
- A DOM polyfill for `flutter_js`.
- Server-side or network rendering.

---

## 3. Architecture

### 3.1 Public API

Rename the public class before publication:

```dart
class MermaidWebViewRenderer implements MermaidRenderer {
  static MermaidRenderer shared();

  static MermaidRenderer withCustomMermaidJs({
    required String mermaidJs,
    required String mermaidVersion,
  });

  @visibleForTesting
  factory MermaidWebViewRenderer.forTesting({
    required MermaidJsLoader loader,
    required MermaidBrowserEngine engine,
    Widget Function()? hostBuilder,
  });

  /// Builds the platform WebView widget. Used by [MermaidWebViewHost].
  Widget buildWidget();
}
```

`MermaidWebViewRenderer.shared()` and `withCustomMermaidJs(...)` both return
`MermaidRenderer`, not the concrete class, so the unsupported-platform stub
(§3.6) can be returned without exposing it to consumers.

`MermaidWebViewHost` is the second public class:

```dart
class MermaidWebViewHost extends StatelessWidget {
  const MermaidWebViewHost({
    required MermaidRenderer renderer,
    required Widget child,
    double hostSize = 1,
  });
}
```

`webview_flutter` requires its `WebViewWidget` to be mounted somewhere in the
tree (notably on macOS) for JavaScript channels to deliver. `MermaidWebViewHost`
keeps that view alive in a 1×1 non-interactive slot stacked behind `child`.
The `renderer` parameter accepts any `MermaidRenderer`; when the value is the
unsupported-platform stub, the host renders `child` directly and skips the
WebView slot, so apps can pass `MermaidWebViewRenderer.shared()` everywhere
without platform branching.

Rationale: `FlutterJsMermaidRenderer` is now misleading and was never released.
`MermaidWebViewRenderer` names the durable architecture without naming a
specific plugin. The public barrel exports `MermaidWebViewRenderer` and
`MermaidWebViewHost`.

### 3.2 Internal Backend Boundary

All platform-specific WebView code is hidden behind one package-private engine:

```dart
abstract class MermaidBrowserEngine {
  String get backendId;
  bool get isReady;

  Future<void> initialize({required String mermaidJs});

  Future<String> renderJson({
    required String requestId,
    required String diagramId,
    required String source,
  });

  Future<void> dispose();
}
```

`MermaidWebViewRenderer` owns lazy initialization, theme directive injection,
render queueing, error mapping, SVG post-processing, intrinsic size parsing, and
version string composition. The engine owns only browser lifecycle and the Dart
to JavaScript bridge.

Initial implementation:

```text
MermaidWebViewRenderer
  -> MermaidJsLoader
  -> MermaidThemeDirective
  -> MermaidBrowserEngine
       -> WebViewFlutterMermaidEngine
            -> WebViewController
            -> JavaScriptChannel "MermaidResult"
  -> MermaidSvgPostprocessor
  -> MermaidArtifact.parseViewBox
```

Future implementations:

```text
InAppWebViewMermaidEngine      // Android/iOS/macOS/Windows if chosen later
WebViewWindowsMermaidEngine    // Windows via webview_windows
```

Those engines implement the same `MermaidBrowserEngine` interface. The public
`MermaidWebViewRenderer` and M1 stay unchanged.

### 3.3 Browser Shell

The engine loads a local HTML shell with no network dependencies:

```html
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <style>
      html, body { margin: 0; padding: 0; background: transparent; }
      #sandbox { position: absolute; left: -10000px; top: -10000px; }
    </style>
  </head>
  <body>
    <div id="sandbox"></div>
  </body>
</html>
```

Initialization then runs:

1. raw `mermaid.min.js`
2. `mermaid.initialize({ startOnLoad: false, securityLevel: "strict" })`
3. a bridge function:

```js
window.__fmwmRenderMermaid = function(requestId, diagramId, source) {
  var container = document.getElementById('sandbox');
  container.innerHTML = '';
  mermaid.render(diagramId, source, container)
    .then(function(result) {
      MermaidResult.postMessage(JSON.stringify({
        requestId: requestId,
        svg: result.svg
      }));
    })
    .catch(function(error) {
      MermaidResult.postMessage(JSON.stringify({
        requestId: requestId,
        error: (error && error.message) || String(error)
      }));
    });
};
```

The Dart side never interpolates unescaped user source into executable script.
It uses `jsonEncode` for `requestId`, `diagramId`, and Mermaid source.

### 3.4 Render Queue

Even if a backend can handle multiple bridge requests, M2 serializes renders
through one queue per renderer instance:

```text
previous render completes -> clear sandbox -> render next source
```

Reasons:

- Mermaid uses global configuration and shared DOM containers.
- A single queue is easier to reason about than concurrent DOM mutation.
- M1 already owns caching; renderer throughput is acceptable for Markdown block
  rendering.

### 3.5 Error Mapping

Renderer error behavior stays aligned with M1:

| Failure | Maps to |
|---|---|
| WebView unavailable or initialization fails | `MermaidInitializationError` |
| Dart to WebView bridge throws | `MermaidRuntimeError` |
| JS bridge returns `{error}` | `MermaidSyntaxError` |
| SVG cannot be parsed downstream | M1 invalid-output path |
| Timeout | M1 `Future.timeout` |

### 3.6 Platform Support

`webview_flutter` currently supports Android, iOS, and macOS. Those are the M2
gated platforms. Windows returns `UnsupportedMermaidRenderer` in 0.1.0. A
future Windows implementation adds `WebViewWindowsMermaidEngine` and updates the
factory selection only.

### 3.7 Example App for Smoke Tests

Do not put generated platform runners at the package root. Create an
`example/` app and run integration smoke tests from that app:

```bash
cd example
flutter test integration_test/mermaid_smoke_test.dart -d macos
```

This keeps the package root publishable and isolates iOS/Android/macOS runner
files in the conventional example app.

---

## 4. Testing Strategy

### Unit Tests

Use `FakeMermaidBrowserEngine` for all renderer unit tests. It records
`initialize` and `renderJson` calls and can simulate:

- initialization success/failure
- bridge runtime errors
- Mermaid syntax errors
- delayed render completion for queue tests
- disposal

Keep existing tests for:

- `MermaidThemeDirective`
- `MermaidSvgPostprocessor`
- `MermaidJsLoader`
- `UnsupportedMermaidRenderer`
- boundary enforcement

Add tests for:

- renderer init evaluates loader once
- render happy path maps SVG to `MermaidArtifact`
- JSON escaping of source in bridge call
- syntax/runtime/init errors
- dispose lifecycle
- render queue serializes concurrent requests
- version string includes package version, Mermaid version, and backend id

### Real Platform Smoke

Run one smoke fixture in `example/integration_test/mermaid_smoke_test.dart` on
macOS locally and in CI, then iOS/Android/macOS in GitHub Actions:

```dart
final renderer = MermaidWebViewRenderer.shared();
final artifact = await renderer.render(
  'flowchart TD\nA-->B',
  theme: MermaidTheme.light,
);
expect(artifact.svg, contains('<svg'));
expect(artifact.intrinsicSize, isNotNull);
```

### Spike Gate

Before deleting the old `flutter_js` implementation, run a focused backend
spike: prove that `WebViewController` can load the shell, evaluate Mermaid, and
return an SVG without a visible `WebViewWidget` in the tree. If that fails, stop
and switch the backend implementation to `flutter_inappwebview`
`HeadlessInAppWebView` behind the same `MermaidBrowserEngine` interface. Do not
change the public renderer API.

---

## 5. Migration From Current M2 State

Current completed M2 work that remains valid:

- package scaffold
- Mermaid asset and checksum
- `MermaidThemeDirective`
- `MermaidSvgPostprocessor`
- `MermaidJsLoader` with package/local asset fallback (the loader first
  requests `packages/flutter_markdown_widget_mermaid/assets/mermaid.min.js`,
  then retries `assets/mermaid.min.js` if the package key is missing — this
  lets the subpackage's own `example/` integration tests load the asset
  without the package-prefixed key)
- `UnsupportedMermaidRenderer`
- version generator
- boundary test

Current completed M2 work to replace:

- `_js_runtime.dart`
- `flutter_js_mermaid_renderer.dart`
- `FakeJsRuntime`
- renderer tests tied to `flutter_js`
- public barrel export name
- README usage snippets
- `pubspec.yaml` dependency on `flutter_js`

Uncommitted failed Task 15 artifacts should be cleaned before the new plan:

- remove root `macos/`
- remove root `integration_test/`
- keep or reapply the `MermaidJsLoader` local asset fallback through the new
  plan

---

## 6. Recommendation

Use `webview_flutter` as the first backend, but make it an internal engine
adapter. Public API should be `MermaidWebViewRenderer`, not
`WebViewFlutterMermaidRenderer`. This keeps the default package API stable while
allowing Windows support to land later by adding one new engine implementation.
