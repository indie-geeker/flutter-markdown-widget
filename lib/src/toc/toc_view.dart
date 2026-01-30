// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'toc_generator.dart';
import 'toc_controller.dart';
import '../style/markdown_theme.dart';

/// A widget that displays a Table of Contents for markdown content.
///
/// The [TocListWidget] shows a list of all headings in the markdown document.
/// It automatically highlights the currently visible heading and supports
/// tap-to-scroll functionality.
///
/// Usage:
/// ```dart
/// final tocController = TocController();
///
/// // In your build method:
/// Row(
///   children: [
///     Expanded(child: TocListWidget(controller: tocController)),
///     Expanded(child: MarkdownWidget(data: data, tocController: tocController), flex: 3),
///   ],
/// )
/// ```
class TocListWidget extends StatefulWidget {
  /// The controller that manages TOC state and coordination.
  final TocController controller;

  /// The scroll physics for the TOC list view.
  final ScrollPhysics? physics;

  /// Whether the list view should shrink-wrap its content.
  final bool shrinkWrap;

  /// Padding for the list view.
  final EdgeInsetsGeometry? padding;

  /// Text style for non-current TOC items.
  final TextStyle? textStyle;

  /// Text style for the currently active TOC item.
  final TextStyle? activeTextStyle;

  /// Active item background color.
  final Color? activeBackgroundColor;

  /// Indentation per heading level.
  final double indentPerLevel;

  /// Custom item builder.
  final Widget Function(BuildContext context, TocEntry entry, bool isActive)? itemBuilder;

  const TocListWidget({
    super.key,
    required this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.textStyle,
    this.activeTextStyle,
    this.activeBackgroundColor,
    this.indentPerLevel = 16.0,
    this.itemBuilder,
  });

  @override
  State<TocListWidget> createState() => _TocListWidgetState();
}

class _TocListWidgetState extends State<TocListWidget> {
  final ScrollController _scrollController = ScrollController();
  List<TocEntry> _tocList = [];
  int _currentIndex = -1;

