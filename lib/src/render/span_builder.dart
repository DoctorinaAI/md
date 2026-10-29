//ignore_for_file: unnecessary_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../image.dart';
import '../nodes.dart';
import '../theme.dart';
import 'inline_image.dart';

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

/// Whether any of [spans] paints an opaque / translucent fill behind glyphs
/// (`monospace` / `highlight` backgrounds from [MarkdownThemeData]). Used to
/// decide whether the selection tint must paint *above* the cached content
/// picture so those fills do not hide it. Pictures do the same; check the
/// built text with `markdownSpanHasImages`.
bool markdownSpansPaintOpaqueBackground(Iterable<MD$Span> spans) {
  const fills = MD$Style(MD$Style.monospace | MD$Style.highlight);
  for (final span in spans) {
    if (span.style & fills != 0) return true;
  }
  return false;
}

/// The URL of a link or image span, if it has one.
String? _urlOf(MD$Span span) => switch (span.extra) {
      <String, Object?>{'url': final String url} => url,
      _ => null,
    };

/// The title of a link or image span (`[label](url "title")`), if any.
String? _titleOf(MD$Span span) => switch (span.extra) {
      <String, Object?>{'alt': final String title} => title,
      _ => null,
    };

/// Helper function to create a [TextSpan] from markdown spans.
/// This function filters the spans based on the theme's span filter,
/// and applies the appropriate text style to each span.
///
/// With a [MarkdownThemeData.imageResolver], images (and link icons) it
/// resolves become [MarkdownImageSpan]s: lay the resulting text out with
/// [layoutMarkdownText] and paint it with [paintMarkdownText] instead of the
/// plain [TextPainter] methods. Called outside a `MarkdownWidget`, the caller
/// owns those images: listen to [MarkdownImageSpan.image] to repaint, and
/// dispose it with the text.
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
  final resolver = theme.imageResolver;
  if (resolver == null) {
    return TextSpan(
      style: textStyle ?? theme.textStyle,
      children: filtered.map<InlineSpan>(mapper).toList(growable: false),
    );
  }
  TextStyle effective(MD$Span span) => merge
      ? theme.textStyleFor(span.style).merge(style)
      : theme.textStyleFor(span.style);
  final children = <InlineSpan>[];
  for (final span in filtered) {
    final url = _urlOf(span);
    if (url == null) {
      children.add(mapper(span));
    } else if (span.style.contains(MD$Style.image)) {
      final request = MarkdownImageRequest(
        kind: MarkdownImageKind.image,
        url: url,
        text: span.text,
        title: _titleOf(span),
      );
      final image = resolveMarkdownImage(resolver, request);
      children.add(image == null
          ? mapper(span)
          : MarkdownImageSpan(
              image: image,
              request: request,
              modelText: span.text,
              textStyle: effective(span),
            ));
    } else {
      // Only links and images carry a url.
      final request = MarkdownImageRequest(
        kind: MarkdownImageKind.linkIcon,
        url: url,
        text: span.text,
        title: _titleOf(span),
      );
      final icon = resolveMarkdownImage(resolver, request);
      final label = mapper(span);
      if (icon != null) {
        children.add(MarkdownImageSpan(
          image: icon,
          request: request,
          modelText: '',
          textStyle: effective(span),
          recognizer: label.recognizer,
        ));
      }
      children.add(label);
    }
  }
  return TextSpan(
    style: textStyle ?? theme.textStyle,
    children: children,
  );
}
