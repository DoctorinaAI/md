import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'selection.dart';

class _ScopeMarker extends InheritedWidget {
  const _ScopeMarker({required this.controller, required super.child});

  final MarkdownSelectionController controller;

  @override
  bool updateShouldNotify(_ScopeMarker old) =>
      !identical(controller, old.controller);
}

/// Owns Markdown selection gestures for its subtree and exposes the ambient
/// [MarkdownSelectionController] to descendant `MarkdownWidget`s.
///
/// A mouse/trackpad/stylus drag selects; on touch a long-press-then-drag
/// selects (so a plain swipe still scrolls an enclosing list). Wrap a chat's
/// `ListView` (or any group of `MarkdownWidget`s sharing one controller) in a
/// single scope to get selection that spans widgets and survives disposal.
class MarkdownSelectionScope extends StatelessWidget {
  /// Creates a selection scope backed by [controller].
  const MarkdownSelectionScope({
    required this.controller,
    required this.child,
    super.key,
  });

  /// The controller that owns the selection for this subtree.
  final MarkdownSelectionController controller;

  /// The subtree in which selection gestures apply.
  final Widget child;

  /// The nearest ambient controller, or null if there is no enclosing scope.
  static MarkdownSelectionController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ScopeMarker>()?.controller;

  /// The nearest ambient controller. Throws if there is no enclosing scope.
  static MarkdownSelectionController of(BuildContext context) =>
      maybeOf(context)!;

  @override
  Widget build(BuildContext context) => _ScopeMarker(
        controller: controller,
        child: RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: <Type, GestureRecognizerFactory>{
            PanGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
              () => PanGestureRecognizer(
                supportedDevices: const <PointerDeviceKind>{
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.invertedStylus,
                  PointerDeviceKind.trackpad,
                },
              ),
              (recognizer) => recognizer
                ..dragStartBehavior = DragStartBehavior.down
                ..onStart = ((d) => controller.startAtGlobal(d.globalPosition))
                ..onUpdate =
                    ((d) => controller.extendToGlobal(d.globalPosition)),
            ),
            LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(),
              (recognizer) => recognizer
                ..onLongPressStart =
                    ((d) => controller.startAtGlobal(d.globalPosition))
                ..onLongPressMoveUpdate =
                    ((d) => controller.extendToGlobal(d.globalPosition)),
            ),
          },
          child: child,
        ),
      );
}
