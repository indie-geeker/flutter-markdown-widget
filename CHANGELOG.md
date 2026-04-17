## Unreleased

### Added

- `RenderOptions.imagePlaceholderHeight` (default `200.0`) — reserves vertical
  space for network images while they load so scroll position stays stable.

### Changed

- Network image `errorBuilder` now renders inside a `SizedBox` of
  `imagePlaceholderHeight` with centered text (previously rendered at the
  text's intrinsic height). Error states no longer alter scroll geometry.

### Performance

- Lifted per-build `RegExp` literals in `ContentBuilder` to `static final`
  fields, eliminating pattern recompilation in heading, blockquote, list,
  image, and list-item parsing hot paths.
- Hoisted `CodeBlockView`'s language-label, copy-button, and per-line
  line-number `TextStyle` allocations out of `build`, removing N+3 style
  instances per code-block render (N = line count).
- Memoised LaTeX preprocessing in `FormulaBuilder` via a process-wide
  string cache keyed by raw content + block flag; repeated formulas skip
  regex and substring work on rebuild.

## 0.1.0

- Initial release of `flutter_markdown_widget`
- Added dual parser architecture: AST + incremental
- Added streaming rendering via `StreamingMarkdownView.fromStream`
- Added LaTeX, tables, code blocks, task lists, and image rendering support
- Added TOC system (`TocGenerator`, `TocController`, `TocListWidget`)
- Added virtual scrolling support for large markdown documents
- Added example app with feature, streaming, TOC, editor, and performance demos
