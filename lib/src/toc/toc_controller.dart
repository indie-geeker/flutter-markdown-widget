// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/material.dart';

import 'toc_generator.dart';

/// Callback type for index change events
typedef TocIndexCallback = void Function(int index);

/// Callback type for TOC list change events
typedef TocListCallback = void Function(List<TocEntry> list);

/// Controller that manages the state and coordination between TocWidget and markdown content.
///
/// Provides:
/// - Jump functionality: TOC items can scroll to specific headings in the markdown content
/// - Bidirectional synchronization: Scroll position changes notify the TOC to update the current item
/// - External listener support: External code can listen to index and list changes
///
/// Usage:
/// ```dart
/// final tocController = TocController();
///
/// Widget buildTocWidget() => TocListWidget(controller: tocController);
///
/// Widget buildMarkdown() => MarkdownWidget(data: data, tocController: tocController);
/// ```
///
/// Configuration:
/// ```dart
/// // Show transition effect (TOC highlights intermediate headings during scroll)
/// tocController.syncTocDuringJump = true;
///
/// // Direct jump (TOC jumps directly to target, default behavior)
/// tocController.syncTocDuringJump = false;
/// ```
class TocController {
  /// Maps the widget index in the markdown tree to the corresponding TOC item
  final LinkedHashMap<int, TocEntry> _widgetIndex2TocItem = LinkedHashMap();

  /// Internal callback to jump to a specific index in the markdown content
  TocIndexCallback? _jumpToWidgetIndexCallback;

  /// Listeners notified when the current heading index changes
  final Set<TocIndexCallback> _indexChangeListeners = {};

  /// Listeners notified when the TOC list is updated
  final Set<TocListCallback> _listChangeListeners = {};

  /// Whether the controller has been disposed
  bool _isDisposed = false;

  /// Current active heading index
  int _currentIndex = -1;

  /// Flag indicating whether a programmatic jump is in progress
  /// When true, scroll-based index updates should be ignored
  bool _isJumping = false;

  /// Whether to sync TOC highlights with scroll position during jumps.
  ///
  /// - `true`: TOC highlights intermediate headings as content scrolls (transition effect)
  /// - `false`: TOC jumps directly to target heading without intermediate highlights (default)
  bool syncTocDuringJump = false;

  /// Returns the current list of TOC items.
  List<TocEntry> get tocList => List.unmodifiable(_widgetIndex2TocItem.values);

  /// Returns the current active heading index.
  int get currentIndex => _currentIndex;

  /// Whether the controller has been disposed
  bool get isDisposed => _isDisposed;

  /// Sets the callback that handles jumping to a specific widget index.
  ///
  /// This is typically set by the MarkdownWidget to enable
  /// scroll-to-index functionality when TOC items are tapped.
  set jumpToWidgetIndexCallback(TocIndexCallback? callback) {
    _jumpToWidgetIndexCallback = callback;
  }

  /// Clears the jump callback only when it matches [callback].
  ///
  /// This prevents stale widgets from clearing a newer callback that
  /// was registered by a replacement MarkdownWidget during layout changes.
  void clearJumpToWidgetIndexCallback(TocIndexCallback callback) {
    if (_jumpToWidgetIndexCallback == callback) {
      _jumpToWidgetIndexCallback = null;
    }
  }

  /// Adds a listener that is called when the current heading index changes.
  void addIndexListener(TocIndexCallback listener) {
    if (_isDisposed) return;
    _indexChangeListeners.add(listener);
  }

  /// Removes a previously added index change listener.
  void removeIndexListener(TocIndexCallback listener) {
    _indexChangeListeners.remove(listener);
  }

  /// Adds a listener that is called when the TOC list is updated.
  void addTocListListener(TocListCallback listener) {
    if (_isDisposed) return;
    _listChangeListeners.add(listener);
  }

  /// Removes a previously added list change listener.
  void removeTocListListener(TocListCallback listener) {
    _listChangeListeners.remove(listener);
  }

  /// Updates the TOC list with new items.
  void setTocList(List<TocEntry> list) {
    if (_isDisposed) return;

    _widgetIndex2TocItem.clear();
    for (final item in list) {
      _widgetIndex2TocItem[item.blockIndex] = item;
    }
    _notifyListChanged(List.unmodifiable(list));
  }

  /// Finds the TOC item for a given widget index.
  TocEntry? findTocItemByWidgetIndex(int widgetIndex) {
    return _widgetIndex2TocItem[widgetIndex];
  }

  /// Scrolls the markdown content to the heading at the specified widget index.
  ///
  /// During the jump, scroll-based index updates are suppressed to prevent
  /// TOC from highlighting intermediate headings (unless [syncTocDuringJump] is true).
  void jumpToWidgetIndex(int widgetIndex) {
    if (_isDisposed) return;
    _isJumping = true;

    // Only update index immediately if NOT in sync mode
    // In sync mode, let the scroll listener handle the gradual updates
    if (!syncTocDuringJump) {
      _currentIndex = widgetIndex;
      notifyIndexChanged(widgetIndex);
    }

    _jumpToWidgetIndexCallback?.call(widgetIndex);
  }

  /// Called when jump animation completes to re-enable scroll sync
  void onJumpComplete() {
    _isJumping = false;
  }

  /// Whether a programmatic jump is currently in progress.
  ///
  /// When true, scroll-based TOC updates are suppressed.
  /// In [syncTocDuringJump] mode, Timer handles sequential highlighting instead.
  bool get isJumping => _isJumping;

  /// Notifies all listeners that the current heading index has changed.
  void notifyIndexChanged(int widgetIndex) {
    if (_isDisposed) return;

    _currentIndex = widgetIndex;
    for (final listener in _indexChangeListeners) {
      try {
        listener.call(widgetIndex);
      } catch (e) {
        debugPrint('Error in TocIndexCallback: $e');
      }
    }
  }

  /// Notifies all listeners that the TOC list has changed.
  void _notifyListChanged(List<TocEntry> list) {
    for (final listener in _listChangeListeners) {
      try {
        listener.call(list);
      } catch (e) {
        debugPrint('Error in TocListCallback: $e');
      }
    }
  }

  /// Releases all resources and listeners associated with this controller.
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _widgetIndex2TocItem.clear();
    _indexChangeListeners.clear();
    _listChangeListeners.clear();
    _jumpToWidgetIndexCallback = null;
  }
}
