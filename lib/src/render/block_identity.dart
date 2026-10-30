import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart' as meta show internal;

import '../nodes.dart';

bool _sameList<T>(List<T> a, List<T> b, bool Function(T, T) same) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!same(a[i], b[i])) return false;
  }
  return true;
}

bool _sameSpan(MD$Span a, MD$Span b) =>
    identical(a, b) ||
    (a.style == b.style &&
        a.start == b.start &&
        a.end == b.end &&
        a.text == b.text &&
        mapEquals(a.extra, b.extra));

bool _sameSpans(List<MD$Span> a, List<MD$Span> b) => _sameList(a, b, _sameSpan);

bool _sameItem(MD$ListItem a, MD$ListItem b) =>
    identical(a, b) ||
    (a.indent == b.indent &&
        a.checked == b.checked &&
        a.marker == b.marker &&
        a.text == b.text &&
        _sameSpans(a.spans, b.spans) &&
        _sameList(a.children, b.children, _sameItem));

bool _sameRow(MD$TableRow a, MD$TableRow b) =>
    identical(a, b) || _sameList(a.cells, b.cells, _sameSpans);

/// Whether blocks [a] and [b], usually from two parses of a growing document,
/// describe the same content, so a painter of one can stand in for the other.
///
/// Parsing yields new objects every time, and the nodes have no `==`.
@meta.internal
bool markdownBlocksSame(MD$Block a, MD$Block b) {
  if (identical(a, b)) return true;
  return switch ((a, b)) {
    (final MD$Paragraph a, final MD$Paragraph b) =>
      a.text == b.text && _sameSpans(a.spans, b.spans),
    (final MD$Heading a, final MD$Heading b) =>
      a.level == b.level && a.text == b.text && _sameSpans(a.spans, b.spans),
    (final MD$Quote a, final MD$Quote b) => a.indent == b.indent &&
        a.text == b.text &&
        _sameSpans(a.spans, b.spans) &&
        _sameList(a.blocks, b.blocks, markdownBlocksSame),
    (final MD$Alert a, final MD$Alert b) => a.alert == b.alert &&
        a.text == b.text &&
        _sameSpans(a.spans, b.spans) &&
        _sameList(a.blocks, b.blocks, markdownBlocksSame),
    (final MD$Code a, final MD$Code b) =>
      a.language == b.language && a.text == b.text,
    (final MD$List a, final MD$List b) =>
      a.text == b.text && _sameList(a.items, b.items, _sameItem),
    (MD$Divider(), MD$Divider()) => true,
    (final MD$Table a, final MD$Table b) => a.text == b.text &&
        listEquals(a.alignments, b.alignments) &&
        _sameRow(a.header, b.header) &&
        _sameList(a.rows, b.rows, _sameRow),
    (final MD$Spacer a, final MD$Spacer b) => a.count == b.count,
    _ => false,
  };
}
