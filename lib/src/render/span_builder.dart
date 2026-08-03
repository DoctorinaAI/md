//ignore_for_file: unnecessary_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../nodes.dart';
import '../theme.dart';

/// Builds a tap recognizer for the given markdown span.
TapGestureRecognizer? _buildTapRecognizer(
  MD$Span span,
  void Function(String title, String url)? onTap,
) {
  if (onTap == null) return null;
  if (span.extra case <String, Object?>{'url': String url}) {
    return TapGestureRecognizer()
      ..onTap = () {
        onTap(span.extra?['alt']?.toString() ?? span.text, url);
      };
  }
  return null;
}

/// Helper function to create a [TextSpan] from markdown spans.
/// This function filters the spans based on the theme's span filter,
/// and applies the appropriate text style to each span.
TextSpan paragraphFromMarkdownSpans({
  required Iterable<MD$Span> spans,
  required MarkdownThemeData theme,
  TextStyle? textStyle,
}) {
  final style = textStyle ?? theme.textStyle;
  final spanFilter = theme.spanFilter;
  final filtered = spanFilter != null ? spans.where(spanFilter) : spans;
  // With an explicit block style, merge it under each span's own style;
  // otherwise the span style stands alone (the block style is applied once, on
  // the parent TextSpan below).
  final merge = textStyle != null;
  TextSpan mapper(MD$Span span) => TextSpan(
        text: span.text,
        style: merge
            ? theme.textStyleFor(span.style).merge(style)
            : theme.textStyleFor(span.style),
        recognizer: span.style.contains(MD$Style.link)
            ? _buildTapRecognizer(span, theme.onLinkTap)
            : null,
      );
  return TextSpan(
    style: textStyle ?? theme.textStyle,
    children: filtered.map<InlineSpan>(mapper).toList(growable: false),
  );
}
