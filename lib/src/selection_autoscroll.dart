// ignore_for_file: lines_longer_than_80_chars

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Edge-zone autoscroll while dragging a markdown selection.
///
/// Activation bands sit on the **padded scrollable viewport** (with optional
/// overshoot past the pad). The host union is the **hard stop / gate**:
///
/// - Toward start only while host content still extends above the pad top
///   (`hostTop < paddedTop`), or the whole host sits above the viewport.
/// - Toward end only while host content still extends below the pad bottom
///   (`hostBottom > paddedBottom`), or the whole host sits below the viewport.
///
/// A mid-viewport host that fits inside the pad therefore never drives the
/// far scrollable chrome. Inside the pad ± [edgeZone], velocity ramps with
/// depth; past that outer band, scroll continues at [maxVelocity] while the
/// host union still allows that direction (finger held past the edge), and
/// idles / hard-stops once the union is flush.
///
/// After a hard stop, [MarkdownAutoscrollSession] disarms that direction until
/// the pointer leaves and re-enters the band (arming gate).
final class MarkdownSelectionAutoscrollConfig {
  /// Creates an autoscroll config.
  const MarkdownSelectionAutoscrollConfig({
    this.enabled = true,
    this.edgeZone = 48,
    this.maxVelocity = 600,
    this.topPad = 0,
    this.bottomPad = 0,
    this.useMediaQueryPadding = true,
  })  : assert(edgeZone > 0),
        assert(maxVelocity >= 0),
        assert(topPad >= 0),
        assert(bottomPad >= 0);

  /// Autoscroll disabled — selection never drives the ancestor scrollable.
  static const disabled = MarkdownSelectionAutoscrollConfig(enabled: false);

  /// Whether edge-zone scrolling is active.
  final bool enabled;

  /// Height of each edge band, in logical pixels.
  final double edgeZone;

  /// Scroll speed (px/s) at the outer edge of the band (`d == edgeZone`).
  final double maxVelocity;

  /// Extra inset before the top band starts (added on top of media-query pad).
  final double topPad;

  /// Extra inset before the bottom band starts.
  final double bottomPad;

  /// When true, [MediaQuery.padding] / [MediaQuery.viewPadding] are added to
  /// [topPad]/[bottomPad] so the edge zone starts before handles disappear
  /// under app chrome.
  final bool useMediaQueryPadding;
}

/// Per-drag arming state for the host-union autoscroll gate.
///
/// After a hard stop in one direction, that direction stays disarmed until the
/// pointer leaves the activation band (re-armed on leave so the next enter can
/// scroll again).
final class MarkdownAutoscrollSession {
  bool _disarmedTowardStart = false;
  bool _disarmedTowardEnd = false;

  /// Whether scrolling toward the start (min extent) is disarmed.
  bool get isDisarmedTowardStart => _disarmedTowardStart;

  /// Whether scrolling toward the end (max extent) is disarmed.
  bool get isDisarmedTowardEnd => _disarmedTowardEnd;

  /// Whether [towardStart] (min) or the opposite (max) direction is disarmed.
  bool isDisarmed({required bool towardStart}) =>
      towardStart ? _disarmedTowardStart : _disarmedTowardEnd;

  /// Disarms scrolling toward start (min) or end (max).
  void disarm({required bool towardStart}) {
    if (towardStart) {
      _disarmedTowardStart = true;
    } else {
      _disarmedTowardEnd = true;
    }
  }

  /// Clears both direction gates (call on drag start / end).
  void reset() {
    _disarmedTowardStart = false;
    _disarmedTowardEnd = false;
  }
}

/// Outcome of one autoscroll step.
enum MarkdownAutoscrollResult {
  /// Not in an edge band (or disabled / no scrollable).
  idle,

  /// Scrolled (or held in-band while scrolling). Caller should keep ticking
  /// while the drag remains active.
  scrolled,

  /// Pointer is in an edge band but we must not scroll (host-union edge already
  /// flush, scrollable cannot move, or arming gate disarmed). Caller should
  /// **stop the ticker** until the next pointer update re-enters a band.
  suppressed,
}

