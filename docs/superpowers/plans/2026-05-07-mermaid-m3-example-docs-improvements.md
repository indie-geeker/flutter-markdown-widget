# Mermaid M3 Example, Docs, and Integration Improvements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ship the M3 Mermaid cycle: a real main-package example app showcase, publish-ready README guidance, and the small integration fixes needed for streaming and virtual-scroll stability.

**Architecture:** Keep renderer execution in the companion `flutter_markdown_widget_mermaid` package. The main package example owns a shared `MermaidWebViewRenderer`, mounts it once with `MermaidWebViewHost`, and passes it through a tiny example-only scope. Main-package runtime changes stay limited to Mermaid source-completeness plumbing and optional size reporting; do not replace the current natural-height `VirtualMarkdownList` strategy.

**Tech Stack:** Dart, Flutter, `flutter_markdown_widget`, `flutter_markdown_widget_mermaid`, `webview_flutter`, `flutter_test`, GitHub Actions.

---

## Context

M3 is defined in `docs/superpowers/specs/2026-05-06-mermaid-design.md` as:

- "Mermaid Showcase" page in the example app with streaming, static, and error samples.
- Main-package README section covering both integration paths.
- `AGENTS.md` / claude-mem observation index update.

Two existing implementation details shape the plan:

- `ContentBuilder._buildCodeBlock` currently passes `sourceComplete: true` to `MermaidView` for every Mermaid block. That is correct for static parsing but too optimistic for streaming display of an incomplete Mermaid fence.
- `BlockDimensionEstimator` exists and `MermaidView.onIntrinsicSize` exists, but they are not wired together. `VirtualMarkdownList` deliberately uses natural child height, and `test/virtual_markdown_list_test.dart` protects against returning to forced estimated extents. M3 should record Mermaid-rendered height hints only; it must not reintroduce forced extents or `SliverVariedExtentList`.

## Non-Goals

- No Windows, Linux, or Web backend implementation.
- No mermaid.js 11 upgrade.
- No renderer-in-isolate work.
- No full SVG golden tests.
- No forced virtual-list item heights.
- No pub.dev publishing unless the user explicitly asks for the release step.

---

### Task 0: Preflight Current State

**Files:**
- Read: `README.md`
- Read: `example/pubspec.yaml`
- Read: `example/lib/data/demo_entries.dart`
- Read: `example/lib/app/example_app.dart`
- Read: `lib/src/builder/content_builder.dart`
- Read: `lib/src/widgets/streaming_markdown_view.dart`
- Read: `lib/src/widgets/virtual_markdown_list.dart`
- Read: `lib/src/widgets/components/mermaid_view.dart`
- Read: `lib/src/widgets/components/mermaid_artifact_view.dart`

**Step 1: Check worktree state**

Run:

```bash
git status --short
git -C ../flutter-markdown-widget-mermaid status --short
```

Expected: note unrelated dirty files before editing. Do not revert user changes.

**Step 2: Verify package dependencies resolve before edits**

Run:

```bash
flutter pub get
cd example && flutter pub get
```

Expected: both commands pass from the main package repo.

**Step 3: Commit boundary**

Do not commit in this task. It is only a preflight checkpoint.

---

### Task 1: Preserve Streaming Source Completeness for Mermaid Blocks

**Files:**
- Modify: `lib/src/widgets/streaming_markdown_view.dart`
- Modify: `lib/src/builder/content_builder.dart`
- Test: `test/mermaid/content_builder_routing_test.dart`
- Test: `test/streaming_test.dart`

**Step 1: Write failing routing test**

Add a test proving `ContentBuilder` forwards `ContentBlock.metadata['sourceComplete'] == false` to `MermaidView`.

Expected assertion shape:

```dart
final view = tester.widget<MermaidView>(find.byType(MermaidView));
expect(view.sourceComplete, isFalse);
```

**Step 2: Write failing streaming test**

Add a widget test where `StreamingMarkdownView.fromStream` uses:

```dart
const StreamingOptions(
  renderIncompleteBlocks: true,
  bufferMode: BufferMode.byCharacter,
)
```

