import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aquafarm/widgets/highlighted_text.dart';

void main() {
  group('HighlightedText.buildSpans', () {
    test('splits a single marked word into plain and highlighted spans', () {
      final spans = HighlightedText.buildSpans(
        'Water shows <mark>ammonia</mark> spike.',
        const TextStyle(),
      );
      expect(spans.length, 3);
      expect(spans[0].text, 'Water shows ');
      expect(spans[1].text, 'ammonia');
      expect(spans[1].style?.fontWeight, FontWeight.w700);
      expect(spans[2].text, ' spike.');
    });

    test('handles several marks in one snippet', () {
      final spans = HighlightedText.buildSpans(
        '<mark>Ammonia</mark> high, <mark>ammonia</mark> again',
        const TextStyle(),
      );
      final marked =
          spans.where((s) => s.style?.fontWeight == FontWeight.w700).toList();
      expect(marked.length, 2);
      expect(marked[0].text, 'Ammonia');
      expect(marked[1].text, 'ammonia');
    });

    test('falls back to plain text when there are no marks', () {
      final spans = HighlightedText.buildSpans(
        'Routine check, no mortality.',
        const TextStyle(),
      );
      expect(spans.length, 1);
      expect(spans.single.text, 'Routine check, no mortality.');
    });

    test('does not leak stray mark tags into the output', () {
      final spans = HighlightedText.buildSpans(
        'unterminated <mark>ammonia',
        const TextStyle(),
      );
      final all = spans.map((s) => s.text ?? '').join();
      expect(all.contains('<mark>'), isFalse);
      expect(all, 'unterminated ammonia');
    });
  });
}
