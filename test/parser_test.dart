// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

void main() {
  group('IncrementalMarkdownParser', () {
    late IncrementalMarkdownParser parser;

    setUp(() {
      parser = IncrementalMarkdownParser();
    });

    group('basic parsing', () {
      test('parses empty string', () {
        final result = parser.parse('');
        expect(result.blocks, isEmpty);
        expect(result.hasChanges, isFalse);
      });

      test('parses single paragraph', () {
        final result = parser.parse('Hello, world!');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.paragraph);
        expect(result.blocks[0].rawContent.trim(), 'Hello, world!');
      });

      test('parses multiple paragraphs', () {
        final result = parser.parse('First paragraph\n\nSecond paragraph');
        expect(result.blocks, hasLength(2));
        expect(result.blocks[0].type, ContentBlockType.paragraph);
        expect(result.blocks[1].type, ContentBlockType.paragraph);
      });
    });

    group('heading parsing', () {
      test('parses h1 heading', () {
        final result = parser.parse('# Heading 1');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.heading);
        expect(result.blocks[0].headingLevel, 1);
      });

      test('parses h2 heading', () {
        final result = parser.parse('## Heading 2');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.heading);
        expect(result.blocks[0].headingLevel, 2);
      });

      test('parses h6 heading', () {
        final result = parser.parse('###### Heading 6');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.heading);
        expect(result.blocks[0].headingLevel, 6);
      });

      test('parses mixed headings and paragraphs', () {
        final result = parser.parse('''# Title

Some content here.

## Subtitle

More content.''');
        expect(result.blocks.length, greaterThanOrEqualTo(4));
        expect(result.blocks[0].type, ContentBlockType.heading);
        expect(result.blocks[0].headingLevel, 1);
      });
    });

    group('code block parsing', () {
      test('parses fenced code block with backticks', () {
        final result = parser.parse('''```dart
void main() {
  print('Hello');
}
```''');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.codeBlock);
        expect(result.blocks[0].language, 'dart');
      });

      test('parses fenced code block with tildes', () {
        final result = parser.parse('''~~~python
print("Hello")
~~~''');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.codeBlock);
        expect(result.blocks[0].language, 'python');
      });

      test('parses code block without language', () {
        final result = parser.parse('''```
code here
```''');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.codeBlock);
        expect(result.blocks[0].language, isNull);
      });
    });

    group('list parsing', () {
      test('parses unordered list with dashes', () {
        final result = parser.parse('- Item 1\n- Item 2\n- Item 3');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.unorderedList);
      });

      test('parses unordered list with asterisks', () {
        final result = parser.parse('* Item 1\n* Item 2');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.unorderedList);
      });

      test('parses ordered list', () {
        final result = parser.parse('1. First\n2. Second\n3. Third');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.orderedList);
      });
    });

    group('blockquote parsing', () {
      test('parses single line blockquote', () {
        final result = parser.parse('> This is a quote');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.blockquote);
      });

      test('parses multi-line blockquote', () {
        final result = parser.parse('> Line 1\n> Line 2\n> Line 3');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.blockquote);
      });
    });

    group('LaTeX parsing', () {
      test('parses LaTeX block', () {
        final result = parser.parse(r'''$$
E = mc^2
$$''');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.latexBlock);
      });

      test('parses inline LaTeX block on same line', () {
        final result = parser.parse(r'$$E = mc^2$$');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.latexBlock);
      });
    });

    group('table parsing', () {
      test('parses GFM table', () {
        final result = parser.parse('''| Header 1 | Header 2 |
| -------- | -------- |
| Cell 1   | Cell 2   |''');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.table);
      });
    });

    group('image parsing', () {
      test('parses standalone image block', () {
        final result = parser.parse('![Alt](https://example.com/image.png)');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.image);
      });
    });

    group('custom syntax parsing', () {
      test('parses custom block syntax into metadata', () {
        final customParser = IncrementalMarkdownParser(
          customBlockSyntaxes: [_NoteBlockSyntax()],
        );

        final result = customParser.parse(':::note This is a note');

        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.htmlBlock);
        expect(result.blocks[0].metadata['tag'], 'note');
        expect(result.blocks[0].metadata['text'], 'This is a note');
      });
    });

    group('horizontal rule parsing', () {
      test('parses horizontal rule with dashes', () {
        final result = parser.parse('---');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.horizontalRule);
      });

      test('parses horizontal rule with asterisks', () {
        final result = parser.parse('***');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.horizontalRule);
      });

      test('parses horizontal rule with underscores', () {
        final result = parser.parse('___');
        expect(result.blocks, hasLength(1));
        expect(result.blocks[0].type, ContentBlockType.horizontalRule);
      });
    });

    group('incremental parsing', () {
      test('caches unchanged content', () {
        const content = 'Hello, world!';
        final result1 = parser.parse(content);
        final result2 = parser.parse(content);

        expect(result1.blocks, hasLength(1));
        expect(result2.blocks, hasLength(1));
        expect(result2.hasChanges, isFalse);
      });

      test('detects changes', () {
        parser.parse('Hello');
        final result = parser.parse('Hello, world!');

        expect(result.hasChanges, isTrue);
        expect(result.modifiedIndices, contains(0));
      });

      test('reset clears cache', () {
        parser.parse('Hello');
        parser.reset();
        final result = parser.parse('Hello');

        expect(result.hasChanges, isTrue);
      });
    });

    group('streaming mode', () {
      test('detects incomplete code block', () {
        final result = parser.parse('```dart\nvoid main() {', isStreaming: true);
        expect(result.incompleteBlock, isNotNull);
        expect(result.incompleteBlock!.expectedType, ContentBlockType.codeBlock);
      });

      test('detects incomplete LaTeX block', () {
        final result = parser.parse(r'$$' '\nE = mc^2', isStreaming: true);
        expect(result.incompleteBlock, isNotNull);
        expect(result.incompleteBlock!.expectedType, ContentBlockType.latexBlock);
      });

      test('no incomplete block for complete content', () {
        final result = parser.parse('Complete paragraph', isStreaming: true);
        expect(result.incompleteBlock, isNull);
      });
    });
  });
}

class _NoteBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^:::note\s+(.+)$');

  @override
  md.Node? parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    if (match == null) {
      return null;
    }
    final text = match.group(1)?.trim() ?? '';
    parser.advance();
    return md.Element('note', [md.Text(text)]);
  }
}
