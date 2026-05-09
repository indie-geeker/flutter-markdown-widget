<claude-mem-context>
# Memory Context

# [flutter-markdown-widget] recent context, 2026-05-07 8:54pm EDT

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Stats: 50 obs (21,333t read) | 447,330t work | 95% savings

### May 6, 2026
1065 10:23p 🔵 M2 Specs and Plans Contain Zero DOM/Polyfill Awareness
1066 10:24p 🔵 M2 Plan's Actual JS Render Call Confirmed: Direct mermaid.render() in Headless VM
1151 10:41p 🟣 M2 Subpackage flutter_markdown_widget_mermaid Implemented with webview_flutter
### May 7, 2026
1164 3:20a ⚖️ M2 fixes scoped: MIT LICENSE + platform guard + doc cleanup
1166 " 🔴 Added missing imports to mermaid_webview_renderer.dart for platform guard fix
1165 3:32a 🔵 Main flutter-markdown-widget repo uses MIT license (not BSD-3-Clause)
1167 3:33a 🔴 MermaidWebViewRenderer.shared() now returns UnsupportedMermaidRenderer on Web/Windows/Linux
1168 " 🔴 MermaidWebViewHost now accepts MermaidRenderer interface and degrades gracefully on unsupported platforms
1169 " ✅ UnsupportedMermaidRenderer docstring and error message updated for WebView replan
1170 3:34a ✅ BundledMermaidJsLoader docstring updated to remove FlutterJsMermaidRenderer reference and document fallback behavior
1171 " ✅ MIT LICENSE file created for flutter_markdown_widget_mermaid subpackage
1172 " ✅ Spec §3.1 back-synced to document MermaidWebViewHost and buildWidget() as public API
1173 " ✅ Spec §5 back-synced to document MermaidJsLoader two-path asset fallback behavior
1174 3:35a ✅ All 4 audit fixes verified: flutter analyze clean, 44/44 tests pass after changes
1175 9:42a 🔵 flutter-markdown-widget Mermaid Package Structure
1176 9:43a 🔵 flutter-markdown-widget Mermaid Development History and Branch Structure
1177 " 🔵 flutter_markdown_widget_mermaid Is a Separate Sibling Repository
1178 " 🔵 mermaid_smoke_test Validates SVG Generation Only, Not Visual Display
1179 " 🔵 SVG Display Pipeline: flutter_svg Renders SVG, Not WebView
1180 " 🔵 WebViewFlutterMermaidEngine Has macOS-Specific Widget Tree Constraint
1181 " 🔵 MermaidSvgPostprocessor Normalizes SVG Root Dimensions — Potential flutter_svg Incompatibility
1185 9:45a 🔵 MermaidWebViewBridge CSS Inlining in 1px Offscreen WebView — Root Cause of White Block
1186 " 🔵 Full Mermaid Rendering Architecture: End-to-End Pipeline
1190 " 🔵 Bundled mermaid.js v10.9.5, 3.3MB — CSS Variable Heavy Theme System
1192 9:46a 🔵 Companion Example Has Single main.dart; Main Example Tests Use FakeMermaidRenderer
1197 " 🔵 Most Recent Fix: "avoid foreignObject in flowchart SVG output" — White Block Is a Separate Subsequent Issue
1194 9:47a 🔵 MermaidShowcasePage Uses MermaidTheme.auto Default with Three Demo Modes
1201 " 🔵 Smoke Test's stroke= Assertion Is Insufficient — Doesn't Verify Visible Colors
1202 9:48a 🔵 The White Block Root Cause: flutter_svg Cannot Process CSS Class-Based Styles in Mermaid SVG
1203 " ⚖️ Previous MermaidWebViewHost Always Mounted WebView; New Design Mounts Only During Renders
S185 Step 1 验证根因 — 探索 example 应用结构，准备在 MermaidWebViewRenderer 中添加诊断 SVG 转储代码 (May 7 at 9:48 AM)
S182 Debug macOS white block in Mermaid diagram rendering: integration test passes but example app shows white rectangles instead of diagrams (May 7 at 9:48 AM)
S183 Step 1 验证根因 — 用诊断输出捕获真实 SVG，确认白块是 flutter_svg 兼容性问题还是布局/尺寸问题 (May 7 at 9:48 AM)
1204 9:49a 🟣 MermaidWebViewHost Tests Verify Dynamic Offscreen Mounting and Lifecycle
S186 Fix Mermaid diagram white block bug on macOS — Step 1: add diagnostic instrumentation to isolate whether flutter_svg incompatibility or MermaidArtifactView layout is the root cause (May 7 at 9:51 AM)
1206 10:02a 🔵 MermaidRenderer Public API Contract — render() Returns MermaidArtifact, Version Determines Cache Validity
1207 " 🟣 DiagnosticMermaidRenderer Created — SVG Dump + Element Statistics for Root Cause Validation
1208 10:03a 🟣 SvgDiagnosticPage Created — In-App Flutter_SVG Isolation Test
S188 Fix Mermaid white-block bug — Step 2-A confirmed: flutter_svg cannot parse mermaid SVG at all; implementing WebView PNG rasterization (May 7 at 10:04 AM)
1213 10:06a 🔵 Mermaid white-block root cause confirmed: MermaidArtifactView layout bug, not flutter_svg CSS incompatibility
S189 Platform compatibility question: Windows (webview_windows) and flutter_inappwebview migration compatibility with Step 2-A PNG rasterization approach (May 7 at 10:06 AM)
S187 Fix Mermaid diagram white block bug on macOS — diagnostic run completed, root cause confirmed as MermaidArtifactView layout bug (Step 2-B) (May 7 at 10:07 AM)
S190 Mermaid white-block fix: root cause confirmed as flutter_svg parse failure; Step 2-A (WebView PNG rasterization) plan presented and pending user confirmation to execute (May 7 at 10:14 AM)
S191 Platform compatibility analysis for Step 2-A PNG rasterization: Windows (webview_windows) and flutter_inappwebview migration — both confirmed compatible, shim pattern proposed (May 7 at 10:16 AM)
1218 10:23a 🔵 Current MermaidFullscreenViewer and FakeMermaidRenderer structure before Step 2-A modification
1219 10:24a 🔵 Mermaid test suite structure mapped before Step 2-A modifications
1220 " 🟣 MermaidArtifact gains nullable rasterPng field for WebView PNG rasterization
1221 10:25a 🟣 MermaidArtifact equality updated to include rasterPng via listEquals; hashCode uses length-only for performance
1222 " 🟣 MermaidArtifactView gains PNG/SVG branch widget keys; artifact test adds rasterPng coverage
1223 " 🔴 MermaidArtifactView now renders Image.memory(rasterPng) instead of broken SvgPicture for mermaid diagrams
1224 " 🟣 MermaidFullscreenViewer updated to prefer PNG over SVG; FakeMermaidRenderer prepared for rasterPng
1225 10:26a 🟣 FakeMermaidRenderer gains pngBuilder hook for injecting synthetic rasterPng in tests
1226 " 🟣 Artifact view test adds minimal valid PNG fixture and flutter_svg import for branch-discriminating tests
1227 " 🟣 Three new widget tests cover MermaidArtifactView PNG/SVG branch discrimination with key and type assertions
1228 " 🟣 mermaid_fullscreen_viewer_test.dart updated with PNG fixture and imports for branch-discriminating tests
1229 10:27a 🟣 MermaidFullscreenViewer tests extended with PNG/SVG branch discrimination assertions
1230 " 🔵 flutter analyze reveals dart:typed_data imports are redundant — flutter/foundation.dart already re-exports Uint8List
S192 Fix Mermaid diagram white-block bug on macOS via WebView PNG rasterization (Step 2-A) — implement full canvas rasterization pipeline in companion package (May 7 at 10:27 AM)
1239 10:30a 🔵 Mermaid PNG renders but inline view clips — fullscreen view works correctly
1240 10:31a 🔵 MermaidArtifactView uses aspect-ratio-derived SizedBox — tall diagrams require document scrolling

Access 447k tokens of past work via get_observations([IDs]) or mem-search skill.
</claude-mem-context>