  TocController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _initListeners();
    _tocList = controller.tocList;
    _currentIndex = controller.currentIndex;
  }

  void _initListeners() {
    controller.addTocListListener(_onTocListChanged);
    controller.addIndexListener(_onIndexChanged);
  }

  void _onTocListChanged(List<TocEntry> list) {
    if (mounted) {
      setState(() {
        _tocList = list;
      });
    }
  }

  void _onIndexChanged(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
      _scrollToCurrentItem();
    }
  }

  void _scrollToCurrentItem() {
    final currentListIndex = _tocList.indexWhere((e) => e.blockIndex == _currentIndex);
    if (currentListIndex >= 0 && _scrollController.hasClients) {
      // Approximate scroll position (each item ~48 pixels)
      final targetOffset = currentListIndex * 48.0;
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        targetOffset.clamp(0, maxScroll),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(TocListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeTocListListener(_onTocListChanged);
      oldWidget.controller.removeIndexListener(_onIndexChanged);
      _initListeners();
      _tocList = widget.controller.tocList;
    }
  }

  @override
  void dispose() {
    controller.removeTocListListener(_onTocListChanged);
    controller.removeIndexListener(_onIndexChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tocList.isEmpty) {
      return const Center(
        child: Text('No headings found'),
      );
    }

    return ListView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      controller: _scrollController,
      padding: widget.padding,
      itemCount: _tocList.length,
      itemBuilder: (context, index) {
        final entry = _tocList[index];
        final isActive = entry.blockIndex == _currentIndex;

        if (widget.itemBuilder != null) {
          return widget.itemBuilder!(context, entry, isActive);
        }

        return _buildDefaultItem(context, entry, isActive);
      },
    );
  }

  Widget _buildDefaultItem(BuildContext context, TocEntry entry, bool isActive) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = theme.colorScheme.primary;
    final inactiveColor = isDark ? Colors.grey[400] : Colors.grey[700];
    final activeBackground = widget.activeBackgroundColor ?? 
        activeColor.withValues(alpha: 0.1);

    final baseStyle = widget.textStyle ?? TextStyle(
      fontSize: entry.level == 1 ? 14 : 13,
      color: inactiveColor,
    );

    final activeStyle = widget.activeTextStyle ?? baseStyle.copyWith(
      color: activeColor,
      fontWeight: FontWeight.w600,
    );

    return Material(
      color: isActive ? activeBackground : Colors.transparent,
      child: InkWell(
        onTap: () => controller.jumpToWidgetIndex(entry.blockIndex),
        child: Padding(
          padding: EdgeInsets.only(
            left: 12 + (entry.level - 1) * widget.indentPerLevel,
            right: 12,
            top: 10,
            bottom: 10,
          ),
          child: Row(
            children: [
              if (isActive)
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Expanded(
                child: Text(
                  entry.title,
                  style: isActive ? activeStyle : baseStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Widget for displaying a table of contents (legacy, kept for compatibility).
class TocView extends StatelessWidget {
  /// Creates a TOC view.
  const TocView({
    super.key,
    required this.entries,
    this.onEntryTap,
    this.activeIndex,
    this.showNumbers = false,
    this.indentPerLevel = 16.0,
    this.itemPadding = const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    this.activeColor,
    this.inactiveColor,
    this.activeBackgroundColor,
    this.textStyle,
    this.activeTextStyle,
  });

  /// TOC entries to display.
  final List<TocEntry> entries;

  /// Callback when an entry is tapped.
  final void Function(TocEntry entry)? onEntryTap;

  /// Currently active/visible heading index.
  final int? activeIndex;

  /// Whether to show section numbers.
  final bool showNumbers;

  /// Indentation per heading level.
  final double indentPerLevel;

  /// Padding around each item.
  final EdgeInsets itemPadding;

  /// Color for active entry text.
  final Color? activeColor;

  /// Color for inactive entry text.
  final Color? inactiveColor;

  /// Background color for active entry.
  final Color? activeBackgroundColor;

  /// Text style for entries.
  final TextStyle? textStyle;

  /// Text style for active entry.
  final TextStyle? activeTextStyle;

  @override
  Widget build(BuildContext context) {
    final theme = MarkdownThemeProvider.maybeOf(context);
    final defaultTextStyle = theme?.textStyle ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _countAllEntries(entries),
      itemBuilder: (context, index) {
        final (entry, depth) = _getEntryAtFlatIndex(entries, index);
        return _buildEntry(context, entry, depth, defaultTextStyle);
      },
    );
  }

  Widget _buildEntry(
    BuildContext context,
    TocEntry entry,
    int depth,
    TextStyle defaultStyle,
  ) {
    final isActive = activeIndex == entry.blockIndex;
    final theme = Theme.of(context);

    final effectiveActiveColor =
        activeColor ?? theme.colorScheme.primary;
    final effectiveInactiveColor =
        inactiveColor ?? theme.textTheme.bodyMedium?.color ?? Colors.black87;
    final effectiveActiveBackground =
        activeBackgroundColor ?? theme.colorScheme.primary.withValues(alpha: 0.1);

    final style = isActive
        ? (activeTextStyle ??
            (textStyle ?? defaultStyle).copyWith(
              color: effectiveActiveColor,
              fontWeight: FontWeight.w600,
            ))
        : (textStyle ?? defaultStyle).copyWith(
            color: effectiveInactiveColor,
          );

    return Material(
      color: isActive ? effectiveActiveBackground : Colors.transparent,
      child: InkWell(
        onTap: onEntryTap != null ? () => onEntryTap!(entry) : null,
        child: Padding(
          padding: itemPadding.copyWith(
            left: itemPadding.left + (depth * indentPerLevel),
          ),
          child: Row(
            children: [
              if (showNumbers) ...[
                Text(
                  _getNumberPrefix(entry, entries),
                  style: style.copyWith(
                    fontWeight: FontWeight.w500,
                    color: style.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  entry.title,
                  style: style,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: effectiveActiveColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _countAllEntries(List<TocEntry> entries) {
    int count = 0;
    for (final entry in entries) {
      count += 1 + _countAllEntries(entry.children);
    }
    return count;
  }

  (TocEntry, int) _getEntryAtFlatIndex(List<TocEntry> entries, int index) {
    int currentIndex = 0;

    for (final entry in entries) {
      if (currentIndex == index) {
        return (entry, 0);
      }
      currentIndex++;

      final childResult = _findInChildren(entry.children, index - currentIndex, 1);
      if (childResult != null) {
        return childResult;
      }
      currentIndex += _countAllEntries(entry.children);
    }

    // Fallback (shouldn't happen)
    return (entries.first, 0);
  }

  (TocEntry, int)? _findInChildren(
    List<TocEntry> entries,
    int relativeIndex,
    int depth,
  ) {
    int currentIndex = 0;

    for (final entry in entries) {
      if (currentIndex == relativeIndex) {
        return (entry, depth);
      }
      currentIndex++;

      final childResult = _findInChildren(
        entry.children,
        relativeIndex - currentIndex,
        depth + 1,
      );
      if (childResult != null) {
        return childResult;
      }
      currentIndex += _countAllEntries(entry.children);
    }

    return null;
  }

  String _getNumberPrefix(TocEntry entry, List<TocEntry> allEntries) {
    // Simple flat numbering
    int number = 0;
    for (final e in _flattenEntries(allEntries)) {
      number++;
      if (e.blockIndex == entry.blockIndex) {
        return '$number.';
      }
    }
    return '';
  }

  Iterable<TocEntry> _flattenEntries(List<TocEntry> entries) sync* {
    for (final entry in entries) {
      yield entry;
      yield* _flattenEntries(entry.children);
    }
  }
}

/// A compact inline TOC widget.
class InlineTocView extends StatelessWidget {
  /// Creates an inline TOC view.
  const InlineTocView({
    super.key,
    required this.entries,
    this.onEntryTap,
    this.separator = ' • ',
    this.textStyle,
  });

  /// TOC entries to display.
  final List<TocEntry> entries;

  /// Callback when an entry is tapped.
  final void Function(TocEntry entry)? onEntryTap;

  /// Separator between entries.
  final String separator;

  /// Text style for entries.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final flatEntries = _flattenEntries(entries).toList();
    final theme = Theme.of(context);

    return Wrap(
      children: [
        for (int i = 0; i < flatEntries.length; i++) ...[
          GestureDetector(
            onTap: onEntryTap != null
                ? () => onEntryTap!(flatEntries[i])
                : null,
            child: Text(
              flatEntries[i].title,
              style: textStyle ??
                  TextStyle(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
          if (i < flatEntries.length - 1)
            Text(separator, style: textStyle),
        ],
      ],
    );
  }

  Iterable<TocEntry> _flattenEntries(List<TocEntry> entries) sync* {
    for (final entry in entries) {
      yield entry;
      yield* _flattenEntries(entry.children);
    }
  }
}
