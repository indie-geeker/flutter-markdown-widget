// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Sanitizes a string to ensure it is well-formed UTF-16.
///
/// This trims incomplete surrogate pairs that can appear in streaming inputs.
String sanitizeUtf16(String text) {
  if (text.isEmpty) return text;

  final firstCodeUnit = text.codeUnitAt(0);
  if (_isLowSurrogate(firstCodeUnit)) {
    return text.substring(1);
  }

  final lastCodeUnit = text.codeUnitAt(text.length - 1);
  if (_isHighSurrogate(lastCodeUnit)) {
    return text.substring(0, text.length - 1);
  }

  return text;
}

bool _isHighSurrogate(int codeUnit) => codeUnit >= 0xD800 && codeUnit <= 0xDBFF;

bool _isLowSurrogate(int codeUnit) => codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
