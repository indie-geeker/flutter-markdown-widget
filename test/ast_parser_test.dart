// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';

// ast_models.dart is not part of the public API surface, so import it directly.
import 'package:flutter_markdown_widget/src/core/parser/ast_models.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

/// Parses [text] and returns the resulting blocks.
///
/// Note: the returned list is a view of the parser's internal cache. Capture
/// individual [ContentBlock.contentHash] values before calling [parser.reset]
/// or issuing another parse, since the cache is mutated in-place.
List<ContentBlock> parseToBlocks(AstMarkdownParser parser, String text) {
  return parser.parse(text).blocks;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AstMarkdownParser', () {
    // -----------------------------------------------------------------------
    // Group: block type detection
    // -----------------------------------------------------------------------
    group('block type detection', () {
      late AstMarkdownParser parser;
      setUp(() => parser = AstMarkdownParser());

      test('h1 heading → ContentBlockType.heading with level 1', () {
        final blocks = parseToBlocks(parser, '# Heading');
        expect(blocks, hasLength(1));
        expect(blocks[0].type, ContentBlockType.heading);
        expect(blocks[0].headingLevel, 1);
      });

      test('h2 heading → ContentBlockType.heading with level 2', () {
        final blocks = parseToBlocks(parser, '## Heading 2');
        expect(blocks, hasLength(1));
        expect(blocks[0].type, ContentBlockType.heading);
        expect(blocks[0].headingLevel, 2);
      });

      test('plain paragraph → ContentBlockType.paragraph', () {
        final blocks = parseToBlocks(parser, 'Just some plain text.');
        expect(blocks, hasLength(1));
        expect(blocks[0].type, ContentBlockType.paragraph);
      });

      test('fenced code block → ContentBlockType.codeBlock with language', () {
        final blocks = parseToBlocks(
          parser,
          '```dart\nvoid main() {}\n```',
        );
        expect(blocks, hasLength(1));
        expect(blocks[0].type, ContentBlockType.codeBlock);
        expect(blocks[0].language, 'dart');
      });

      test('fenced code block without language has null language', () {
        final blocks = parseToBlocks(parser, '```\nsome code\n```');
        expect(blocks, hasLength(1));
        expect(blocks[0].type, ContentBlockType.codeBlock);
        expect(blocks[0].language, isNull);
      });

      test('blockquote → ContentBlockType.blockquote', () {
        final blocks = parseToBlocks(parser, '> This is a quote');
        expect(blocks, hasLength(1));
        expect(blocks[0].type, ContentBlockType.blockquote);
      });

      test('dash list → ContentBlockType.unorderedList', () {
        final blocks = parseToBlocks(parser, '- item one\n- item two');
        expect(blocks, hasLength(1));
        expect(blocks[0].type, ContentBlockType.unorderedList);
      });

      test('asterisk list → ContentBlockType.unorderedList', () {
        final blocks = parseToBlocks(parser, '* item one\n* item two');
        expect(blocks, hasLength(1));
        expect(blocks[0].type, ContentBlockType.unorderedList);
      });

      test('numbered list → ContentBlockType.orderedList', () {
        final blocks = parseToBlocks(parser, '1. first\n2. second');
        expect(blocks, hasLength(1));
        expect(blocks[0].type, ContentBlockType.orderedList);
      });

      test('GFM table → ContentBlockType.table', () {
        final blocks = parseToBlocks(
          parser,
          '| Name | Age |\n| ---- | --- |\n| Alice | 30 |',
        );
        expect(blocks, hasLength(1));
        expect(blocks[0].type, ContentBlockType.table);
      });

      test('horizontal rule → ContentBlockType.horizontalRule', () {
        final blocks = parseToBlocks(parser, '---');
        expect(blocks, hasLength(1));
        expect(blocks[0].type, ContentBlockType.horizontalRule);
      });

      // The markdown package wraps `![alt](url)` in a <p> element; a
      // standalone image line therefore parses as a paragraph whose inline
      // content contains an <img> node.
      test(
        'standalone image line → ContentBlockType.paragraph '
        '(img is inline inside <p>)',
        () {
          final blocks = parseToBlocks(
            parser,
            '![alt text](https://example.com/img.png)',
          );
          expect(blocks, hasLength(1));
          expect(blocks[0].type, ContentBlockType.paragraph);
        },
      );

      // The LatexBlockSyntax only matches lines consisting solely of $$
      // (optionally with trailing whitespace) followed by body lines and a
      // closing $$ line — i.e. a fenced block, not an inline $$…$$ span.
      test(
        r'fenced LaTeX block ($$\n...\n$$) with enableLatex:true → '
        'ContentBlockType.latexBlock',
        () {
          final latexParser = AstMarkdownParser(enableLatex: true);
          // LatexBlockSyntax matches a line of only $$ as the opening fence.
          const latexDoc = r'$$' '\nE = mc^2\n' r'$$';
          final blocks = parseToBlocks(latexParser, latexDoc);
          expect(blocks, hasLength(1));
          expect(blocks[0].type, ContentBlockType.latexBlock);
        },
      );
    });

    // -----------------------------------------------------------------------
    // Group: AST metadata populated
    // -----------------------------------------------------------------------
    group('AST metadata populated', () {
      late AstMarkdownParser parser;
      setUp(() => parser = AstMarkdownParser());

      test('paragraph with inline content has non-empty inlineNodes', () {
        final blocks = parseToBlocks(parser, 'Hello **world**');
        expect(blocks, hasLength(1));
        final ast = blocks[0].metadata[kAstDataKey] as AstBlockData?;
        expect(ast, isNotNull);
        expect(ast!.inlineNodes, isNotEmpty);
      });

      test('heading with inline content has non-empty inlineNodes', () {
        final blocks = parseToBlocks(parser, '# Title with `code`');
        expect(blocks, hasLength(1));
        final ast = blocks[0].metadata[kAstDataKey] as AstBlockData?;
        expect(ast, isNotNull);
        expect(ast!.inlineNodes, isNotEmpty);
      });

      test('unordered list block has AstListData with ordered=false', () {
        final blocks = parseToBlocks(parser, '- alpha\n- beta\n- gamma');
        expect(blocks, hasLength(1));
        final ast = blocks[0].metadata[kAstDataKey] as AstBlockData?;
        expect(ast, isNotNull);
        final listData = ast!.listData;
        expect(listData, isNotNull);
        expect(listData!.ordered, isFalse);
        expect(listData.items, hasLength(3));
      });

      test('ordered list block has AstListData with ordered=true', () {
        final blocks = parseToBlocks(parser, '1. one\n2. two');
        expect(blocks, hasLength(1));
        final ast = blocks[0].metadata[kAstDataKey] as AstBlockData?;
        expect(ast, isNotNull);
        final listData = ast!.listData;
        expect(listData, isNotNull);
        expect(listData!.ordered, isTrue);
        expect(listData.items, hasLength(2));
      });

      test('table block has AstTableData with headers, rows, and alignments',
          () {
        final blocks = parseToBlocks(
          parser,
          '| A | B |\n|---|---|\n| 1 | 2 |\n| 3 | 4 |',
        );
        expect(blocks, hasLength(1));
        final ast = blocks[0].metadata[kAstDataKey] as AstBlockData?;
        expect(ast, isNotNull);
        final tableData = ast!.tableData;
        expect(tableData, isNotNull);
        // Two header cells.
        expect(tableData!.headers, hasLength(2));
        // Two data rows.
        expect(tableData.rows, hasLength(2));
        // Two alignment entries.
        expect(tableData.alignments, hasLength(2));
      });

      test('blockquote has AstBlockData.children populated', () {
        final blocks = parseToBlocks(parser, '> Some quoted text');
        expect(blocks, hasLength(1));
        final ast = blocks[0].metadata[kAstDataKey] as AstBlockData?;
        expect(ast, isNotNull);
        expect(ast!.children, isNotNull);
        expect(ast.children, isNotEmpty);
      });

      // An inline image inside a paragraph is stored as a paragraph block;
      // the AstBlockData carries inlineNodes that include the <img> element.
      test(
        'paragraph containing only an image has non-empty inlineNodes '
        '(img is inline)',
        () {
          final blocks = parseToBlocks(
            parser,
            '![my alt](https://example.com/photo.jpg)',
          );
          expect(blocks, hasLength(1));
          expect(blocks[0].type, ContentBlockType.paragraph);
          final ast = blocks[0].metadata[kAstDataKey] as AstBlockData?;
          expect(ast, isNotNull);
          expect(ast!.inlineNodes, isNotEmpty);
        },
      );
    });

    // -----------------------------------------------------------------------
    // Group: content hashing
    // -----------------------------------------------------------------------
    group('content hashing', () {
      test('same document parsed twice produces identical contentHash values',
          () {
        const doc = '# Title\n\nHello world\n\n- item 1\n- item 2';
        final parser1 = AstMarkdownParser();
        final parser2 = AstMarkdownParser();

        // Snapshot hashes from independent parser instances.
        final hashes1 =
            parseToBlocks(parser1, doc).map((b) => b.contentHash).toList();
        final hashes2 =
            parseToBlocks(parser2, doc).map((b) => b.contentHash).toList();

        expect(hashes1, hasLength(hashes2.length));
        for (var i = 0; i < hashes1.length; i++) {
          expect(
            hashes1[i],
            hashes2[i],
            reason: 'Block $i contentHash should be equal across parsers',
          );
        }
      });

      test('different content produces different contentHash values', () {
        final parserA = AstMarkdownParser();
        final parserB = AstMarkdownParser();

        // Capture hash before the parser is reused.
        final hashA = parseToBlocks(parserA, 'Hello world')[0].contentHash;
        final hashB = parseToBlocks(parserB, 'Goodbye world')[0].contentHash;

        expect(hashA, isNot(equals(hashB)));
      });

      test('after modifying one block, only that block hash changes', () {
        const doc = '# Title\n\nParagraph one\n\nParagraph two';
        const modified = '# Title\n\nParagraph ONE (changed)\n\nParagraph two';

        final parserOrig = AstMarkdownParser();
        final parserMod = AstMarkdownParser();

        // Snapshot original hashes immediately before any further mutation.
        final origHashes =
            parseToBlocks(parserOrig, doc).map((b) => b.contentHash).toList();
        final updHashes =
            parseToBlocks(parserMod, modified)
                .map((b) => b.contentHash)
                .toList();

        // Block 0: heading unchanged — same hash.
        expect(updHashes[0], equals(origHashes[0]));
        // Block 1: paragraph changed — different hash.
        expect(updHashes[1], isNot(equals(origHashes[1])));
        // Block 2: second paragraph unchanged — same hash.
        expect(updHashes[2], equals(origHashes[2]));
      });
    });

    // -----------------------------------------------------------------------
    // Group: change detection (modifiedIndices)
    // -----------------------------------------------------------------------
    group('change detection (modifiedIndices)', () {
      test('first parse of a 3-block document reports all 3 indices modified',
          () {
        final parser = AstMarkdownParser();
        const doc = '# Heading\n\nParagraph\n\n- list item';
        final result = parser.parse(doc);

        expect(result.blocks, hasLength(3));
        expect(result.modifiedIndices, containsAll([0, 1, 2]));
      });

      test('re-parsing same document produces empty modifiedIndices', () {
        final parser = AstMarkdownParser();
        const doc = '# Heading\n\nParagraph\n\n- list item';
        parser.parse(doc); // first parse — warms cache
        final result = parser.parse(doc); // second parse — no changes

        expect(result.modifiedIndices, isEmpty);
      });

      test('modifying only the second block reports only index 1 as modified',
          () {
        final parser = AstMarkdownParser();
        const original = '# Heading\n\nOriginal paragraph\n\n- list item';
        const modified = '# Heading\n\nChanged paragraph\n\n- list item';

        parser.parse(original);
        final result = parser.parse(modified);

        expect(result.modifiedIndices, equals({1}));
      });
    });

    // -----------------------------------------------------------------------
    // Group: mixed content document
    // -----------------------------------------------------------------------
    group('mixed content document', () {
      test('heading + paragraph + code block + list → correct count and types',
          () {
        final parser = AstMarkdownParser();
        const doc = '''# My Heading

This is a paragraph.

```python
print("hello")
```

- first
- second
- third
''';
        final blocks = parseToBlocks(parser, doc);

        expect(blocks, hasLength(4));
        expect(blocks[0].type, ContentBlockType.heading);
        expect(blocks[1].type, ContentBlockType.paragraph);
        expect(blocks[2].type, ContentBlockType.codeBlock);
        expect(blocks[3].type, ContentBlockType.unorderedList);
      });

      test('code block language is extracted correctly in mixed doc', () {
        final parser = AstMarkdownParser();
        const doc = '''# Title

Some text.

```python
print("hello")
```
''';
        final blocks = parseToBlocks(parser, doc);
        final codeBlock = blocks.firstWhere(
          (b) => b.type == ContentBlockType.codeBlock,
        );
        expect(codeBlock.language, 'python');
      });
    });
  });
}
