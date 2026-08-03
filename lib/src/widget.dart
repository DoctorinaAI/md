import 'package:flutter/widgets.dart';

import 'markdown.dart' show Markdown;
import 'render.dart' show MarkdownRenderObject;
import 'selection.dart' show MarkdownSelectionController;
import 'selection_scope.dart' show MarkdownSelectionScope;
import 'theme.dart';

/// {@template markdown_widget}
/// MarkdownWidget widget.
/// {@endtemplate}
class MarkdownWidget extends LeafRenderObjectWidget {
  /// {@macro markdown_widget}
  const MarkdownWidget({
    required this.markdown,
    this.theme,
    this.controller,
    this.documentId,
    super.key, // ignore: unused_element
  });

  /// Current markdown entity to render.
  final Markdown markdown;

  /// Current theme for the markdown widget.
  final MarkdownThemeData? theme;

  /// The selection controller this widget participates in. When null, the
  /// nearest [MarkdownSelectionScope] controller is used, if any.
  final MarkdownSelectionController? controller;

  /// The stable document id used to anchor selection positions. Selection is
  /// only enabled when this is non-null AND a controller is available; the app
  /// must register this document's model with the controller.
  final Object? documentId;

  MarkdownThemeData _resolveTheme(BuildContext context) =>
      theme ??
      MarkdownTheme.maybeOf(context) ??
      MarkdownThemeData(
        textStyle: DefaultTextStyle.of(context).style,
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        textScaler: MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling,
      );

  MarkdownSelectionController? _resolveController(BuildContext context) =>
      documentId == null
          ? null
          : (controller ?? MarkdownSelectionScope.maybeOf(context));

  @override
  RenderObject createRenderObject(BuildContext context) => MarkdownRenderObject(
        markdown: markdown,
        theme: _resolveTheme(context),
      )..updateSelection(_resolveController(context), documentId);

  @override
  void updateRenderObject(
    BuildContext context,
    MarkdownRenderObject renderObject,
  ) {
    renderObject
      ..update(markdown: markdown, theme: _resolveTheme(context))
      ..updateSelection(_resolveController(context), documentId);
  }
}
