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
    super.key, // ignore: unused_element
  });

  /// Current markdown entity to render.
  final Markdown markdown;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final theme = MarkdownTheme.maybeOf(context);
    final direction = Directionality.maybeOf(context);
    final scaler = MediaQuery.maybeTextScalerOf(context);
    return MarkdownRenderObject(
      markdown: markdown,
      theme: theme ?? const MarkdownThemeData(),
      painter: TextPainter(
        textAlign: TextAlign.start,
        textDirection: direction ?? TextDirection.ltr,
        textScaler: scaler ?? TextScaler.noScaling,
      ),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    MarkdownRenderObject renderObject,
  ) {
    final theme = MarkdownTheme.maybeOf(context) ?? const MarkdownThemeData();
    final direction = Directionality.maybeOf(context);
    final scaler = MediaQuery.maybeTextScalerOf(context);
    renderObject
      ..markdown = markdown
      ..theme = theme
      ..painter.textAlign = TextAlign.start
      ..painter.textDirection = direction ?? TextDirection.ltr
      ..painter.textScaler = scaler ?? TextScaler.noScaling;
  }
}