Feed an unclosed Mermaid fence:

````markdown
```mermaid
flowchart TD
A-->B
```
````

Expected: fallback source is visible, but the fake Mermaid renderer has zero calls until the closing fence arrives.

**Step 3: Implement metadata propagation**

In `_createIncompleteDisplayBlock`, set:

```dart
metadata: const {'sourceComplete': false},
```

In `ContentBuilder._buildCodeBlock`, compute:

```dart
final sourceComplete = block.metadata['sourceComplete'] is bool
    ? block.metadata['sourceComplete'] as bool
    : true;
```

Then pass `sourceComplete` to `MermaidView`.

**Step 4: Run focused tests**

Run:

```bash
flutter test test/mermaid/content_builder_routing_test.dart test/streaming_test.dart
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add lib/src/widgets/streaming_markdown_view.dart lib/src/builder/content_builder.dart test/mermaid/content_builder_routing_test.dart test/streaming_test.dart
git commit -m "fix: preserve incomplete mermaid streaming state"
```

---

### Task 2: Record Mermaid Rendered Heights Without Forcing Virtual Extents

**Files:**
- Modify: `lib/src/widgets/components/mermaid_artifact_view.dart`
- Modify: `lib/src/widgets/components/mermaid_view.dart`
- Modify: `lib/src/builder/content_builder.dart`
- Modify: `lib/src/widgets/virtual_markdown_list.dart`
- Test: `test/mermaid/mermaid_artifact_view_test.dart`
- Test: `test/mermaid/mermaid_view_core_test.dart`
- Test: `test/virtual_markdown_list_test.dart`

**Step 1: Write failing artifact-view size callback test**

Add an optional `onLaidOutSize` callback to `MermaidArtifactView`.

Test with a 400px-wide parent and an `intrinsicSize` of `Size(800, 400)`.

Expected callback value: `Size(400, 200)`.

**Step 2: Write failing MermaidView callback test**

Add an internal/additive `onRenderedSize` callback to `MermaidView`, separate from the existing `onIntrinsicSize`.

Expected: after render, `onRenderedSize` receives the laid-out widget size.

**Step 3: Write failing virtual list estimator test**

Extend `VirtualMarkdownList` with an optional `BlockDimensionEstimator dimensionEstimator`.

Use a fake Mermaid renderer returning a known aspect ratio. Pump a virtual list containing one Mermaid block. After layout, expect:

```dart
expect(estimator.getActualHeight(block.contentHash), closeTo(expectedHeight, 0.1));
```

Also keep the existing "lets children take their natural height" test unchanged.

**Step 4: Implement size reporting**

Implement callback plumbing:

- `MermaidArtifactView(onLaidOutSize: ...)` reports the computed `SizedBox` size after layout.
- `MermaidView(onRenderedSize: ...)` forwards that rendered size.
- `ContentBuilder` accepts an optional callback such as `onBlockRenderedSize`.
- `VirtualMarkdownList` supplies a callback that calls `dimensionEstimator.recordActualHeight(block.contentHash, size.height)`.

Do not use `dimensionEstimator.estimateHeight` to set item extent in M3.

**Step 5: Run focused tests**

Run:

```bash
flutter test test/mermaid/mermaid_artifact_view_test.dart test/mermaid/mermaid_view_core_test.dart test/virtual_markdown_list_test.dart
```

Expected: all tests pass and the natural-height regression test still passes.

**Step 6: Commit**

```bash
git add lib/src/widgets/components/mermaid_artifact_view.dart lib/src/widgets/components/mermaid_view.dart lib/src/builder/content_builder.dart lib/src/widgets/virtual_markdown_list.dart test/mermaid/mermaid_artifact_view_test.dart test/mermaid/mermaid_view_core_test.dart test/virtual_markdown_list_test.dart
git commit -m "feat: record mermaid rendered heights"
```

---

### Task 3: Add Example-App Mermaid Dependency and Renderer Scope

