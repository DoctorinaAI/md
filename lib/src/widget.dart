import 'package:flutter/widgets.dart';

import 'markdown.dart' show Markdown;
import 'render.dart' show MarkdownRenderObject;
import 'theme.dart';

/// {@template markdown_widget}
/// MarkdownWidget widget.
/// {@endtemplate}
class MarkdownWidget extends LeafRenderObjectWidget {
  /// {@macro markdown_widget}
  const MarkdownWidget({
    required this.markdown,
    this.theme,
    super.key, // ignore: unused_element
  });

  /// Current markdown entity to render.
  final Markdown markdown;

  /// Current theme for the markdown widget.
  final MarkdownThemeData? theme;

  @override
  RenderObject createRenderObject(BuildContext context) => MarkdownRenderObject(
        markdown: markdown,
        theme: theme ??
            MarkdownTheme.maybeOf(context) ??
            const MarkdownThemeData(),
        painter: TextPainter(
          textAlign: TextAlign.start,
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          textScaler:
              MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling,
        ),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    MarkdownRenderObject renderObject,
  ) =>
      renderObject.update(
        markdown: markdown,
        theme: theme ??
            MarkdownTheme.maybeOf(context) ??
            const MarkdownThemeData(),
        direction: Directionality.maybeOf(context) ?? TextDirection.ltr,
        textScaler:
            MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling,
      );
}