/// Signed scroll velocity (px/s) for a pointer [localY] inside a **clip** of
/// height [clipHeight] whose top is at [clipTopLocalY] in the same local space.
///
/// Positive means toward later text / max scroll for a standard downward axis;
/// callers flip the sign for reverse axes.
@visibleForTesting
double markdownAutoscrollVelocity({
  required double localY,
  required double clipTopLocalY,
  required double clipHeight,
  required MarkdownSelectionAutoscrollConfig config,
}) {
  if (!config.enabled || clipHeight <= 0) return 0;
  final edge = config.edgeZone;
  final topThreshold = clipTopLocalY + edge;
  final bottomThreshold = clipTopLocalY + clipHeight - edge;
  // Allow up to [edge] past the clip so pad insets / finger jitter just
  // outside the visible host union still drive scroll — but not the far
  // scrollable chrome when the host sits mid-viewport.
  final outerTop = clipTopLocalY - edge;
  final outerBottom = clipTopLocalY + clipHeight + edge;
  if (localY < topThreshold && localY >= outerTop) {
    final depth = (topThreshold - localY).clamp(0.0, edge);
    final t = depth / edge;
    return -config.maxVelocity * t * t;
  }
  if (localY > bottomThreshold && localY <= outerBottom) {
    final depth = (localY - bottomThreshold).clamp(0.0, edge);
    final t = depth / edge;
    return config.maxVelocity * t * t;
  }
  return 0;
}

/// Convenience overload: velocity against a full viewport with pad insets
/// (unit tests that don't need an explicit host-union clip).
@visibleForTesting
double markdownAutoscrollVelocityInViewport({
  required double localY,
  required double viewportHeight,
  required MarkdownSelectionAutoscrollConfig config,
  double resolvedTopPad = 0,
  double resolvedBottomPad = 0,
}) {
  final clipTop = resolvedTopPad;
  final clipHeight = viewportHeight - resolvedTopPad - resolvedBottomPad;
  return markdownAutoscrollVelocity(
    localY: localY,
    clipTopLocalY: clipTop,
    clipHeight: clipHeight,
    config: config,
  );
}

/// Resolves effective top/bottom pads: explicit config + optional MediaQuery.
@visibleForTesting
(double top, double bottom) resolveMarkdownAutoscrollPads({
  required MarkdownSelectionAutoscrollConfig config,
  required BuildContext? context,
}) {
  var top = config.topPad;
  var bottom = config.bottomPad;
  if (context case final context?
      when context.mounted && config.useMediaQueryPadding) {
    final data = [
      MediaQuery.maybePaddingOf(context),
      MediaQuery.maybeViewPaddingOf(context)
    ];
    if (data case [final padding?, final viewPadding?]) {
      top += math.max(padding.top, viewPadding.top);
      bottom += math.max(padding.bottom, viewPadding.bottom);
    }
  }
  return (top, bottom);
}

