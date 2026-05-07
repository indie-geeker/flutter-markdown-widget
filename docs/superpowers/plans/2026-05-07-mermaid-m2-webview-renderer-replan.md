# Mermaid M2 WebView Renderer Replan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the failed `flutter_js` runtime with a WebView-backed Mermaid renderer while preserving the M1 `MermaidRenderer` contract and isolating backend-specific code for future Windows support.

**Architecture:** The public class becomes `MermaidWebViewRenderer`. It orchestrates loader, theme directive, render queue, error mapping, SVG post-processing, and cache-version identity. Browser execution is hidden behind a package-private `MermaidBrowserEngine`; M2 ships `WebViewFlutterMermaidEngine`, and future releases can add `InAppWebViewMermaidEngine` or `WebViewWindowsMermaidEngine` without changing public API.

**Tech Stack:** Dart, Flutter, `webview_flutter`, bundled `mermaid.js@10.9.5`, `flutter_markdown_widget` M1 public Mermaid API, `flutter_test`, `integration_test`, GitHub Actions.

**Spec:** [`../specs/2026-05-07-mermaid-m2-webview-renderer-redesign.md`](../specs/2026-05-07-mermaid-m2-webview-renderer-redesign.md)

---

## Scope and Current State

Tasks 0-14 of the original plan produced useful commits through M2.1. This
replan starts from that state and replaces the runtime layer. Do not continue
old Tasks 15-23.

Useful files to keep:

- `assets/mermaid.min.js`
- `assets/mermaid.min.js.sha256`
- `lib/src/mermaid_js_loader.dart`
- `lib/src/mermaid_theme_directive.dart`
- `lib/src/mermaid_svg_postprocess.dart`
- `lib/src/unsupported_mermaid_renderer.dart`
- `tool/generate_package_version.dart`
- pure utility tests and boundary test

Files to replace:

- `lib/src/_js_runtime.dart`
- `lib/src/flutter_js_mermaid_renderer.dart`
- `test/_fake_js_runtime.dart`
- renderer tests tied to `FakeJsRuntime`
- public barrel export

Before starting, inspect the M2 repo worktree. The previous failed Task 15 may
have uncommitted root `macos/` and root `integration_test/` files. Those are
obsolete because the new plan uses an `example/` app for platform runners.

---

### Task 15R: [m2] Clean failed Task 15 artifacts and switch dependencies

**Files:**
- Modify: `pubspec.yaml`
- Modify: `.gitignore`
- Delete if present and uncommitted: root `macos/`
- Delete if present and uncommitted: root `integration_test/`
- Delete: `lib/src/_js_runtime.dart`
- Delete: `test/_fake_js_runtime.dart`

**Step 1: Inspect status**

```bash
git status --short --ignored
```

Expected: only known failed Task 15 artifacts are uncommitted. If unrelated
tracked files are modified, stop and ask.

**Step 2: Remove obsolete failed-smoke artifacts**

```bash
rm -rf macos integration_test
```

Expected: root package no longer has platform runners or root integration tests.

**Step 3: Update dependencies**

Edit `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_markdown_widget:
    path: ../flutter-markdown-widget
  webview_flutter: ^4.13.1
  meta: ^1.16.0
```

Remove `flutter_js`.

**Step 4: Remove obsolete runtime files**

```bash
git rm lib/src/_js_runtime.dart test/_fake_js_runtime.dart
```

**Step 5: Resolve dependencies**

```bash
flutter pub get
```

Expected: succeeds and resolves `webview_flutter`.

**Step 6: Commit**

```bash
git add pubspec.yaml .gitignore
git commit -m "chore: switch Mermaid renderer runtime to webview_flutter"
```

---

### Task 16R: [m2] Add `MermaidBrowserEngine` interface and fake engine

**Files:**
- Create: `lib/src/mermaid_browser_engine.dart`
- Create: `test/_fake_mermaid_browser_engine.dart`

**Step 1: Create the engine interface**

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

**Step 2: Create the fake**

The fake records `initializeCalls`, `renderCalls`, and `disposeCalled`. It
supports fields:

- `Object? initializeThrows`
- `Object? renderThrows`
- `String Function(RenderCall call)? renderResult`
- `Completer<void>? renderGate` for queue tests

**Step 3: Analyze**

```bash
flutter analyze lib/src/mermaid_browser_engine.dart test/_fake_mermaid_browser_engine.dart
```

Expected: no issues.

**Step 4: Commit**

```bash
git add lib/src/mermaid_browser_engine.dart test/_fake_mermaid_browser_engine.dart
git commit -m "feat: add MermaidBrowserEngine abstraction"
```

---

### Task 17R: [m2] Add WebView bridge script builder

**Files:**
- Create: `lib/src/mermaid_webview_bridge.dart`
- Test: `test/mermaid_webview_bridge_test.dart`

**Step 1: Write failing tests**

