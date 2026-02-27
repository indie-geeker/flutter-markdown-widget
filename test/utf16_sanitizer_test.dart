import 'package:flutter_markdown_widget/src/core/text/utf16_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeUtf16', () {
    test('removes trailing lone high surrogate', () {
      const input = 'A\uD83D';
      expect(sanitizeUtf16(input), 'A');
    });

    test('removes leading lone low surrogate', () {
      const input = '\uDC00B';
      expect(sanitizeUtf16(input), 'B');
    });

    test('keeps valid emoji pair unchanged', () {
      const input = 'Hi 😀';
      expect(sanitizeUtf16(input), input);
    });

    test('keeps normal ascii unchanged', () {
      const input = 'hello world';
      expect(sanitizeUtf16(input), input);
    });
  });
}
