// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:markdown/markdown.dart' as md;

/// Custom block syntax for LaTeX blocks ($$...$$).
class LatexBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\$\$\s*$');

  @override
  md.Node? parse(md.BlockParser parser) {
    final buffer = StringBuffer();
    buffer.writeln(parser.current.content);
    parser.advance();

    while (!parser.isDone) {
      final line = parser.current.content;
      buffer.writeln(line);
      if (line.trim() == r'$$') {
        parser.advance();
        break;
      }
      parser.advance();
    }

    return md.Element('latex_block', [md.Text(buffer.toString())]);
  }
}

/// Custom inline syntax for LaTeX ($...$).
class LatexInlineSyntax extends md.InlineSyntax {
  LatexInlineSyntax() : super(r'\$([^\$]+)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final latex = match[1]!;
    parser.addNode(md.Element.text('latex_inline', latex));
    return true;
  }
}

/// Custom inline syntax for auto-linking bare URLs.
class AutoLinkSyntax extends md.InlineSyntax {
  AutoLinkSyntax() : super(r'(?:(?:https?|ftp):\/\/|www\.)[^\s<]+');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final raw = match[0]!;
    final trimmed = _trimTrailingPunctuation(raw);
    if (trimmed.isEmpty) {
      return false;
    }

    final href = trimmed.startsWith('www.') ? 'https://$trimmed' : trimmed;
    final element = md.Element('a', [md.Text(trimmed)])
      ..attributes['href'] = href;
    parser.addNode(element);

    final trailing = raw.substring(trimmed.length);
    if (trailing.isNotEmpty) {
      parser.addNode(md.Text(trailing));
    }

    return true;
  }

  String _trimTrailingPunctuation(String text) {
    const trailingPunctuation = {'.', ',', ';', ':', '!', '?'};
    var end = text.length;
    while (end > 0 && trailingPunctuation.contains(text[end - 1])) {
      end--;
    }
    return text.substring(0, end);
  }
}