Cover:

- shell HTML contains `#sandbox`
- initialization script calls `mermaid.initialize`
- render script calls `window.__fmwmRenderMermaid`
- request id, diagram id, and source are JSON encoded
- user source containing quotes and `</script>` is not interpolated raw

Run:

```bash
flutter test test/mermaid_webview_bridge_test.dart
```

Expected: FAIL with missing import.

**Step 2: Implement bridge builder**

Create an `abstract final class MermaidWebViewBridge` with:

- `static String shellHtml()`
- `static String initializeMermaidJs()`
- `static String installBridgeJs()`
- `static String renderInvocation({required String requestId, required String diagramId, required String source})`

The render invocation must use `jsonEncode` for all dynamic values.

**Step 3: Run tests**

```bash
flutter test test/mermaid_webview_bridge_test.dart
```

Expected: PASS.

**Step 4: Commit**

```bash
git add lib/src/mermaid_webview_bridge.dart test/mermaid_webview_bridge_test.dart
git commit -m "feat: add Mermaid WebView bridge scripts"
```

---

### Task 18R: [m2] Spike `webview_flutter` backend on macOS

**Files:**
- Create: `example/`
- Create: `example/integration_test/webview_backend_spike_test.dart`

**Step 1: Create example app**

```bash
flutter create example --platforms=android,ios,macos
```

Edit `example/pubspec.yaml` to depend on the package under test:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_markdown_widget_mermaid:
    path: ..
