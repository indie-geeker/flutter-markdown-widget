// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_markdown_widget/src/core/mermaid/mermaid_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MermaidError subclasses', () {
    test('MermaidSyntaxError carries source and message', () {
      final err = MermaidSyntaxError(
        source: 'graph LR\n bad',
        message: 'Parse error on line 2',
        stackTrace: StackTrace.current,
      );
      expect(err.source, 'graph LR\n bad');
      expect(err.message, 'Parse error on line 2');
      expect(err, isA<MermaidError>());
    });

    test('MermaidTimeoutError carries elapsed', () {
      final err = MermaidTimeoutError(
        source: 'graph LR',
        elapsed: const Duration(seconds: 5),
        stackTrace: StackTrace.current,
      );
      expect(err.elapsed, const Duration(seconds: 5));
      expect(err, isA<MermaidError>());
    });

    test('MermaidRuntimeError carries cause', () {
      final cause = StateError('engine crash');
      final err = MermaidRuntimeError(
        source: 'graph LR',
        cause: cause,
        stackTrace: StackTrace.current,
      );
      expect(err.cause, cause);
      expect(err, isA<MermaidError>());
    });

    test('MermaidInvalidOutputError carries svg', () {
      final err = MermaidInvalidOutputError(
        source: 'graph LR',
        svg: '<not-svg/>',
        stackTrace: StackTrace.current,
      );
      expect(err.svg, '<not-svg/>');
      expect(err, isA<MermaidError>());
    });

    test('MermaidInitializationError carries cause', () {
      final cause = Exception('asset missing');
      final err = MermaidInitializationError(
        source: 'graph LR',
        cause: cause,
        stackTrace: StackTrace.current,
      );
      expect(err.cause, cause);
      expect(err, isA<MermaidError>());
    });
  });

  group('MermaidErrorContext', () {
    test('exposes error, source, and a retry callback', () {
      final err = MermaidSyntaxError(
        source: 'graph LR',
        message: 'Bad node',
        stackTrace: StackTrace.current,
      );
      var retryCalls = 0;
      final ctx = MermaidErrorContext(
        error: err,
        source: 'graph LR',
        retry: () => retryCalls++,
      );
      expect(ctx.error, err);
      expect(ctx.source, 'graph LR');
      ctx.retry();
      expect(retryCalls, 1);
    });
  });
}
