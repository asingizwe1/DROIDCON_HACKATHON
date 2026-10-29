import 'package:flutter/material.dart';

import '../config/aqua_colors.dart';

/// Renders a Typesense snippet, bolding the words Typesense wrapped in
/// `<mark>` tags.
///
/// Typesense returns the matched tokens wrapped in `<mark>...</mark>`. Rather
/// than pull in an HTML renderer for one tag, this walks the string and splits
/// on the tags. The snippet is plain text from our own index, never user
/// supplied HTML, so there is nothing to sanitize but the tags themselves.
class HighlightedText extends StatelessWidget {
  final String snippet;
  final int maxLines;
  final TextStyle? style;

  const HighlightedText(
    this.snippet, {
    super.key,
    this.maxLines = 3,
    this.style,
  });

  static const String _open = '<mark>';
  static const String _close = '</mark>';

  /// Splits [snippet] into spans, alternating plain and highlighted.
  static List<TextSpan> buildSpans(String snippet, TextStyle? base) {
    final spans = <TextSpan>[];
    var rest = snippet;
    final highlightStyle = (base ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      color: AquaColors.primary,
      backgroundColor: AquaColors.primary.withValues(alpha: 0.12),
    );

    while (rest.isNotEmpty) {
      final open = rest.indexOf(_open);
      if (open == -1) {
        spans.add(TextSpan(text: _stripTags(rest), style: base));
        break;
      }
      final before = rest.substring(0, open);
      if (before.isNotEmpty) {
        spans.add(TextSpan(text: _stripTags(before), style: base));
      }
      final afterOpen = rest.substring(open + _open.length);
      final close = afterOpen.indexOf(_close);
      if (close == -1) {
        // Unterminated tag: treat the remainder as highlighted.
        spans.add(
          TextSpan(text: _stripTags(afterOpen), style: highlightStyle),
        );
        break;
      }
      spans.add(TextSpan(
        text: afterOpen.substring(0, close),
        style: highlightStyle,
      ));
      rest = afterOpen.substring(close + _close.length);
    }
    return spans;
  }

  static String _stripTags(String value) =>
      value.replaceAll(_open, '').replaceAll(_close, '');

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ??
        Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black87);
    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: buildSpans(snippet, baseStyle)),
    );
  }
}