/// Applies one autoscroll step to the nearest ancestor [Scrollable] of
/// [context].
///
/// [hostUnionTopGlobalY] / [hostUnionBottomGlobalY] are the global Y bounds of
/// the union of mounted selectable bodies under the selection host. Bands use
/// the padded viewport; the host union only gates / hard-stops each direction.
MarkdownAutoscrollResult applyMarkdownSelectionAutoscroll({
  required Offset globalPosition,
  required BuildContext? context,
  required MarkdownSelectionAutoscrollConfig config,
  required Duration? lastTimestamp,
  required void Function(Duration?) storeTimestamp,
  required double hostUnionTopGlobalY,
  required double hostUnionBottomGlobalY,
  MarkdownAutoscrollSession? session,
}) {
  void clear() => storeTimestamp(null);

  if (!config.enabled || context == null || !context.mounted) {
    clear();
    return MarkdownAutoscrollResult.idle;
  }
  final scrollable = _scrollableFor(context);
  if (scrollable == null) {
    clear();
    return MarkdownAutoscrollResult.idle;
  }
  final position = scrollable.position;
  if (!position.hasPixels || !position.hasContentDimensions) {
    clear();
    return MarkdownAutoscrollResult.idle;
  }

  final box = scrollable.context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) {
    clear();
    return MarkdownAutoscrollResult.idle;
  }

  final (topPad, bottomPad) = resolveMarkdownAutoscrollPads(
    config: config,
    context: scrollable.context,
  );
  final hostPads = resolveMarkdownAutoscrollPads(
    config: config,
    context: context,
  );
  var resolvedTop = math.max(topPad, hostPads.$1);
  var resolvedBottom = math.max(bottomPad, hostPads.$2);

  // Chrome that sits *outside* the scrollable (AppBar above / bottom nav below)
  // still eats finger space in screen coords. Fold that gap into the pads so
  // the edge band starts before handles vanish under it.
  final screenHeight = MediaQuery.maybeSizeOf(context)?.height;
  if (config.useMediaQueryPadding && screenHeight != null) {
    final origin = box.localToGlobal(Offset.zero);
    final above = origin.dy;
    final below = screenHeight - (origin.dy + box.size.height);
    if (below > 0) {
      resolvedBottom = math.max(resolvedBottom, below.clamp(0.0, 120.0));
    }
    if (above > 0 && resolvedTop < 8) {
      resolvedTop = math.max(resolvedTop, 8);
    }
  }

  final viewportOriginY = box.localToGlobal(Offset.zero).dy;
  final viewportHeight = box.size.height;
  final localY = globalPosition.dy - viewportOriginY;

  final paddedTop = viewportOriginY + resolvedTop;
  final paddedBottom = viewportOriginY + viewportHeight - resolvedBottom;
  final clipHeight = paddedBottom - paddedTop;
  if (clipHeight <= 0) {
    session?.reset();
    clear();
    return MarkdownAutoscrollResult.idle;
  }

  // Host still has content to reveal past each pad edge (or sits entirely
  // off-screen past that edge — drag must be able to pull it back).
  final canTowardStart = hostUnionTopGlobalY < paddedTop - 0.5 ||
      hostUnionBottomGlobalY <= paddedTop + 0.5;
  final canTowardEnd = hostUnionBottomGlobalY > paddedBottom + 0.5 ||
      hostUnionTopGlobalY >= paddedBottom - 0.5;

  final clipTopLocal = resolvedTop;
  var velocity = markdownAutoscrollVelocity(
    localY: localY,
    clipTopLocalY: clipTopLocal,
    clipHeight: clipHeight,
    config: config,
  );

  if (velocity == 0) {
    // Past the quadratic outer band: keep scrolling at max while the host
    // union still has content that way (finger held past the viewport edge).
    // Mid-viewport hosts that do not extend past the pad stay gated out.
    final outerTop = clipTopLocal - config.edgeZone;
    final outerBottom = clipTopLocal + clipHeight + config.edgeZone;
    if (localY < outerTop && canTowardStart) {
      velocity = -config.maxVelocity;
    } else if (localY > outerBottom && canTowardEnd) {
      velocity = config.maxVelocity;
    } else {
      // Left the band (or past-viewport with nothing left to reveal) → re-arm.
      session?.reset();
      clear();
      return MarkdownAutoscrollResult.idle;
    }
  }

  final towardStart = velocity < 0;
  // Direction gate: band hit but host has nothing left to reveal that way.
  if ((towardStart && !canTowardStart) || (!towardStart && !canTowardEnd)) {
    session?.disarm(towardStart: towardStart);
    clear();
    return MarkdownAutoscrollResult.suppressed;
  }

  if (session != null && session.isDisarmed(towardStart: towardStart)) {
    clear();
    return MarkdownAutoscrollResult.suppressed;
  }

  // Reverse axes: positive velocity should still mean "toward maxScrollExtent".
  velocity = switch (scrollable.axisDirection) {
    AxisDirection.down || AxisDirection.right => velocity,
    AxisDirection.up || AxisDirection.left => -velocity,
  };

  final previous = lastTimestamp;
  final now = _autoscrollNow(previous);
  storeTimestamp(now);
  final dtSeconds =
      previous == null ? 1 / 60 : (now - previous).inMicroseconds / 1e6;
  final dt = dtSeconds.clamp(0.0, 0.05);
  final delta = velocity * dt;
  if (delta.abs() < 0.5) {
    return MarkdownAutoscrollResult.scrolled;
  }

  final before = position.pixels;
  final next = (before + delta).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  if ((next - before).abs() < 0.5) {
    session?.disarm(towardStart: towardStart);
    clear();
    return MarkdownAutoscrollResult.suppressed;
  }

  position.jumpTo(next);
  return MarkdownAutoscrollResult.scrolled;
}

Duration _autoscrollNow(Duration? last) {
  final binding = SchedulerBinding.instance;
  return switch (binding.schedulerPhase) {
    SchedulerPhase.idle =>
      (last ?? Duration.zero) + const Duration(milliseconds: 16),
    _ => binding.currentFrameTimeStamp,
  };
}

/// Like [Scrollable.maybeOf], but also accepts a context whose widget *is* the
/// [Scrollable] (maybeOf only walks ancestors).
ScrollableState? _scrollableFor(BuildContext context) => switch (context) {
      StatefulElement(state: final ScrollableState state) => state,
      _ => Scrollable.maybeOf(context),
    };

/// Convenience: depth fraction used by tests / diagnostics.
@visibleForTesting
double markdownAutoscrollDepthFraction({
  required double localY,
  required double clipTopLocalY,
  required double clipHeight,
  required MarkdownSelectionAutoscrollConfig config,
}) {
  final v = markdownAutoscrollVelocity(
    localY: localY,
    clipTopLocalY: clipTopLocalY,
    clipHeight: clipHeight,
    config: config,
  );
  if (v == 0 || config.maxVelocity == 0) return 0;
  return math.sqrt(v.abs() / config.maxVelocity);
}