**Files:**
- Modify: `example/pubspec.yaml`
- Modify: `example/lib/app/example_app.dart`
- Create: `example/lib/mermaid/mermaid_demo_scope.dart`
- Test: `example/test/mermaid_demo_scope_test.dart`

**Step 1: Add companion package dependency**

For local two-repo development, add:

```yaml
flutter_markdown_widget_mermaid:
  path: ../../flutter-markdown-widget-mermaid
```

If this task is executed after pub.dev release, prefer:

```yaml
flutter_markdown_widget_mermaid: ^0.1.0
```

Do not mix both in the committed example.

**Step 2: Create example-only renderer scope**

Create `MermaidDemoScope` as an `InheritedWidget` exposing a `MermaidRenderer`.

Required API:

```dart
class MermaidDemoScope extends InheritedWidget {
  const MermaidDemoScope({
    super.key,
    required this.renderer,
    required super.child,
  });

  final MermaidRenderer renderer;

  static MermaidRenderer of(BuildContext context) { ... }
  static MermaidRenderer? maybeOf(BuildContext context) { ... }
}
```

**Step 3: Mount WebView host once**

Convert `ExampleApp` to own a shared renderer:

```dart
late final MermaidRenderer _mermaidRenderer = MermaidWebViewRenderer.shared();
```

Use `MaterialApp.builder` to wrap the app content:

```dart
builder: (context, child) {
  final body = child ?? const SizedBox.shrink();
  return MermaidDemoScope(
    renderer: _mermaidRenderer,
    child: MermaidWebViewHost(
      renderer: _mermaidRenderer,
      child: body,
    ),
  );
},
```

Because this is an app-lifetime singleton, do not dispose the shared renderer in widget tests that pump and tear down the app repeatedly.

**Step 4: Test scope availability**

Add a test that pumps `ExampleApp`, reads `MermaidDemoScope.maybeOf`, and verifies a non-null renderer is available without opening the showcase page.

Run:

```bash
cd example && flutter test test/mermaid_demo_scope_test.dart
```

Expected: pass on the host test platform. On Linux, the renderer may be `UnsupportedMermaidRenderer`; the test should assert presence, not platform support.

**Step 5: Commit**

```bash
git add example/pubspec.yaml example/pubspec.lock example/lib/app/example_app.dart example/lib/mermaid/mermaid_demo_scope.dart example/test/mermaid_demo_scope_test.dart
git commit -m "feat: wire mermaid renderer into example app"
```

---

### Task 4: Add Mermaid Showcase Sample Data

**Files:**
- Create: `example/lib/data/mermaid_samples.dart`
- Test: `example/test/mermaid_samples_test.dart`

**Step 1: Create sample data**

Add markdown strings for:

- Static showcase: flowchart, sequence diagram, class/state diagram.
- Streaming showcase: a compact answer that includes one Mermaid fenced block.
- Error showcase: one intentionally invalid Mermaid block.

Keep samples deterministic and small enough for widget tests.

**Step 2: Test sample shape**

Add tests asserting:

