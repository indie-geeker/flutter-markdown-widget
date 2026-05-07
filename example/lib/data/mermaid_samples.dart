// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class MermaidSamples {
  const MermaidSamples._();

  static const String staticShowcase = '''
# Mermaid Showcase

Static markdown can render diagrams alongside normal prose.

```mermaid
flowchart TD
  A[Markdown source] --> B[Mermaid renderer]
  B --> C[SVG artifact]
  C --> D[Flutter widget]
```

```mermaid
sequenceDiagram
  participant User
  participant App
  participant Renderer
  User->>App: Opens markdown
  App->>Renderer: render(source)
  Renderer-->>App: SVG artifact
```

```mermaid
stateDiagram-v2
  [*] --> Pending
  Pending --> Rendered
  Pending --> Failed
  Failed --> Pending: Retry
```
''';

  static const String streamingShowcase = '''
The assistant is composing a response with a diagram.

```mermaid
flowchart LR
  Stream[Streaming chunks] --> Parser
  Parser --> Complete{Fence closed?}
  Complete -->|yes| Render
  Complete -->|no| Fallback
```
''';

  static const String errorShowcase = '''
# Error sample

This intentionally invalid diagram demonstrates fallback and retry UI.

```mermaid
flowchart TD
  A --> 
```
''';
}