```

Add `integration_test` under `dev_dependencies`.

**Step 2: Write spike test**

The test should instantiate `WebViewController`, set unrestricted JavaScript,
load the shell HTML, evaluate `mermaid.min.js`, install the bridge, render
`flowchart TD\nA-->B`, and expect returned JSON with `<svg`.

Do not use `MermaidWebViewRenderer` yet. This task proves the backend can work
without a visible `WebViewWidget`.

**Step 3: Run spike locally**

```bash
cd example
flutter test integration_test/webview_backend_spike_test.dart -d macos
```

Expected: PASS.

If it fails because `WebViewController` needs a widget in the tree or because
Promise results are not delivered, stop. Keep `MermaidBrowserEngine` and change
only the backend implementation plan to `flutter_inappwebview`
`HeadlessInAppWebView`.

**Step 4: Commit**

```bash
git add example
git commit -m "test: prove webview_flutter Mermaid backend spike"
```

---

### Task 19R: [m2] Implement `WebViewFlutterMermaidEngine`

**Files:**
- Create: `lib/src/webview_flutter_mermaid_engine.dart`
- Test: `test/webview_flutter_mermaid_engine_test.dart` if pure seams are needed

**Step 1: Implement the engine**

Use `WebViewController` with:

- `setJavaScriptMode(JavaScriptMode.unrestricted)`
- `setNavigationDelegate` that blocks unexpected navigation
- `addJavaScriptChannel('MermaidResult', onMessageReceived: ...)`
- `loadHtmlString(MermaidWebViewBridge.shellHtml())`
- `runJavaScript(mermaidJs)`
- `runJavaScript(MermaidWebViewBridge.initializeMermaidJs())`
- `runJavaScript(MermaidWebViewBridge.installBridgeJs())`

`renderJson` creates a Dart `Completer<String>` keyed by `requestId`, invokes
the render script, and completes when the JS channel posts the matching JSON.

**Step 2: Add timeout cleanup**

If a request completer is completed with error or disposed, remove it from the
pending map.

**Step 3: Run spike again**

```bash
cd example
flutter test integration_test/webview_backend_spike_test.dart -d macos
```

Expected: PASS using `WebViewFlutterMermaidEngine`.

**Step 4: Commit**

```bash
git add lib/src/webview_flutter_mermaid_engine.dart test/webview_flutter_mermaid_engine_test.dart example/integration_test/webview_backend_spike_test.dart
git commit -m "feat: add webview_flutter Mermaid browser engine"
```

---

### Task 20R: [m2] Replace renderer with `MermaidWebViewRenderer`

**Files:**
- Delete: `lib/src/flutter_js_mermaid_renderer.dart`
- Create: `lib/src/mermaid_webview_renderer.dart`
- Replace: `test/flutter_js_mermaid_renderer_test.dart` with `test/mermaid_webview_renderer_test.dart`

**Step 1: Write failing renderer tests using fake engine**

Cover:

- first render initializes loader and engine once
- second render does not reinitialize
- concurrent renders are serialized
- engine init failure maps to `MermaidInitializationError`
- engine render exception maps to `MermaidRuntimeError`
- engine JSON `{error}` maps to `MermaidSyntaxError`
- SVG success injects background and parses intrinsic size
- dispose calls engine dispose and makes future renders fail
- version matches `webview-<pkg>+<engineId>+mermaid-<version>`

Run:

```bash
flutter test test/mermaid_webview_renderer_test.dart
```

Expected: FAIL with missing renderer.

**Step 2: Implement renderer**

Port the existing renderer orchestration from `FlutterJsMermaidRenderer`, but
replace `_JsRuntime` calls with `MermaidBrowserEngine`.

Factory selection:

```dart
static MermaidRenderer shared() {
  if (kIsWeb || Platform.isWindows || Platform.isLinux) {
    return _shared ??= UnsupportedMermaidRenderer();
  }
  return _shared ??= MermaidWebViewRenderer._internal(
    loader: BundledMermaidJsLoader(),
    engine: WebViewFlutterMermaidEngine(),
  );
}
```

Use conditional imports or `dart:io` guarded behind `kIsWeb` so analysis stays
clean.

**Step 3: Run tests**

```bash
flutter test test/mermaid_webview_renderer_test.dart
```

Expected: PASS.

**Step 4: Commit**

```bash
git add lib/src/mermaid_webview_renderer.dart test/mermaid_webview_renderer_test.dart
git rm lib/src/flutter_js_mermaid_renderer.dart test/flutter_js_mermaid_renderer_test.dart
git commit -m "feat: replace flutter_js renderer with MermaidWebViewRenderer"
```

---

### Task 21R: [m2] Update public barrel, README, and compatibility docs

**Files:**
- Modify: `lib/flutter_markdown_widget_mermaid.dart`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `THIRD_PARTY_LICENSES.md` if needed

**Step 1: Update public export**

```dart
export 'src/mermaid_webview_renderer.dart' show MermaidWebViewRenderer;
```

**Step 2: Update README snippets**

Use:

```dart
MermaidOptions(
  renderer: MermaidWebViewRenderer.shared(),
)
```

Document that 0.1.0 supports Android, iOS, and macOS via `webview_flutter`.
Windows is planned through a future backend.

**Step 3: Run docs-adjacent tests**

```bash
flutter test test/boundary_test.dart
flutter test test/mermaid_webview_renderer_test.dart
```

Expected: PASS.

**Step 4: Commit**

```bash
git add lib/flutter_markdown_widget_mermaid.dart README.md CHANGELOG.md THIRD_PARTY_LICENSES.md
git commit -m "docs: update public API for WebView Mermaid renderer"
```

---

### Task 22R: [m2] Real-platform smoke through public renderer

**Files:**
- Create: `example/integration_test/mermaid_smoke_test.dart`

**Step 1: Write smoke test**

Use `MermaidWebViewRenderer.shared()` and render a simple flowchart.

**Step 2: Run macOS smoke locally**

```bash
cd example
flutter test integration_test/mermaid_smoke_test.dart -d macos
```

Expected: PASS, 1 test.

**Step 3: Run package unit suite**

```bash
cd ..
flutter analyze
flutter test
```

Expected: analyzer clean and all unit tests pass.

**Step 4: Commit**

```bash
git add example/integration_test/mermaid_smoke_test.dart
git commit -m "test: add WebView Mermaid real-platform smoke"
```

---

### Task 23R: [m2] Update CI for WebView backend

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `.github/workflows/integration.yml`
- Modify: `.github/actions/checkout-both/action.yml` if still needed

**Step 1: Unit workflow**

Root package job:

```bash
dart run tool/generate_package_version.dart
flutter pub get
flutter analyze
flutter test
sha256sum -c assets/mermaid.min.js.sha256
```

**Step 2: Integration workflow**

Run from `example/` after the two-repo checkout:

```bash
flutter pub get
flutter test integration_test/mermaid_smoke_test.dart -d macos
```

For iOS and Android jobs, use the example app's generated platform runners.

**Step 3: Commit and push**

```bash
git add .github
git commit -m "ci: run WebView Mermaid smoke from example app"
git push
```

Expected: unit workflow green; integration workflow green on macOS/iOS/Android.

---

### Task 24R: [m2] M2.2 verification gate

**Files:** none unless CI fixes are needed.

**Step 1: Verify local**

```bash
flutter analyze
flutter test
cd example
flutter test integration_test/mermaid_smoke_test.dart -d macos
```

Expected: all pass.

**Step 2: Verify GitHub Actions**

Manually trigger integration workflow and wait for:

- macOS smoke green
- iOS smoke green
- Android smoke green

**Step 3: Report milestone**

Stop and report M2.2 completion. Do not start publishing tasks until the user
confirms.

---

## Publish Tasks

After Task 24R is green, resume the original M2.3 publish order with these
changes:

- Main package 0.2.0 still publishes first.
- Subpackage `pubspec.yaml` cuts over to `flutter_markdown_widget: ^0.2.0`.
- Subpackage publishes `flutter_markdown_widget_mermaid 0.1.0`.
- README examples use `MermaidWebViewRenderer.shared()`.
- Publishing still requires user-run `flutter pub publish`; the agent only runs
  `--dry-run`.
