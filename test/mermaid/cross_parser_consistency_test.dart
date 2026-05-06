// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_markdown_widget/src/core/parser/ast_markdown_parser.dart';
import 'package:flutter_markdown_widget/src/core/parser/content_block.dart';
import 'package:flutter_markdown_widget/src/core/parser/incremental_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const _samples = <String>[
  '```mermaid\ngraph LR\nA-->B\n```',
  '''
Some intro paragraph.

```mermaid
sequenceDiagram
  Alice->>Bob: hi
  Bob-->>Alice: hello
```

Trailing paragraph.
''',
  '''
```mermaid
%% diagram with comment
graph TD
  X[Start]-->Y{Choice}
```
''',
];

ContentBlock _firstMermaidBlock(List<ContentBlock> blocks) {
  return blocks.firstWhere(
    (block) =>
        block.type == ContentBlockType.codeBlock && block.language == 'mermaid',
  );
}

void main() {
  group('AST and Incremental parsers agree on Mermaid blocks', () {
    for (final sample in _samples) {
      test(
        'language and contentHash match for sample of length ${sample.length}',
        () {
          final astParser = AstMarkdownParser();
          final incParser = IncrementalMarkdownParser();
          final astResult = astParser.parse(sample);
          final incResult = incParser.parse(sample);

          final astMermaid = _firstMermaidBlock(astResult.blocks);
          final incMermaid = _firstMermaidBlock(incResult.blocks);

          expect(astMermaid.language, 'mermaid');
          expect(incMermaid.language, 'mermaid');
          expect(
            incMermaid.rawContent.trim(),
            equals(astMermaid.rawContent.trim()),
          );
          expect(incMermaid.contentHash, astMermaid.contentHash);
        },
      );
    }
  });
}
