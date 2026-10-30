import 'package:flutter/scheduler.dart';

/// How long [yieldToUi] waits for a frame, in case it never comes: frames stop
/// when the app goes to the background while one is awaited.
const Duration _maxFrameWait = Duration(milliseconds: 100);

/// The scheduler binding, or null when this isolate has none: a background
/// isolate, or the main one before the binding is initialized.
SchedulerBinding? get _binding {
  try {
    return SchedulerBinding.instance;
  } on Object {
    return null;
  }
}

/// Lets the UI run: waits for the end of the frame when one is on its way, and
/// otherwise gives the event loop a turn without requesting a frame nothing
/// needs.
Future<void> yieldToUi() {
  final binding = _binding;
  if (binding == null ||
      !binding.framesEnabled ||
      (binding.schedulerPhase == SchedulerPhase.idle &&
          !binding.hasScheduledFrame)) {
    return Future<void>.delayed(Duration.zero);
  }
  return binding.endOfFrame.timeout(_maxFrameWait, onTimeout: () {});
}
