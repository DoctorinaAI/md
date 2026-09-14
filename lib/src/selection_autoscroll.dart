// ignore_for_file: lines_longer_than_80_chars

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
///
/// The scroll surface itself is abstract: see [MarkdownAutoscrollTarget]. By
/// default the nearest ancestor [Scrollable] is driven, but a host with its
/// own scroll protocol (a custom anchored chat viewport, a `RenderBox` that
/// moves children itself, a nested transform) supplies [targetResolver]
/// instead. Nothing in the band / gate math touches `ScrollPosition`.
final class MarkdownSelectionAutoscrollConfig {
  /// Creates an autoscroll config.
  const MarkdownSelectionAutoscrollConfig({
    this.enabled = true,
    this.edgeZone = 48,
    this.maxVelocity = 600,
    this.topPad = 0,
    this.bottomPad = 0,
    this.useMediaQueryPadding = true,
    this.useHostUnionGate = true,
    this.targetResolver,
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
  ///
  /// Only consulted by the built-in [Scrollable] resolver — a custom
  /// [targetResolver] reports its own [MarkdownAutoscrollViewport.padding].
  final bool useMediaQueryPadding;

  /// Whether the union of mounted selectable bodies gates each direction.
  ///
  /// True (the default) suits markdown that is an *island* inside a larger
  /// scrollable: a body that fits inside the padded viewport never drives the
  /// far page chrome, and a direction hard-stops once the union is flush with
  /// that edge.
  ///
  /// Set it false when the markdown bodies **are** the scrolling content and
  /// the host only builds what is visible — a chat viewport that mounts no
  /// cache extent has a union barely larger than the viewport, so the gate
  /// would veto a drag that should keep paging through history. The scroll
  /// surface then decides on its own, through
  /// [MarkdownAutoscrollTarget.canScroll] and the delta it reports applying.
  final bool useHostUnionGate;

  /// Resolves the scroll surface a selection drag drives.
  ///
  /// Null (the default) uses the nearest ancestor [Scrollable] — the sliver
  /// protocol. Supply a resolver to drive any other scroll implementation;
  /// return null from it to leave a given drag un-scrolled.
  ///
  /// The resolver is called at most once per drag (the scope caches the
  /// target until the drag ends or the target reports no usable viewport), so
  /// it may do element-tree work without a per-frame cost.
  final MarkdownAutoscrollTargetResolver? targetResolver;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkdownSelectionAutoscrollConfig &&
          other.enabled == enabled &&
          other.edgeZone == edgeZone &&
          other.maxVelocity == maxVelocity &&
          other.topPad == topPad &&
          other.bottomPad == bottomPad &&
          other.useMediaQueryPadding == useMediaQueryPadding &&
          other.useHostUnionGate == useHostUnionGate &&
          // A resolver closure can only be compared by identity; a host that
          // builds one inline gets a new object every build, which is why the
          // scope never invalidates a cached surface mid-drag.
          identical(other.targetResolver, targetResolver);

  @override
  int get hashCode => Object.hash(
        enabled,
        edgeZone,
        maxVelocity,
        topPad,
        bottomPad,
        useMediaQueryPadding,
        useHostUnionGate,
        targetResolver,
      );

  /// A copy with the given fields replaced.
  MarkdownSelectionAutoscrollConfig copyWith({
    bool? enabled,
    double? edgeZone,
    double? maxVelocity,
    double? topPad,
    double? bottomPad,
    bool? useMediaQueryPadding,
    bool? useHostUnionGate,
    MarkdownAutoscrollTargetResolver? targetResolver,
  }) =>
      MarkdownSelectionAutoscrollConfig(
        enabled: enabled ?? this.enabled,
        edgeZone: edgeZone ?? this.edgeZone,
        maxVelocity: maxVelocity ?? this.maxVelocity,
        topPad: topPad ?? this.topPad,
        bottomPad: bottomPad ?? this.bottomPad,
        useMediaQueryPadding: useMediaQueryPadding ?? this.useMediaQueryPadding,
        useHostUnionGate: useHostUnionGate ?? this.useHostUnionGate,
        targetResolver: targetResolver ?? this.targetResolver,
      );
}

/// Signature for resolving the [MarkdownAutoscrollTarget] of a selection drag.
///
/// Return null to leave the drag un-scrolled.
typedef MarkdownAutoscrollTargetResolver = MarkdownAutoscrollTarget? Function(
  MarkdownAutoscrollRequest request,
);

/// What the scope knows about a drag when it asks for a scroll target.
@immutable
final class MarkdownAutoscrollRequest {
  /// Creates a resolver request.
  const MarkdownAutoscrollRequest({
    required this.scopeContext,
    required this.globalPosition,
    required this.config,
    this.contentContext,
  });

  /// Context of the `MarkdownSelectionScope` that owns the drag.
  ///
  /// This sits **above** any scrollable the scope wraps, so
  /// `Scrollable.maybeOf(scopeContext)` does *not* find it — use
  /// [contentContext] (or your own handle) to reach a descendant viewport.
  final BuildContext scopeContext;

  /// Context of the mounted markdown surface under [globalPosition] (or the
  /// first mounted one when the pointer is outside every surface), when the
  /// scope could resolve it. Null when no surface is mounted.
  ///
  /// This is the useful context for `Scrollable.maybeOf`: it is a *descendant*
  /// of the list that scrolls the markdown bodies.
  final BuildContext? contentContext;

  /// Current global pointer position of the drag.
  final Offset globalPosition;

  /// The config the drag runs under.
  final MarkdownSelectionAutoscrollConfig config;
}

/// Visible geometry of a scroll surface, in global coordinates.
@immutable
final class MarkdownAutoscrollViewport {
  /// Creates a viewport description.
  const MarkdownAutoscrollViewport({
    required this.globalBounds,
    this.padding = EdgeInsets.zero,
  });

  /// Global bounds of the visible scroll viewport.
  final Rect globalBounds;

  /// Inset from [globalBounds] where the activation bands start.
  ///
  /// Use it for chrome that overlaps the viewport (a translucent app bar, a
  /// composer, the system status / gesture bars) so the band begins before a
  /// handle disappears underneath.
  final EdgeInsets padding;

  /// [globalBounds] deflated by [padding] (may be empty / inverted when the
  /// padding exceeds the viewport).
  Rect get paddedGlobalBounds => Rect.fromLTRB(
        globalBounds.left + padding.left,
        globalBounds.top + padding.top,
        globalBounds.right - padding.right,
        globalBounds.bottom - padding.bottom,
      );

  /// Whether the padded band has any vertical room to work with.
  bool get isUsable =>
      !globalBounds.hasNaN &&
      globalBounds.isFinite &&
      paddedGlobalBounds.height > 0;

  @override
  String toString() =>
      'MarkdownAutoscrollViewport($globalBounds, padding: $padding)';
}

/// A scroll surface that markdown selection autoscroll can drive.
///
/// Implement it to adapt any scroll protocol — the sliver
/// [Scrollable]/[ScrollPosition] pair (see
/// [MarkdownScrollableAutoscrollTarget]), an anchored chat viewport that owns
/// its own pixel offset, a `PageView`, a transform-based canvas.
///
/// All deltas are **screen-space content movement**, never scroll-offset
/// deltas: positive moves content up so material below the bottom edge comes
/// into view. Adapters flip the sign for reverse axes / inverted anchors.
abstract interface class MarkdownAutoscrollTarget {
  /// Current visible geometry, or null when the surface cannot be driven
  /// right now (detached, unmounted, zero-sized). Read once per frame.
  MarkdownAutoscrollViewport? get viewport;

  /// Whether [applyScrollDelta] can still move content in this direction.
  ///
  /// [forward] true asks about a **positive** delta (content moves up,
  /// revealing what lies below the viewport bottom); false asks about a
  /// negative delta.
  bool canScroll({required bool forward});

  /// Moves content by [delta] logical pixels of screen-space movement.
  ///
  /// A positive [delta] moves content up (reveals what is below the bottom
  /// edge); a negative [delta] moves content down. Returns the delta actually
  /// applied — return `0` when already flush so the drag hard-stops and the
  /// direction disarms.
  double applyScrollDelta(double delta);
}

/// A [MarkdownAutoscrollTarget] assembled from closures.
///
/// The fastest way to adopt a custom scroll implementation without writing a
/// class:
///
/// ```dart
/// MarkdownSelectionAutoscrollConfig(
///   targetResolver: (request) => MarkdownCallbackAutoscrollTarget(
///     viewportOf: () {
///       final box = viewportKey.currentContext?.findRenderObject();
///       if (box is! RenderBox || !box.hasSize) return null;
///       return MarkdownAutoscrollViewport(
///         globalBounds: box.localToGlobal(Offset.zero) & box.size,
///         padding: const EdgeInsets.symmetric(vertical: 8),
///       );
///     },
///     // `scrollBy` is anchor-relative: positive reveals *older* messages,
///     // the opposite of screen-space movement.
///     onScrollDelta: (delta) {
///       chatScrollController.scrollBy(-delta);
///       return delta;
///     },
///     canScrollAt: ({required forward}) =>
///         forward ? !chatScrollController.isAtTail.value : !dataSource.reachedOldest,
///   ),
/// )
/// ```
final class MarkdownCallbackAutoscrollTarget
    implements MarkdownAutoscrollTarget {
  /// Creates a closure-backed target.
  ///
  /// [canScrollAt] defaults to "always allowed" — [onScrollDelta] returning a
  /// delta smaller than half a pixel is then what hard-stops the drag.
  const MarkdownCallbackAutoscrollTarget({
    required MarkdownAutoscrollViewport? Function() viewportOf,
    required double Function(double delta) onScrollDelta,
    bool Function({required bool forward})? canScrollAt,
  })  : _viewportOf = viewportOf,
        _onScrollDelta = onScrollDelta,
        _canScrollAt = canScrollAt;

  final MarkdownAutoscrollViewport? Function() _viewportOf;
  final double Function(double delta) _onScrollDelta;
  final bool Function({required bool forward})? _canScrollAt;

  @override
  MarkdownAutoscrollViewport? get viewport => _viewportOf();

  @override
  bool canScroll({required bool forward}) =>
      _canScrollAt?.call(forward: forward) ?? true;

  @override
  double applyScrollDelta(double delta) => _onScrollDelta(delta);
}

/// The built-in [MarkdownAutoscrollTarget] for the sliver protocol: drives the
/// [ScrollPosition] of a [ScrollableState] with `jumpTo`.
///
/// Handles reverse axes ([AxisDirection.up] / [AxisDirection.left]) so callers
/// always speak screen-space deltas.
final class MarkdownScrollableAutoscrollTarget
    implements MarkdownAutoscrollTarget {
  /// Wraps [scrollable], insetting the activation bands by [padding].
  const MarkdownScrollableAutoscrollTarget(
    this.scrollable, {
    this.padding = EdgeInsets.zero,
  });

  /// The scrollable being driven.
  final ScrollableState scrollable;

  /// Inset applied to [MarkdownAutoscrollViewport.padding].
  final EdgeInsets padding;

  /// Whether the [ScrollPosition] is ready to be read / driven.
  bool get _positionReady {
    if (!scrollable.mounted) return false;
    final position = scrollable.position;
    return position.hasPixels && position.hasContentDimensions;
  }

  /// Whether a positive screen-space delta grows `ScrollPosition.pixels`.
  bool get _axisMatchesScreen => switch (scrollable.axisDirection) {
        AxisDirection.down || AxisDirection.right => true,
        AxisDirection.up || AxisDirection.left => false,
      };

  @override
  MarkdownAutoscrollViewport? get viewport {
    if (!_positionReady) return null;
    final box = scrollable.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return MarkdownAutoscrollViewport(
      globalBounds: box.localToGlobal(Offset.zero) & box.size,
      padding: padding,
    );
  }

  @override
  bool canScroll({required bool forward}) {
    if (!_positionReady) return false;
    final position = scrollable.position;
    final towardMax = _axisMatchesScreen == forward;
    return towardMax
        ? position.pixels < position.maxScrollExtent - precisionErrorTolerance
        : position.pixels > position.minScrollExtent + precisionErrorTolerance;
  }

  @override
  double applyScrollDelta(double delta) {
    if (!_positionReady) return 0;
    final position = scrollable.position;
    final signed = _axisMatchesScreen ? delta : -delta;
    final before = position.pixels;
    final next = (before + signed).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final applied = next - before;
    if (applied.abs() < 0.5) return 0;
    position.jumpTo(next);
    return _axisMatchesScreen ? applied : -applied;
  }
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

/// Builds the built-in sliver target for [context]: the nearest [Scrollable]
/// (or [context]'s own scrollable), padded from config + MediaQuery + the
/// screen chrome that sits *outside* the viewport.
///
/// Returns null when [context] is unusable or has no enclosing [Scrollable].
MarkdownScrollableAutoscrollTarget? resolveMarkdownScrollableAutoscrollTarget({
  required BuildContext? context,
  required MarkdownSelectionAutoscrollConfig config,
}) {
  if (context == null || !context.mounted) return null;
  final scrollable = _scrollableFor(context);
  if (scrollable == null || !scrollable.mounted) return null;
  final position = scrollable.position;
  if (!position.hasPixels || !position.hasContentDimensions) return null;

  final box = scrollable.context.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;

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

  return MarkdownScrollableAutoscrollTarget(
    scrollable,
    padding: EdgeInsets.only(top: resolvedTop, bottom: resolvedBottom),
  );
}

/// Applies one autoscroll step to [target] (or, when [target] is null, to the
/// nearest ancestor [Scrollable] of [context]).
///
/// [hostUnionTopGlobalY] / [hostUnionBottomGlobalY] are the global Y bounds of
/// the union of mounted selectable bodies under the selection host. Bands use
/// the padded viewport; the host union only gates / hard-stops each direction.
MarkdownAutoscrollResult applyMarkdownSelectionAutoscroll({
  required Offset globalPosition,
  required MarkdownSelectionAutoscrollConfig config,
  required Duration? lastTimestamp,
  required void Function(Duration?) storeTimestamp,
  required double hostUnionTopGlobalY,
  required double hostUnionBottomGlobalY,
  BuildContext? context,
  MarkdownAutoscrollTarget? target,
  MarkdownAutoscrollSession? session,
}) {
  void clear() => storeTimestamp(null);

  if (!config.enabled || config.maxVelocity <= 0) {
    // A zero max velocity can never move content; without this the
    // past-the-outer-band branch below would hand back `scrolled` forever and
    // keep the caller's frame ticker spinning on a drag that never scrolls.
    clear();
    return MarkdownAutoscrollResult.idle;
  }

  final resolved = target ??
      resolveMarkdownScrollableAutoscrollTarget(
        context: context,
        config: config,
      );
  if (resolved == null) {
    clear();
    return MarkdownAutoscrollResult.idle;
  }

  final viewport = resolved.viewport;
  if (viewport == null || !viewport.isUsable) {
    session?.reset();
    clear();
    return MarkdownAutoscrollResult.idle;
  }

  final bounds = viewport.globalBounds;
  final padded = viewport.paddedGlobalBounds;
  final paddedTop = padded.top;
  final paddedBottom = padded.bottom;
  final clipHeight = padded.height;
  final localY = globalPosition.dy - bounds.top;
  final clipTopLocal = paddedTop - bounds.top;

  // Host still has content to reveal past each pad edge (or sits entirely
  // off-screen past that edge — drag must be able to pull it back). Hosts whose
  // bodies *are* the scrolling content opt out and let the target decide.
  final canTowardStart = !config.useHostUnionGate ||
      hostUnionTopGlobalY < paddedTop - 0.5 ||
      hostUnionBottomGlobalY <= paddedTop + 0.5;
  final canTowardEnd = !config.useHostUnionGate ||
      hostUnionBottomGlobalY > paddedBottom + 0.5 ||
      hostUnionTopGlobalY >= paddedBottom - 0.5;

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

  if (!resolved.canScroll(forward: !towardStart)) {
    session?.disarm(towardStart: towardStart);
    clear();
    return MarkdownAutoscrollResult.suppressed;
  }

  final applied = resolved.applyScrollDelta(delta);
  if (applied.abs() < 0.5) {
    session?.disarm(towardStart: towardStart);
    clear();
    return MarkdownAutoscrollResult.suppressed;
  }

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