- Static sample contains at least two ```` ```mermaid ```` fences.
- Streaming sample contains exactly one Mermaid fence and closes it.
- Error sample contains one Mermaid fence.

**Step 3: Run tests**

```bash
cd example && flutter test test/mermaid_samples_test.dart
```

Expected: pass.

**Step 4: Commit**

```bash
git add example/lib/data/mermaid_samples.dart example/test/mermaid_samples_test.dart
git commit -m "feat: add mermaid showcase samples"
```

---

### Task 5: Build the Static Mermaid Showcase View

**Files:**
- Create: `example/lib/pages/mermaid_showcase_page.dart`
- Modify: `example/lib/data/demo_entries.dart`
- Test: `example/test/mermaid_showcase_page_test.dart`

**Step 1: Write failing navigation test**

Assert the home page includes a `DemoEntry` titled `Mermaid Showcase`.

**Step 2: Write failing page smoke test**

Pump `MermaidShowcasePage` with a fake renderer through `MermaidDemoScope`.

Expected:

- Page title is visible.
- Static mode renders at least one `MermaidView`.
- The fake renderer receives a Mermaid source containing `flowchart`.

**Step 3: Implement page shell**

Use existing example components:

- `ExampleAppBar`
- `AppBackground`
- `SurfaceCard`
- `SectionHeader`
- `OptionTiles` or segmented controls already used in the example

Add controls for:

- Static
- Streaming
- Errors
- Theme: auto, light, dark

**Step 4: Add home entry**

Add a `DemoEntry`:

```dart
DemoEntry(
  title: 'Mermaid Showcase',
  description: 'Render diagrams in static markdown, streaming output, and error states.',
  icon: Icons.account_tree_rounded,
  gradient: AppGradients.emerald,
  badges: ['Mermaid', 'WebView'],
  builder: (_) => const MermaidShowcasePage(),
),
```

Pick an existing gradient. Do not create a separate design system for one page.

**Step 5: Run tests**

```bash
cd example && flutter test test/mermaid_showcase_page_test.dart
```

Expected: pass.

**Step 6: Commit**

```bash
git add example/lib/pages/mermaid_showcase_page.dart example/lib/data/demo_entries.dart example/test/mermaid_showcase_page_test.dart
git commit -m "feat: add mermaid showcase page"
```

---

### Task 6: Add Streaming Mermaid Replay Behavior

**Files:**
- Modify: `example/lib/pages/mermaid_showcase_page.dart`
- Test: `example/test/mermaid_showcase_page_test.dart`

**Step 1: Write failing streaming test**

Switch the page to streaming mode, tap replay/start, pump streamed chunks, and assert:

- `StreamingMarkdownView` appears.
- The fake renderer is not called for an incomplete fence.
- The fake renderer is called after the closing fence.

This relies on Task 1.

**Step 2: Implement stream controller flow**

The page should:

- Create a fresh `StreamController<String>` per replay.
- Stream deterministic chunks from `MermaidSamples.streaming`.
- Disable the replay button while streaming.
- Close the controller in `dispose`.

Use:

```dart
StreamingOptions(
  bufferMode: BufferMode.byBlock,
  showTypingCursor: true,
  renderIncompleteBlocks: true,
)
```

**Step 3: Run tests**

```bash
cd example && flutter test test/mermaid_showcase_page_test.dart
```

Expected: pass.

**Step 4: Commit**

```bash
git add example/lib/pages/mermaid_showcase_page.dart example/test/mermaid_showcase_page_test.dart
git commit -m "feat: demonstrate streaming mermaid rendering"
```

---

### Task 7: Add Error and Diagnostics Samples

**Files:**
- Modify: `example/lib/pages/mermaid_showcase_page.dart`
- Test: `example/test/mermaid_showcase_page_test.dart`

**Step 1: Write failing error-state test**

Use a fake renderer that throws `MermaidSyntaxError`.

Expected:

- Error mode renders the invalid source fallback.
- The default or custom error banner is visible.
- Diagnostics count increments via `MermaidOptions.onError`.

**Step 2: Implement diagnostics panel**

Keep it compact:

- Last error type.
- Error count.
- A retry action wired through `MermaidErrorContext.retry`.

Do not add unrelated logging infrastructure.

**Step 3: Run tests**

```bash
cd example && flutter test test/mermaid_showcase_page_test.dart
```

Expected: pass.

**Step 4: Commit**

```bash
git add example/lib/pages/mermaid_showcase_page.dart example/test/mermaid_showcase_page_test.dart
git commit -m "feat: demonstrate mermaid error handling"
```

---

### Task 8: Update README and Example Docs

**Files:**
- Modify: `README.md`
- Modify: `example/README.md`
- Modify: `CHANGELOG.md`
- Modify: `AGENTS.md`

**Step 1: Main README**

Replace the current local-only Mermaid section with two paths:

1. Published package path:

```bash
flutter pub add flutter_markdown_widget flutter_markdown_widget_mermaid
```

2. Local two-repo development path dependency:

```yaml
dependencies:
  flutter_markdown_widget:
    path: ../flutter-markdown-widget
  flutter_markdown_widget_mermaid:
    path: ../flutter-markdown-widget-mermaid
