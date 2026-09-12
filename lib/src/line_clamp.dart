import 'markdown.dart';
import 'render/markdown_painter.dart';
import 'theme.dart';

/// Where a markdown document has to be cut to show a limited number of lines.
final class MarkdownLineClamp {
  /// Creates a clamp result.
  const MarkdownLineClamp({
    required this.height,
    required this.clampedHeight,
  });

  /// Full content height at the measured width.
  final double height;

  /// Height holding at most the requested lines, ending on a line boundary.
  /// Equals [height] when the whole document fits.
  final double clampedHeight;

  /// Whether the line budget leaves content out.
  bool get overflows => clampedHeight < height;

  @override
  String toString() =>
      'MarkdownLineClamp(height: $height, clampedHeight: $clampedHeight)';
}

/// Measures [markdown] at [maxWidth] and reports where its first [maxLines]
/// text lines end.
///
/// Lays the document out on its own so a caller can size a clipped box before
/// the renderer runs — the renderer has no line budget of its own. Cutting on
/// a line boundary is what keeps a clipped view from showing half a line.
///
/// Line counting follows the rules of [MarkdownPainter.textLineBottoms]: blank
/// lines and dividers add height without spending the budget, so a clamp never
/// ends on trailing blank space.
MarkdownLineClamp clampMarkdownToLines({
  required Markdown markdown,
  required MarkdownThemeData theme,
  required double maxWidth,
  required int maxLines,
}) {
  final painter = MarkdownPainter(markdown: markdown, theme: theme);
  try {
    final height = painter.layout(maxWidth: maxWidth).height;
    if (maxLines <= 0) {
      return MarkdownLineClamp(height: height, clampedHeight: 0);
    }
    final lines = painter.textLineBottoms();
    if (lines.length <= maxLines) {
      return MarkdownLineClamp(height: height, clampedHeight: height);
    }
    return MarkdownLineClamp(
      height: height,
      clampedHeight: lines[maxLines - 1],
    );
  } finally {
    painter.dispose();
  }
}
