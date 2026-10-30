/// Gives the event loop a turn. Used where Flutter is not available; with
/// Flutter, `yield_to_ui_flutter.dart` replaces this one.
Future<void> yieldToUi() => Future<void>.delayed(Duration.zero);