```

Keep `MermaidWebViewHost` in the usage snippet because macOS requires the mounted WebView backend.

**Step 2: Platform support note**

Document:

- iOS, Android, macOS supported by the current WebView renderer.
- Linux, Windows, Web degrade through unsupported-renderer behavior in the current release.

**Step 3: Example README**

Add `Mermaid Showcase` to the demo page list and note that it uses the companion package.

**Step 4: Changelog**

Add an Unreleased entry for:

- Mermaid example showcase.
- README integration docs.
- Streaming Mermaid source-completeness fix.
- Mermaid rendered-size recording, if Task 2 ships.

**Step 5: AGENTS.md / memory index**

Update only if this repository is already using `AGENTS.md` as a checked-in memory index. Preserve existing memory formatting.

**Step 6: Commit**

```bash
git add README.md example/README.md CHANGELOG.md AGENTS.md
git commit -m "docs: document mermaid showcase integration"
```

---

### Task 9: Keep Main CI Green With the Companion Package

**Files:**
- Modify: `.github/workflows/ci.yml`

**Step 1: Decide dependency mode**

If `example/pubspec.yaml` uses the published `flutter_markdown_widget_mermaid: ^0.1.0`, no CI checkout change is needed.

If it uses a local path dependency, update CI so the main repo and mermaid repo are checked out side-by-side in the same workspace layout expected by `example/pubspec.yaml`.

**Step 2: Implement local-path CI layout if needed**

Recommended shape:

```yaml
- name: Checkout main package
  uses: actions/checkout@v4
  with:
    path: flutter-markdown-widget

- name: Checkout Mermaid package
  uses: actions/checkout@v4
  with:
    repository: indie-geeker/flutter-markdown-widget-mermaid
    path: flutter-markdown-widget-mermaid
```

Then set package commands to:

```yaml
working-directory: flutter-markdown-widget
```

and example commands to:

```yaml
working-directory: flutter-markdown-widget/example
```

This supports `example/pubspec.yaml` path `../../flutter-markdown-widget-mermaid`.

**Step 3: Run workflow-equivalent commands locally**

From the main package repo:

```bash
flutter pub get
flutter analyze
flutter test
flutter test test/benchmark_test.dart --dart-define=BENCHMARK_PROFILE=ci
cd example
flutter pub get
flutter analyze
flutter test
```

Expected: all pass.

**Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: include mermaid companion package for example"
```

---

### Task 10: Full Verification

**Files:**
- No source edits unless verification exposes a bug.

**Step 1: Main package checks**

Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter test test/benchmark_test.dart --dart-define=BENCHMARK_PROFILE=ci
```

Expected: all pass.

**Step 2: Example checks**

Run:

```bash
cd example
flutter pub get
flutter analyze
flutter test
```

Expected: all pass.

**Step 3: Companion package checks**

From `../flutter-markdown-widget-mermaid`:

```bash
flutter pub get
flutter analyze
flutter test
cd example
flutter pub get
```

Expected: all pass through `flutter test`; example dependency resolution passes.

**Step 4: Optional platform smoke**

Run only on available local devices:

```bash
cd ../flutter-markdown-widget-mermaid/example
flutter test integration_test/mermaid_smoke_test.dart -d macos
```

Expected: pass on macOS. Do not block M3 on unavailable iOS/Android local devices if CI already covers them.

**Step 5: Final commit if fixes were needed**

Commit only verification fixes, not generated noise.

---

## Rollout Notes

- Execute Task 1 before the streaming showcase so the page does not render incomplete Mermaid code fences prematurely.
- Execute Task 2 only as a bounded improvement. If it starts pushing `VirtualMarkdownList` toward fixed extents, stop and split it out of M3.
- If pub.dev publishing happens before M3, use version constraints in the example and skip CI side-by-side checkout changes.
- If publishing remains deferred, keep path dependencies and update CI layout as described in Task 9.
- The final user-visible M3 result should be: home page includes Mermaid Showcase, the page demonstrates static/streaming/error paths, and README tells users exactly how to integrate the companion renderer.
