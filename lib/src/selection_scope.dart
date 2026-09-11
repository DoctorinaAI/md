import 'dart:math' as math;

import 'package:flutter/cupertino.dart'
    show
        cupertinoTextSelectionHandleControls,
        cupertinoDesktopTextSelectionHandleControls;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'selection.dart';
import 'selection_autoscroll.dart';

/// Signature for building the selection context menu (toolbar), mirroring
/// `SelectableRegion.contextMenuBuilder`.
///
/// Read [MarkdownSelectionScopeState.contextMenuButtonItems] /
/// [MarkdownSelectionScopeState.contextMenuAnchors] to build an adaptive menu,
/// or call [MarkdownSelectionScopeState.copySelection] / `selectAll` /
/// `clearSelection` from a fully custom menu.
typedef MarkdownSelectionContextMenuBuilder = Widget Function(
  BuildContext context,
  MarkdownSelectionScopeState state,
);

class _ScopeMarker extends InheritedWidget {
  const _ScopeMarker({
    required this.controller,
    required this.state,
    required super.child,
  });

  final MarkdownSelectionController controller;
  final MarkdownSelectionScopeState state;

  @override
  bool updateShouldNotify(_ScopeMarker old) =>
      !identical(controller, old.controller) || !identical(state, old.state);
}

/// Owns Markdown selection gestures, keyboard shortcuts and the selection
/// toolbar for its subtree, and exposes the ambient
/// [MarkdownSelectionController] to descendant `MarkdownWidget`s.
///
/// Modeled on `SelectionArea`/`SelectableRegion`:
///
/// * A mouse/trackpad/stylus drag selects; on touch a long-press-then-drag
///   selects (so a plain swipe still scrolls an enclosing list).
/// * Keyboard shortcuts work when the scope is focused — `Ctrl/Cmd+C` copies,
///   `Ctrl/Cmd+A` selects all, `Shift`+arrows extend the selection (by
///   character, word, line or document per the platform bindings), and `Esc`
///   clears it. The key bindings come from the ambient
///   `DefaultTextEditingShortcuts` (installed by `WidgetsApp`/`MaterialApp`).
/// * Right-click (desktop) or long-press (mobile) shows an adaptive context
///   toolbar; customize it with [contextMenuBuilder].
///
/// Everything is customizable in the same spirit as `SelectableText`:
/// [selectionColor], [contextMenuBuilder], [magnifierConfiguration],
/// [selectionControls], [focusNode] and [onSelectionChanged].
class MarkdownSelectionScope extends StatefulWidget {
  /// Creates a selection scope backed by [controller].
  const MarkdownSelectionScope({
    required this.controller,
    required this.child,
    this.focusNode,
    this.enabled = true,
    this.selectionColor,
    this.contextMenuBuilder = defaultContextMenuBuilder,
    this.magnifierConfiguration,
    this.selectionControls,
    this.onSelectionChanged,
    this.autoscroll = const MarkdownSelectionAutoscrollConfig(),
    super.key,
  });

  /// The controller that owns the selection for this subtree.
  final MarkdownSelectionController controller;

  /// The subtree in which selection gestures apply.
  final Widget child;

  /// An optional external focus node. When null the scope manages its own.
  final FocusNode? focusNode;

  /// Whether selection gestures, handles and shortcuts are active. When false
  /// the scope is inert (but still exposes the controller to descendants).
  final bool enabled;

  /// The selection highlight color. Defaults to the ambient
  /// `DefaultSelectionStyle`/`TextSelectionTheme` color.
  final Color? selectionColor;

  /// Builds the context menu (toolbar). Defaults to an adaptive Copy /
  /// Select-all toolbar; pass null to disable the toolbar entirely.
  final MarkdownSelectionContextMenuBuilder? contextMenuBuilder;

  /// Magnifier configuration for touch selection/handle drags. Defaults to the
  /// platform-adaptive magnifier.
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// Controls used to paint the selection handles. Defaults per platform.
  final TextSelectionControls? selectionControls;

  /// Called whenever the selection changes.
  final ValueChanged<MarkdownSelection?>? onSelectionChanged;

  /// Edge-zone autoscroll while dragging a non-collapsed selection near an
  /// ancestor scrollable's edge.
  final MarkdownSelectionAutoscrollConfig autoscroll;

  /// The default [contextMenuBuilder]: an [AdaptiveTextSelectionToolbar] built
  /// from the scope's [MarkdownSelectionScopeState.contextMenuButtonItems].
  static Widget defaultContextMenuBuilder(
    BuildContext context,
    MarkdownSelectionScopeState state,
  ) =>
      AdaptiveTextSelectionToolbar.buttonItems(
        buttonItems: state.contextMenuButtonItems,
        anchors: state.contextMenuAnchors,
      );

  /// The nearest ambient controller, or null if there is no enclosing scope.
  static MarkdownSelectionController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ScopeMarker>()?.controller;

  /// The nearest ambient controller. Throws if there is no enclosing scope.
  static MarkdownSelectionController of(BuildContext context) =>
      maybeOf(context)!;

  /// The nearest ambient scope state, or null when there is no enclosing scope.
  static MarkdownSelectionScopeState? stateOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ScopeMarker>()?.state;

  @override
  State<MarkdownSelectionScope> createState() => MarkdownSelectionScopeState();
}

/// State for [MarkdownSelectionScope]. Public so a custom [contextMenuBuilder]
/// can drive it (copy/select-all/clear + toolbar geometry), mirroring
/// `SelectableRegionState`.
class MarkdownSelectionScopeState extends State<MarkdownSelectionScope>
    with TickerProviderStateMixin {
  final ContextMenuController _contextMenuController = ContextMenuController();
  final LayerLink _startHandleLink = LayerLink();
  final LayerLink _endHandleLink = LayerLink();
  final LayerLink _toolbarLink = LayerLink();
  SelectionOverlay? _selectionOverlay;
  FocusNode? _internalFocusNode;
  Offset? _lastSecondaryTapDown;

  /// Prior secondary-tap anchor used for macOS same-spot toolbar toggle.
  Offset? _previousSecondaryTapAnchor;
  MarkdownSelection? _lastSelection;

  // Multi-tap / granular selection state. [_granularity] is 1 = character,
  // 2 = word, 3 = block; [_granularAnchor] is the ordered word/block range a
  // word/block-granular drag grows from.
  int _granularity = 1;
  MarkdownSelection? _granularAnchor;

  /// Last pointer position while a selection drag is active (for edge
  /// autoscroll frame ticks).
  Offset? _dragGlobal;
  bool _dragMovesStartEdge = false;
  bool _dragIsHandle = false;
  Duration? _lastAutoscrollTimestamp;
  Ticker? _autoscrollTicker;
  final MarkdownAutoscrollSession _autoscrollSession =
      MarkdownAutoscrollSession();

  /// When true, skip creating/showing handles (Android long-press: show on end).
  bool _deferHandleShow = false;

  /// Coalesces post-frame toolbar rebuilds.
  bool _toolbarBuildScheduled = false;

  /// Coalesces post-frame geometry restores (scroll can notify before layout).
  bool _toolbarGeometryRefreshScheduled = false;

  /// Coalesces post-frame handle-overlay syncs deferred off layout/build.
  bool _overlaySyncScheduled = false;

  /// Ancestor observer (e.g. [Scaffold]) so the toolbar follows parent scrolls
  /// when this scope is a scrollable *child*, not an ancestor.
  ScrollNotificationObserverState? _scrollNotificationObserver;

  PointerDeviceKind? _lastPointerDeviceKind;

  FocusNode get _focusNode =>
      widget.focusNode ??
      (_internalFocusNode ??= FocusNode(debugLabel: 'MarkdownSelectionScope'));

  /// The controller this scope drives.
  MarkdownSelectionController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _lastSelection = widget.controller.selection;
    widget.controller.addListener(_onControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
    // Scope may remount after list virtualization while [toolbarWanted] is
    // still set on the controller — restore chrome once layout exists.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshToolbarForVisibleGeometry();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applySelectionColor();
    _scrollNotificationObserver?.removeListener(_onAncestorScrollNotification);
    _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollNotificationObserver?.addListener(_onAncestorScrollNotification);
  }

  @override
  void didUpdateWidget(covariant MarkdownSelectionScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.focusNode, widget.focusNode)) {
      (oldWidget.focusNode ?? _internalFocusNode)
          ?.removeListener(_handleFocusChanged);
      _focusNode.addListener(_handleFocusChanged);
    }
    if (!identical(oldWidget.controller, widget.controller)) {
      _clearHandles(); // drop leaders/overlay bound to the old controller
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _lastSelection = widget.controller.selection;
      _applySelectionColor();
      _syncOverlay();
    }
    if (oldWidget.selectionColor != widget.selectionColor) {
      _applySelectionColor();
    }
  }

  @override
  void dispose() {
    _stopAutoscroll();
    _scrollNotificationObserver?.removeListener(_onAncestorScrollNotification);
    _scrollNotificationObserver = null;
    _focusNode.removeListener(_handleFocusChanged);
    widget.controller.removeListener(_onControllerChanged);
    _contextMenuController.remove();
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) return;
    // Keep the range while a pointer drag is active — list rebuilds during
    // autoscroll can steal focus without an intentional dismiss.
    if (_dragGlobal != null) return;
    // Retain selection when the app is inactive/backgrounded (e.g. desktop
    // window switch); clear only when focus is lost while resumed (or before
    // the binding has reported a lifecycle — typical in widget tests).
    final lifecycle = SchedulerBinding.instance.lifecycleState;
    if (lifecycle case null || AppLifecycleState.resumed) {
      clearSelection();
    }
  }

  void _applySelectionColor() {
    controller.selectionColor = widget.selectionColor ??
        DefaultSelectionStyle.of(context).selectionColor;
  }

  void _onControllerChanged() {
    final sel = controller.selection;
    if (sel != _lastSelection) {
      _lastSelection = sel;
      widget.onSelectionChanged?.call(sel);
      // Selection moved — drop a frozen right-click anchor so the toolbar
      // tracks the live selection bounds instead.
      if (_contextMenuController.isShown) {
        _lastSecondaryTapDown = null;
      }
    }

    if (sel case final current? when !current.isCollapsed) {
      if (_dragGlobal == null) {
        // Outside a drag: restore when [toolbarWanted] (scroll remount /
        // programmatic selectAll / selection=), else start chrome for keyboard
        // / other _commitSelection ranges.
        if (controller.toolbarWanted) {
          _refreshToolbarForVisibleGeometry();
        } else {
          showToolbar();
        }
      }
    } else {
      hideToolbar();
    }
    // Mid-drag: keep the menu hidden until drag-end [showToolbar].
    _syncOverlay();
  }

  // --- native handles + magnifier ------------------------------------------

  bool get _handlesEnabled =>
      widget.enabled &&
      switch (Theme.of(context).platform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia =>
          true,
        _ => false,
      };

  TextSelectionControls get _effectiveControls =>
      widget.selectionControls ??
      switch (Theme.of(context).platform) {
        TargetPlatform.android ||
        TargetPlatform.fuchsia =>
          materialTextSelectionHandleControls,
        TargetPlatform.linux ||
        TargetPlatform.windows =>
          desktopTextSelectionHandleControls,
        TargetPlatform.iOS => cupertinoTextSelectionHandleControls,
        TargetPlatform.macOS => cupertinoDesktopTextSelectionHandleControls,
      };

  TextMagnifierConfiguration get _effectiveMagnifier =>
      widget.magnifierConfiguration ??
      TextMagnifier.adaptiveMagnifierConfiguration;

  /// Syncs the handle overlay. During an in-flight drag, updates run
  /// pointer-synchronously when geometry walks are safe so highlight/handles
  /// track the finger; always defers during build/layout/paint (including
  /// drag) because [selectionHandleEndpoints] uses [localToGlobal].
  void _syncOverlay() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final inUnsafePhase = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;

    if (_dragGlobal != null && !inUnsafePhase) {
      _updateHandlesAndOverlay();
      return;
    }

    if (inUnsafePhase) {
      if (_overlaySyncScheduled) return;
      _overlaySyncScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _overlaySyncScheduled = false;
        if (!mounted) return;
        _updateHandlesAndOverlay();
      });
      return;
    }

    _updateHandlesAndOverlay();
  }

  void _toggleToolbar() => toolbarIsVisible ? hideToolbar() : showToolbar();

  void _updateHandlesAndOverlay() {
    if (!_handlesEnabled) {
      _clearHandles();
      return;
    }
    final endpoints = controller.selectionHandleEndpoints();
    if (endpoints == null) {
      _clearHandles();
      return;
    }
    _applyHandles(endpoints);
    if (context.findRenderObject() case final RenderBox box when box.hasSize) {
      final startPoint = TextSelectionPoint(
        box.globalToLocal(
            Offset(endpoints.startGlobal.left, endpoints.startGlobal.bottom)),
        TextDirection.ltr,
      );
      final endPoint = TextSelectionPoint(
        box.globalToLocal(
            Offset(endpoints.endGlobal.right, endpoints.endGlobal.bottom)),
        TextDirection.ltr,
      );
      final reversed = controller.isSelectionReversed;
      final startType = reversed
          ? TextSelectionHandleType.right
          : TextSelectionHandleType.left;
      final endType = reversed
          ? TextSelectionHandleType.left
          : TextSelectionHandleType.right;
      switch (_selectionOverlay) {
        case null:
          if (Overlay.maybeOf(context) == null) {
            return; // no host for handles
          }
          final overlay = _selectionOverlay = SelectionOverlay(
            context: context,
            startHandleType: startType,
            lineHeightAtStart: endpoints.startLocal.height,
            onStartHandleDragStart: (d) => _onHandleDragStart(d, isStart: true),
            onStartHandleDragUpdate: (d) =>
                _onHandleDragUpdate(d, isStart: true),
            onStartHandleDragEnd: (_) => _onHandleDragEnd(),
            endHandleType: endType,
            lineHeightAtEnd: endpoints.endLocal.height,
            onEndHandleDragStart: (d) => _onHandleDragStart(d, isStart: false),
            onEndHandleDragUpdate: (d) =>
                _onHandleDragUpdate(d, isStart: false),
            onEndHandleDragEnd: (_) => _onHandleDragEnd(),
            selectionEndpoints: <TextSelectionPoint>[startPoint, endPoint],
            selectionControls: _effectiveControls,
            selectionDelegate: null,
            clipboardStatus: null,
            startHandleLayerLink: _startHandleLink,
            endHandleLayerLink: _endHandleLink,
            toolbarLayerLink: _toolbarLink,
            magnifierConfiguration: _effectiveMagnifier,
          );
          // Android long-press: keep overlay for magnifier, show handles on 
          // end.
          if (!_deferHandleShow) {
            overlay.showHandles();
          }
        case final overlay:
          overlay
            ..startHandleType = startType
            ..lineHeightAtStart = endpoints.startLocal.height
            ..endHandleType = endType
            ..lineHeightAtEnd = endpoints.endLocal.height
            ..selectionEndpoints = <TextSelectionPoint>[startPoint, endPoint];
          if (!_deferHandleShow) {
            overlay.showHandles();
          }
      }
    }
  }

  /// Assigns the two handle leader layers to their owning surfaces (and clears
  /// them everywhere else) in a single pass, so nothing repaints needlessly.
  void _applyHandles(MarkdownHandleEndpoints? e) {
    final startSurface = e?.startSurface;
    final endSurface = e?.endSurface;
    final startLocal = switch (e) {
      null => null,
      final endpoints => Offset(
          endpoints.startLocal.left,
          endpoints.startLocal.bottom,
        ),
    };
    final endLocal = switch (e) {
      null => null,
      final endpoints => Offset(
          endpoints.endLocal.right,
          endpoints.endLocal.bottom,
        ),
    };
    for (final surface in controller.mountedSurfaces) {
      final isStart = identical(surface, startSurface);
      final isEnd = identical(surface, endSurface);
      surface.setSelectionHandleLayers(
        startLink: isStart ? _startHandleLink : null,
        startLocal: isStart ? startLocal : null,
        endLink: isEnd ? _endHandleLink : null,
        endLocal: isEnd ? endLocal : null,
      );
    }
  }

  void _clearHandles() {
    _applyHandles(null);
    _selectionOverlay?.hide();
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
  }

  void _onHandleDragStart(DragStartDetails d, {required bool isStart}) {
    _dragIsHandle = true;
    _dragMovesStartEdge = isStart;
    _dragGlobal = d.globalPosition;
    _autoscrollSession.reset();
    hideToolbar();
    _selectionOverlay
        ?.showMagnifier(_magnifierInfo(d.globalPosition, isStart: isStart));
    _driveAutoscroll();
  }

  void _onHandleDragUpdate(DragUpdateDetails d, {required bool isStart}) {
    _dragIsHandle = true;
    _dragMovesStartEdge = isStart;
    _dragGlobal = d.globalPosition;
    final e = controller.selectionHandleEndpoints();
    final lineHeight = switch (e) {
      null => 0.0,
      final endpoints =>
        isStart ? endpoints.startLocal.height : endpoints.endLocal.height,
    };
    controller.moveSelectionEdgeToGlobal(
      d.globalPosition - Offset(0, lineHeight / 2),
      isStart: isStart,
    );
    _selectionOverlay
        ?.updateMagnifier(_magnifierInfo(d.globalPosition, isStart: isStart));
    _driveAutoscroll();
  }

  void _onHandleDragEnd() {
    _stopAutoscroll();
    _selectionOverlay?.hideMagnifier();
    if (controller.selection case final sel? when !sel.isCollapsed) {
      showToolbar();
    }
  }

  void _onBodyDragEnd() {
    _stopAutoscroll();
    if (controller.selection case final sel? when !sel.isCollapsed) {
      showToolbar();
    }
  }

  MagnifierInfo _magnifierInfo(Offset gesture, {required bool isStart}) {
    final e = controller.selectionHandleEndpoints();
    final caret = switch (e) {
      null => Rect.fromCenter(center: gesture, width: 0, height: 24),
      final endpoints => isStart ? endpoints.startGlobal : endpoints.endGlobal,
    };
    final bounds = switch (e) {
      null => caret,
      final endpoints => isStart
          ? endpoints.startSurface.globalBounds
          : endpoints.endSurface.globalBounds,
    };
    return MagnifierInfo(
      globalGesturePosition: gesture,
      caretRect: caret,
      fieldBounds: bounds,
      currentLineBoundaries: bounds,
    );
  }

  // --- edge autoscroll -----------------------------------------------------

  void _ensureAutoscrollTicker() {
    if (_autoscrollTicker != null) return;
    _autoscrollTicker = createTicker((_) {
      if (!mounted || _dragGlobal == null) {
        _pauseAutoscrollTicker();
        return;
      }
      _tickAutoscroll();
    })
      ..start();
  }

  /// Disposes the frame ticker but keeps the drag pointer so a later update
  /// can restart scrolling after leave-band / re-enter.
  void _pauseAutoscrollTicker() {
    _autoscrollTicker?.dispose();
    _autoscrollTicker = null;
    _lastAutoscrollTimestamp = null;
  }

  void _stopAutoscroll() {
    _pauseAutoscrollTicker();
    _autoscrollSession.reset();
    _dragGlobal = null;
    _dragIsHandle = false;
  }

  /// Global Y span of every mounted selectable body (host union).
  (double, double)? _hostUnionGlobalY() {
    final surfaces = controller.mountedSurfaces;
    if (surfaces.isEmpty) return null;
    var top = double.infinity;
    var bottom = double.negativeInfinity;
    for (final surface in surfaces) {
      final bounds = surface.globalBounds;
      if (bounds.top < top) top = bounds.top;
      if (bounds.bottom > bottom) bottom = bounds.bottom;
    }
    if (!top.isFinite || !bottom.isFinite || bottom < top) return null;
    return (top, bottom);
  }

  void _tickAutoscroll() {
    final global = _dragGlobal;
    final sel = controller.selection;
    if (global case final position?) {
      if (sel case final current? when !current.isCollapsed) {
        if (!widget.autoscroll.enabled) {
          _pauseAutoscrollTicker();
          return;
        }

        final union = _hostUnionGlobalY();
        if (union == null) {
          _pauseAutoscrollTicker();
          return;
        }

        // Prefer a BuildContext under a mounted surface so Scrollable.maybeOf
        // walks up to the enclosing ListView (scope context is an ancestor of
        // the scrollable, not a descendant).
        MarkdownSelectionSurface? content;
        for (final surface in controller.mountedSurfaces) {
          if (surface.globalBounds.contains(position)) {
            content = surface;
            break;
          }
        }
        content ??= switch (controller.mountedSurfaces) {
          final surfaces when surfaces.isEmpty => null,
          final surfaces => surfaces.first,
        };
        final scrollContext = switch (content) {
              final surface? => _contextForSurface(surface),
              null => null,
            } ??
            _scrollableContextNear(position) ??
            context;

        final result = applyMarkdownSelectionAutoscroll(
          globalPosition: position,
          context: scrollContext,
          config: widget.autoscroll,
          lastTimestamp: _lastAutoscrollTimestamp,
          storeTimestamp: (t) => _lastAutoscrollTimestamp = t,
          hostUnionTopGlobalY: union.$1,
          hostUnionBottomGlobalY: union.$2,
          session: _autoscrollSession,
        );

        if (result != MarkdownAutoscrollResult.scrolled) {
          // Leave-band / hard-stop / gate: stop the forever ticker. The next
          // pointer update restarts only if apply returns scrolled again —
          // avoids START→PAUSE thrash on every out-of-band move.
          _pauseAutoscrollTicker();
          return;
        }

        // Keep the frame ticker alive while the finger stays in-band.
        _ensureAutoscrollTicker();

        // After the scroll jump, re-hit-test so selection grows with content.
        if (_dragIsHandle) {
          final e = controller.selectionHandleEndpoints();
          final lineHeight = switch (e) {
            null => 0.0,
            final endpoints => _dragMovesStartEdge
                ? endpoints.startLocal.height
                : endpoints.endLocal.height,
          };
          controller.moveSelectionEdgeToGlobal(
            position - Offset(0, lineHeight / 2),
            isStart: _dragMovesStartEdge,
          );
        } else {
          _extendSelectionAt(position);
        }
        return;
      }
    }
    _pauseAutoscrollTicker();
  }

  /// Pointer-driven autoscroll step: only starts the ticker when scrolling.
  void _driveAutoscroll() {
    _tickAutoscroll();
  }

  /// Element whose [RenderObject] is [surface], if mounted under this scope.
  BuildContext? _contextForSurface(MarkdownSelectionSurface surface) {
    Element? found;
    void visit(Element element) {
      if (found case final _?) return;
      if (identical(element.renderObject, surface)) {
        found = element;
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  /// Nearest descendant [Scrollable] under [global] (the scrollable element
  /// itself is fine — [applyMarkdownSelectionAutoscroll] resolves it).
  BuildContext? _scrollableContextNear(Offset global) {
    BuildContext? best;
    var bestDistance = double.infinity;
    void visit(Element element) {
      if (element.widget case Scrollable()) {
        if (element.renderObject case final RenderBox box when box.hasSize) {
          final origin = box.localToGlobal(Offset.zero);
          final bounds = origin & box.size;
          final dy = switch (global.dy) {
            final y when y < bounds.top => bounds.top - y,
            final y when y > bounds.bottom => y - bounds.bottom,
            _ => 0.0,
          };
          if (dy < bestDistance) {
            bestDistance = dy;
            best = element;
          }
        }
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return best;
  }

  // --- public selection ops ------------------------------------------------

  /// Copies the current selection to the clipboard and hides the toolbar.
  Future<void> copySelection() async {
    final text = controller.getText();
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
    }
    hideToolbar();
  }

  /// Selects everything across the registered documents.
  void selectAll() {
    _focusNode.requestFocus();
    controller.selectAll();
  }

  /// Clears the selection and hides the toolbar.
  void clearSelection() {
    controller.clear();
    hideToolbar();
  }

  // --- context menu --------------------------------------------------------

  /// The default toolbar buttons for the current selection: Copy (when
  /// something is selected) and Select-all (when there is any content).
  List<ContextMenuButtonItem> get contextMenuButtonItems {
    final items = <ContextMenuButtonItem>[];
    if (controller.selection case final sel? when !sel.isCollapsed) {
      items.add(ContextMenuButtonItem(
        type: ContextMenuButtonType.copy,
        onPressed: copySelection,
      ));
    }
    if (controller.hasDocuments) {
      items.add(ContextMenuButtonItem(
        type: ContextMenuButtonType.selectAll,
        onPressed: () {
          selectAll();
          showToolbar();
        },
      ));
    }
    return items;
  }

  /// Where to anchor the toolbar: the last right-click point, else the
  /// selection clipped to this scope's visible bounds.
  ///
  /// Mirrors [TextSelectionToolbarAnchors.fromSelection]: absolute selection
  /// rects that have scrolled outside the host must not pin the menu to the
  /// host's top/bottom edges (that sinks the toolbar to the screen bottom).
  ///
  /// When the visible selection fills most of the clip (mid-viewport view of a
  /// very large range, both edges off-screen), anchors stay near the **top** of
  /// that visible region so the menu's below-fallback cannot land on the
  /// host bottom. When only the bottom endpoint is in view, prefer **below**
  /// that caret; otherwise use stock top/bottom selection anchors.
  TextSelectionToolbarAnchors get contextMenuAnchors {
    if (_lastSecondaryTapDown case final secondary?) {
      return TextSelectionToolbarAnchors(primaryAnchor: secondary);
    }
    if (_toolbarClipBounds() case final clip?) {
      if (_visibleSelectionBoundsIn(clip) case final visible?) {
        return _anchorsForVisibleSelection(visible, clip);
      }
    }
    // No painted selection in view — neutral anchor; scroll/size handlers hide
    // the menu when geometry leaves the host.
    final host = _hostGlobalBounds();
    return TextSelectionToolbarAnchors(
      primaryAnchor: host.isEmpty ? Offset.zero : host.center,
    );
  }

  /// Resolves toolbar anchors for the painted selection inside [clip].
  ///
  /// - Neither endpoint in clip → top-pin (tall mid-viewport range).
  /// - Bottom endpoint only → prefer below that caret.
  /// - Top endpoint only, or both in clip → stock above/below anchors
  ///   (Material/Cupertino prefer above when it fits).
  ///
  /// Uses mounted, non-proxied carets — handle proxies must not disable
  /// top-pin or steal edge-stick.
  TextSelectionToolbarAnchors _anchorsForVisibleSelection(
    Rect visible,
    Rect clip,
  ) {
    final baseRect = controller.selectionEndpointGlobalRect(base: true);
    final extentRect = controller.selectionEndpointGlobalRect(base: false);
    final hit = clip.inflate(0.5);
    final baseIn = switch (baseRect) {
      final rect? => hit.overlaps(rect),
      null => false,
    };
    final extentIn = switch (extentRect) {
      final rect? => hit.overlaps(rect),
      null => false,
    };

    return switch ((baseIn, extentIn, baseRect, extentRect)) {
      (false, false, _, _) => _topPinnedAnchors(visible),
      (false, true, _, final edge?) => _anchorsPreferringBelow(
          above: edge.topCenter,
          below: edge.bottomCenter,
        ),
      (true, false, final edge?, _) => _stockSelectionAnchors(edge),
      _ => _stockSelectionAnchors(visible),
    };
  }

  /// Stock [TextSelectionToolbarAnchors.fromSelection]-style top/bottom pair.
  static TextSelectionToolbarAnchors _stockSelectionAnchors(Rect rect) =>
      TextSelectionToolbarAnchors(
        primaryAnchor: rect.topCenter,
        secondaryAnchor: rect.bottomCenter,
      );

  /// Mid-viewport tall selection: keep both anchors near the visible top so a
  /// below-fallback cannot sink to the host bottom.
  static TextSelectionToolbarAnchors _topPinnedAnchors(Rect visible) {
    final primary = visible.topCenter;
    return TextSelectionToolbarAnchors(
      primaryAnchor: primary,
      secondaryAnchor: Offset(
        primary.dx,
        math.min(primary.dy + _kTallSelectionSecondaryOffset, visible.bottom),
      ),
    );
  }

  /// Prefers placing the menu **below** [below] when there is room.
  ///
  /// Material/Cupertino map `primaryAnchor` → `anchorAbove` and prefer above
  /// whenever it fits. Touch platforms force `fitsAbove` false by parking
  /// primary near the screen top; desktop toolbars use only `primaryAnchor`,
  /// so primary is the below point there.
  TextSelectionToolbarAnchors _anchorsPreferringBelow({
    required Offset above,
    required Offset below,
  }) {
    final mqSize = MediaQuery.maybeSizeOf(context);
    final mqPadding = MediaQuery.maybePaddingOf(context);
    final size = mqSize ?? Size.zero;
    final padding = mqPadding ?? EdgeInsets.zero;
    const toolbarHeight = 48.0;
    const aboveGap = 8.0;
    const belowGap = TextSelectionToolbar.kToolbarContentDistanceBelow;

    final spaceBelow = size.height - padding.bottom - below.dy - belowGap;
    final spaceAbove = above.dy - padding.top - aboveGap;
    if (spaceBelow < toolbarHeight && spaceBelow < spaceAbove) {
      return TextSelectionToolbarAnchors(
        primaryAnchor: above,
        secondaryAnchor: below,
      );
    }

    final isTouch = switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia =>
        true,
      _ => false,
    };
    if (!isTouch) {
      return TextSelectionToolbarAnchors(
        primaryAnchor: below,
        secondaryAnchor: below,
      );
    }

    return TextSelectionToolbarAnchors(
      primaryAnchor: Offset(below.dx, padding.top + aboveGap),
      secondaryAnchor: below,
    );
  }

  /// How far below the visible top to place the secondary anchor when
  /// top-pinning, so a below-fallback stays near the top instead of the
  /// clip bottom.
  static const double _kTallSelectionSecondaryOffset = 48;

  /// Global bounds of this scope's render box, or [Rect.zero] if unavailable.
  Rect _hostGlobalBounds() {
    return switch (context.findRenderObject()) {
      final RenderBox box when box.hasSize =>
        box.localToGlobal(Offset.zero) & box.size,
      _ => Rect.zero,
    };
  }

  /// Host bounds intersected with any enclosing [RenderAbstractViewport].
  ///
  /// When the scope **wraps** the scrollable, the host itself is the clip.
  /// When the scope is a **child** of a list, the host may scroll off-screen
  /// while still reporting a non-empty size — the viewport intersection goes
  /// empty so the toolbar can dismiss.
  Rect? _toolbarClipBounds() {
    final host = _hostGlobalBounds();
    if (host.isEmpty) return null;
    var clip = host;
    if (context.findRenderObject() case final box?) {
      if (RenderAbstractViewport.maybeOf(box) case final RenderBox viewportBox
          when viewportBox.hasSize) {
        final viewportRect =
            viewportBox.localToGlobal(Offset.zero) & viewportBox.size;
        clip = clip.intersect(viewportRect);
      }
    }
    if (clip.isEmpty) return null;
    return clip;
  }

  /// Union of painted selection rects intersected with the toolbar clip.
  ///
  /// Null when the selection is collapsed, unmounted, or entirely outside the
  /// visible host / enclosing viewport (scrolled away / virtualized).
  Rect? _visibleSelectionBounds() => switch (_toolbarClipBounds()) {
        final clip? => _visibleSelectionBoundsIn(clip),
        null => null,
      };

  Rect? _visibleSelectionBoundsIn(Rect clip) {
    final rects = controller.globalSelectionRects();
    if (rects.isEmpty) return null;
    final bounds = rects.reduce((a, b) => a.expandToInclude(b));
    final visible = bounds.intersect(clip);
    if (visible.isEmpty) return null;
    return visible;
  }

  /// Whether the toolbar is currently visible.
  bool get toolbarIsVisible => _contextMenuController.isShown;

  /// Shows the context toolbar. [location] anchors it at a point (e.g. the
  /// right-click position); otherwise it anchors to the selection.
  ///
  /// Remembers that the menu should stay available across scroll and scope
  /// remounts ([MarkdownSelectionController.toolbarWanted]): if the selection
  /// is currently off-screen the overlay is deferred until geometry returns.
  void showToolbar([Offset? location]) {
    if (widget.contextMenuBuilder case final builder?) {
      if (Overlay.maybeOf(context, rootOverlay: true) == null) return;
      controller.toolbarWanted = true;
      _lastSecondaryTapDown = location;
      if (location == null) {
        if (_visibleSelectionBounds() case null) {
          _contextMenuController.remove();
          return;
        }
      }
      _contextMenuController.remove();
      _contextMenuController.show(
        context: context,
        contextMenuBuilder: (context) => builder(context, this),
      );
    }
  }

  /// Hides the context toolbar and clears the scroll-restore intent.
  void hideToolbar() {
    controller.toolbarWanted = false;
    _lastSecondaryTapDown = null;
    _contextMenuController.remove();
  }

  // --- gestures ------------------------------------------------------------

  /// SelectableRegion-style consecutive-tap capping.
  int _effectiveConsecutiveTapCount(int rawCount) {
    var maxConsecutiveTap = 3;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        if (_lastPointerDeviceKind case final kind?
            when kind != PointerDeviceKind.mouse) {
          maxConsecutiveTap = 2;
        }
        return _cycleTapCount(rawCount, maxConsecutiveTap);
      case TargetPlatform.linux:
        return _cycleTapCount(rawCount, maxConsecutiveTap);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return math.min(rawCount, maxConsecutiveTap);
    }
  }

  static int _cycleTapCount(int rawCount, int maxConsecutiveTap) =>
      switch (rawCount) {
        final n when n <= maxConsecutiveTap => n,
        final n when n % maxConsecutiveTap == 0 => maxConsecutiveTap,
        final n => n % maxConsecutiveTap,
      };

  bool _positionIsOnActiveSelection(Offset global) {
    if (controller.selection case final sel? when !sel.isCollapsed) {
      for (final rect in controller.globalSelectionRects()) {
        if (rect.contains(global)) return true;
      }
    }
    return false;
  }

  /// Forces handles + toolbar to refresh even when the range is unchanged
  /// (double-tap re-select must not be a no-op).
  void _refreshSelectionChrome({Offset? toolbarAt}) {
    _syncOverlay();
    _updateHandlesAndOverlay();
    if (controller.selection case final sel? when !sel.isCollapsed) {
      showToolbar(toolbarAt);
    }
  }

  /// Anchors a fresh selection at [global] with the given consecutive
  /// [tapCount]: 1 collapses a caret (character granularity), 2 selects the
  /// word, 3+ selects the whole block. Stores the granular anchor for a drag.
  ///
  /// Returns false when [global] misses every mounted selectable surface
  /// (strict containment — no nearest-neighbor clamp), so callers skip
  /// haptic / drag arming / chrome.
  bool _beginSelection(Offset global, int tapCount) {
    if (!controller.hitsSelectableContent(global)) {
      return false;
    }
    final effective = _effectiveConsecutiveTapCount(tapCount);
    _granularity = switch (effective) {
      <= 1 => 1,
      2 => 2,
      _ => 3,
    };
    switch (_granularity) {
      case 2:
        _granularAnchor = controller.selectWordAtGlobal(global);
      case 3:
        _granularAnchor = controller.selectBlockAtGlobal(global);
      default:
        controller.startAtGlobal(global);
        _granularAnchor = null;
    }
    return true;
  }

  /// Extends the active selection to [global] at the current granularity.
  void _updateSelection(Offset global) {
    final before = controller.selection;
    _dragGlobal = global;
    _extendSelectionAt(global);
    _maybeBodySelectionDragHaptic(before);
    _driveAutoscroll();
  }

  /// Android selection-click ticks while expanding via body / long-press drag.
  ///
  /// Handle drags already tick through [SelectionOverlay.selectionEndpoints]
  /// when the overlay reports an in-progress handle drag; body long-press
  /// (especially with deferred handles) never sets those flags, so we emit
  /// the same CLOCK_TICK here when the model selection actually changes.
  void _maybeBodySelectionDragHaptic(MarkdownSelection? before) {
    if (_dragIsHandle) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (controller.selection case final after? when after != before) {
      HapticFeedback.selectionClick();
    }
  }

  void _extendSelectionAt(Offset global) {
    if (_granularity == 1) {
      controller.extendToGlobal(global);
      return;
    }
    if (_granularAnchor case final anchor?) {
      controller.extendSelectionGranular(
        anchor,
        global,
        word: _granularity == 2,
      );
      return;
    }
    controller.extendToGlobal(global);
  }

  /// Whether a Shift-click should extend (rather than replace) the selection.
  bool get _shiftHeld => HardwareKeyboard.instance.isShiftPressed;

  /// Mouse-only "precise" pointer — matches [SelectableRegion].
  static bool _isPrecisePointer(PointerDeviceKind? kind) =>
      kind == PointerDeviceKind.mouse;

  /// Touch recognizer joins the arena only on selectable text, or while chrome
  /// must still receive taps (active range / toolbar) to dismiss or extend.
  bool _shouldArmTouchSelectionGesture(Offset global) {
    if (controller.hitsSelectableContent(global)) return true;
    if (controller.selection case final sel? when !sel.isCollapsed) {
      return true;
    }
    return _contextMenuController.isShown;
  }

  /// With an active range, take horizontal drags eagerly (block dismissible /
  /// nested horizontal scroll). With no selection, yield to those ancestors.
  bool get _shouldEagerVictoryOnTouchDrag => switch (controller.selection) {
        final sel? when !sel.isCollapsed => true,
        _ => false,
      };

  void _handleTapDown(TapDragDownDetails d) {
    _lastPointerDeviceKind = d.kind;
    _focusNode.requestFocus();
    final effective = _effectiveConsecutiveTapCount(d.consecutiveTapCount);
    // SelectableRegion selects the word/block on the multi-tap *down* so
    // chrome and a following drag are ready without waiting for tap-up.
    if (effective >= 2) {
      if (!_beginSelection(d.globalPosition, d.consecutiveTapCount)) return;
      hideToolbar();
    } else if (_isPrecisePointer(d.kind)) {
      hideToolbar();
    }
  }

  void _handleTapUp(TapDragUpDetails d) {
    _lastPointerDeviceKind = d.kind;
    _stopAutoscroll();
    final effective = _effectiveConsecutiveTapCount(d.consecutiveTapCount);

    // iOS: tap on an active selection toggles the toolbar.
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        effective <= 1 &&
        _positionIsOnActiveSelection(d.globalPosition)) {
      _toggleToolbar();
      return;
    }

    // Shift-click extends the existing selection to the tapped point.
    if (_shiftHeld && effective <= 1) {
      if (controller.selection case final _?) {
        _granularity = 1;
        _granularAnchor = null;
        controller.extendToGlobal(d.globalPosition);
        return;
      }
    }

    if (effective <= 1) {
      // Touch / non-precise: dismiss immediately (no double-tap arena wait).
      // Mouse: collapse to a caret at the click, matching prior desktop UX.
      if (!_isPrecisePointer(d.kind)) {
        hideToolbar();
        clearSelection();
        return;
      }
      _beginSelection(d.globalPosition, d.consecutiveTapCount);
      return;
    }

    // Multi-tap: range was set on tapDown; refresh handles/toolbar on tapUp.
    if (controller.selection case final sel? when !sel.isCollapsed) {
      // Keep the non-collapsed range from tapDown.
    } else if (!_beginSelection(d.globalPosition, d.consecutiveTapCount)) {
      return;
    }
    _refreshSelectionChrome();
  }

  void _handleDragStart(TapDragStartDetails d) {
    _lastPointerDeviceKind = d.kind;
    final effective = _effectiveConsecutiveTapCount(d.consecutiveTapCount);
    // Single-finger body drag selects only with a precise pointer; touch
    // vertical scroll must remain free (SelectableRegion contract).
    if (effective <= 1 && !_isPrecisePointer(d.kind)) {
      return;
    }
    _focusNode.requestFocus();
    hideToolbar();
    _dragIsHandle = false;
    _autoscrollSession.reset();
    if (_shiftHeld && effective <= 1) {
      if (controller.selection case final _?) {
        // Extending an existing range may clamp through gaps.
        _dragGlobal = d.globalPosition;
        _granularity = 1;
        _granularAnchor = null;
        controller.extendToGlobal(d.globalPosition);
        _driveAutoscroll();
        return;
      }
    }
    // New selection start must hit markdown (no chrome / empty-space clamp).
    if (!controller.hitsSelectableContent(d.globalPosition)) {
      return;
    }
    // Arm drag before mutating selection so overlay sync is pointer-sync.
    _dragGlobal = d.globalPosition;
    // Multi-tap may already have anchored on tapDown; still re-begin so a
    // drag that starts without a clean tapUp keeps the right granularity.
    _beginSelection(d.globalPosition, d.consecutiveTapCount);
    _driveAutoscroll();
  }

  void _handleDragUpdate(TapDragUpdateDetails d) {
    // Touch single-finger drag intentionally skips [_handleDragStart] arming.
    if (_dragGlobal == null) return;
    _updateSelection(d.globalPosition);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    _onScrollAffectingChrome();
    return false;
  }

  /// Parent/ancestor scrolls via [ScrollNotificationObserver] (Scaffold).
  void _onAncestorScrollNotification(ScrollNotification notification) {
    _onScrollAffectingChrome();
  }

  /// Absolute [contextMenuAnchors] go stale when content scrolls; handles
  /// still track via [LeaderLayer] on each surface, but overlay geometry
  /// needs a refresh after scroll-driven layout. When the selection leaves
  /// the host viewport entirely, temporarily remove the menu (keeping the
  /// restore intent); bring it back when selection paint re-enters view.
  void _onScrollAffectingChrome() {
    _refreshToolbarForVisibleGeometry();
    // Scroll notifications can run before child layout finishes (common when
    // the scope itself was outside the viewport cache). Retry next frame.
    _scheduleToolbarGeometryRefresh();
    _syncOverlay();
  }

  bool _onSizeChanged(SizeChangedLayoutNotification notification) {
    // [SizeChangedLayoutNotifier] dispatches from performLayout. Any geometry
    // walk ([localToGlobal], handle endpoints, toolbar clip) must wait until
    // after layout — including the drag-time overlay sync path.
    _scheduleToolbarGeometryRefresh();
    _syncOverlay();
    return false;
  }

  void _scheduleToolbarGeometryRefresh() {
    if (!controller.toolbarWanted || _toolbarGeometryRefreshScheduled) {
      return;
    }
    _toolbarGeometryRefreshScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _toolbarGeometryRefreshScheduled = false;
      if (!mounted || !controller.toolbarWanted) return;
      _refreshToolbarForVisibleGeometry();
    });
  }

  /// Shows, rebuilds, or suppresses the toolbar from visible selection 
  /// geometry.
  ///
  /// Must not run during layout/build — geometry walks use [localToGlobal].
  void _refreshToolbarForVisibleGeometry() {
    if (!controller.toolbarWanted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      _scheduleToolbarGeometryRefresh();
      return;
    }
    _lastSecondaryTapDown = null;
    if (_visibleSelectionBounds() case null) {
      _contextMenuController.remove();
      return;
    }
    if (!_contextMenuController.isShown) {
      // Restore after a geometry suppress (or a deferred [showToolbar]).
      if (widget.contextMenuBuilder case final builder?) {
        if (Overlay.maybeOf(context, rootOverlay: true) == null) return;
        _contextMenuController.show(
          context: context,
          contextMenuBuilder: (context) => builder(context, this),
        );
      }
      return;
    }
    _markContextMenuNeedsBuild();
  }

  /// Rebuilds the context menu when it is safe to dirty the overlay entry.
  ///
  /// [ContextMenuController.markNeedsBuild] must not run during build/layout
  /// (e.g. a [ScrollNotification] bubbling while a list tile rebuilds). Match
  /// [SelectionOverlay.markNeedsBuild]: defer to the next frame.
  void _markContextMenuNeedsBuild() {
    if (!_contextMenuController.isShown) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      if (_toolbarBuildScheduled) return;
      _toolbarBuildScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _toolbarBuildScheduled = false;
        if (!mounted || !_contextMenuController.isShown) return;
        _contextMenuController.markNeedsBuild();
      });
      return;
    }
    _contextMenuController.markNeedsBuild();
  }

  void _handleSecondaryTapUp(TapUpDetails d) {
    _focusNode.requestFocus();
    final onSelection = _positionIsOnActiveSelection(d.globalPosition);
    final previousSecondary = _previousSecondaryTapAnchor;
    final toolbarWasVisible = toolbarIsVisible;
    // Common paths: on-selection keeps the range and shows/toggles toolbar;
    // off-selection follows platform select/collapse.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
        if (onSelection) {
          showToolbar(d.globalPosition);
          _previousSecondaryTapAnchor = d.globalPosition;
          return;
        }
        controller.startAtGlobal(d.globalPosition);
        showToolbar(d.globalPosition);
      case TargetPlatform.linux:
        if (toolbarWasVisible) {
          hideToolbar();
          _previousSecondaryTapAnchor = d.globalPosition;
          return;
        }
        if (!onSelection) {
          controller.startAtGlobal(d.globalPosition);
        }
        showToolbar(d.globalPosition);
      case TargetPlatform.macOS:
        if (toolbarWasVisible) {
          if (previousSecondary case final anchor?
              when anchor == d.globalPosition) {
            hideToolbar();
            _previousSecondaryTapAnchor = d.globalPosition;
            return;
          }
        }
        if (!onSelection) {
          controller.selectWordAtGlobal(d.globalPosition);
        }
        showToolbar(d.globalPosition);
      case TargetPlatform.iOS:
        if (!onSelection) {
          controller.selectWordAtGlobal(d.globalPosition);
        }
        showToolbar(d.globalPosition);
    }
    _previousSecondaryTapAnchor = d.globalPosition;
  }

  Map<Type, GestureRecognizerFactory> get _gestures =>
      <Type, GestureRecognizerFactory>{
        // Mouse: taps + pan drag. Consecutive-tap counting stays on one
        // recognizer (SelectableRegion mouse path).
        TapAndPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapAndPanGestureRecognizer>(
          () => TapAndPanGestureRecognizer(
            supportedDevices: const <PointerDeviceKind>{
              PointerDeviceKind.mouse,
            },
          ),
          (recognizer) => recognizer
            ..dragStartBehavior = DragStartBehavior.down
            ..onTapDown = _handleTapDown
            ..onTapUp = _handleTapUp
            ..onDragStart = _handleDragStart
            ..onDragUpdate = _handleDragUpdate
            ..onDragEnd = ((_) => _onBodyDragEnd()),
        ),
        // Touch / stylus / trackpad: consecutive taps + horizontal drag-to-
        // extend, without a DoubleTapGestureRecognizer arena (no ~300ms
        // single-tap delay). Only joins the arena on selectable content (or
        // while a selection/toolbar is active) so wrapping a full dismissible
        // / scrollable page does not steal edge swipes on chrome. With an
        // active selection, eagerly wins horizontal drag (blocks dismissible);
        // otherwise yields to competing [HorizontalDragGestureRecognizer]s.
        _ContentGatedTapAndHorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
                _ContentGatedTapAndHorizontalDragGestureRecognizer>(
          () => _ContentGatedTapAndHorizontalDragGestureRecognizer(
            shouldArm: _shouldArmTouchSelectionGesture,
            shouldEagerVictoryOnDrag: () => _shouldEagerVictoryOnTouchDrag,
            supportedDevices: PointerDeviceKind.values
                .where((d) => d != PointerDeviceKind.mouse)
                .toSet(),
          ),
          (recognizer) => recognizer
            ..dragStartBehavior = DragStartBehavior.down
            ..onTapDown = _handleTapDown
            ..onTapUp = _handleTapUp
            ..onDragStart = _handleDragStart
            ..onDragUpdate = _handleDragUpdate
            ..onDragEnd = ((_) => _onBodyDragEnd()),
        ),
        // Secondary-only (any device): right-click opens the context toolbar.
        // Distinct type key so it can coexist with other recognizers in the 
        // map.
        _SecondaryTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            _SecondaryTapGestureRecognizer>(
          () => _SecondaryTapGestureRecognizer(),
          (recognizer) => recognizer
            ..onSecondaryTapDown =
                ((d) => _lastSecondaryTapDown = d.globalPosition)
            ..onSecondaryTapUp = _handleSecondaryTapUp,
        ),
        // Touch: long-press selects the word under the finger, then drags
        // extend by word (a plain swipe still scrolls an enclosing list).
        // Content-gated like the tap/drag recognizer so chrome swipes are not
        // held in the arena when the host wraps a dismissible page.
        _ContentGatedLongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
                _ContentGatedLongPressGestureRecognizer>(
          () => _ContentGatedLongPressGestureRecognizer(
            shouldArm: _shouldArmTouchSelectionGesture,
            supportedDevices: const <PointerDeviceKind>{
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
            },
          ),
          (recognizer) => recognizer
            ..onLongPressStart = ((d) {
              _lastPointerDeviceKind = PointerDeviceKind.touch;
              // Host may wrap chrome + markdown; only arm on a real text hit.
              if (!controller.hitsSelectableContent(d.globalPosition)) {
                return;
              }
              _focusNode.requestFocus();
              hideToolbar();
              _dragIsHandle = false;
              _autoscrollSession.reset();
              // Android shows handles on press-end; other platforms on start.
              _deferHandleShow =
                  defaultTargetPlatform == TargetPlatform.android;
              // Match TextField long-press: Android vibrate (LONG_PRESS) via
              // Feedback.forLongPress; iOS heavy-impact. selectionClick alone
              // is CLOCK_TICK and is easy to miss when handles are deferred.
              Feedback.forLongPress(context);
              // Arm drag before beginSelection so overlay sync is pointer-sync.
              _dragGlobal = d.globalPosition;
              _beginSelection(d.globalPosition, 2);
              // Magnifier still tracks during the press even when handles wait.
              _selectionOverlay?.showMagnifier(
                _magnifierInfo(d.globalPosition, isStart: false),
              );
              _driveAutoscroll();
            })
            ..onLongPressMoveUpdate = ((d) {
              if (_dragGlobal == null) return;
              _updateSelection(d.globalPosition);
              _selectionOverlay?.updateMagnifier(
                _magnifierInfo(d.globalPosition, isStart: false),
              );
            })
            ..onLongPressEnd = ((_) {
              if (_dragGlobal == null && controller.selection == null) {
                return;
              }
              _stopAutoscroll();
              _selectionOverlay?.hideMagnifier();
              _deferHandleShow = false;
              _updateHandlesAndOverlay();
              if (controller.selection case final sel? when !sel.isCollapsed) {
                showToolbar();
              }
            }),
        ),
      };

  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    CopySelectionTextIntent: CallbackAction<CopySelectionTextIntent>(
      onInvoke: (_) {
        copySelection();
        return null;
      },
    ),
    SelectAllTextIntent: CallbackAction<SelectAllTextIntent>(
      onInvoke: (_) {
        selectAll();
        return null;
      },
    ),
    ExtendSelectionByCharacterIntent:
        CallbackAction<ExtendSelectionByCharacterIntent>(
      onInvoke: (intent) {
        if (!intent.collapseSelection) {
          controller.extendSelectionByCharacter(forward: intent.forward);
        }
        return null;
      },
    ),
    ExtendSelectionToNextWordBoundaryIntent:
        CallbackAction<ExtendSelectionToNextWordBoundaryIntent>(
      onInvoke: (intent) {
        if (!intent.collapseSelection) {
          controller.extendSelectionByWord(forward: intent.forward);
        }
        return null;
      },
    ),
    ExtendSelectionToLineBreakIntent:
        CallbackAction<ExtendSelectionToLineBreakIntent>(
      onInvoke: (intent) {
        if (!intent.collapseSelection) {
          controller.extendSelectionToLineBreak(forward: intent.forward);
        }
        return null;
      },
    ),
    ExtendSelectionVerticallyToAdjacentLineIntent:
        CallbackAction<ExtendSelectionVerticallyToAdjacentLineIntent>(
      onInvoke: (intent) {
        if (!intent.collapseSelection) {
          controller.extendSelectionToAdjacentLine(forward: intent.forward);
        }
        return null;
      },
    ),
    ExtendSelectionToDocumentBoundaryIntent:
        CallbackAction<ExtendSelectionToDocumentBoundaryIntent>(
      onInvoke: (intent) {
        if (!intent.collapseSelection) {
          controller.extendSelectionToDocumentBoundary(forward: intent.forward);
        }
        return null;
      },
    ),
    DismissIntent: CallbackAction<DismissIntent>(
      onInvoke: (_) {
        clearSelection();
        return null;
      },
    ),
  };

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return _ScopeMarker(
        controller: widget.controller,
        state: this,
        child: widget.child,
      );
    }
    return _ScopeMarker(
      controller: widget.controller,
      state: this,
      child: Actions(
        actions: _actions,
        child: Focus(
          focusNode: _focusNode,
          child: NotificationListener<SizeChangedLayoutNotification>(
            onNotification: _onSizeChanged,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: RawGestureDetector(
                behavior: HitTestBehavior.translucent,
                gestures: _gestures,
                excludeFromSemantics: true,
                child: SizeChangedLayoutNotifier(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Distinct [TapGestureRecognizer] subclass used as the map key for the
/// secondary-only right-click recognizer in [RawGestureDetector]'s gestures.
final class _SecondaryTapGestureRecognizer extends TapGestureRecognizer {
  _SecondaryTapGestureRecognizer();
}

/// [TapAndHorizontalDragGestureRecognizer] that skips the arena when the
/// pointer is not on selectable markdown (and no selection/toolbar needs
/// tap handling). Lets ancestor dismiss / horizontal-drag gestures win on
/// chrome when a host wraps an entire page. With an active selection,
/// [eagerVictoryOnDrag] is refreshed on each pointer down so horizontal
/// swipes stay with selection chrome instead of dismissible.
final class _ContentGatedTapAndHorizontalDragGestureRecognizer
    extends TapAndHorizontalDragGestureRecognizer {
  _ContentGatedTapAndHorizontalDragGestureRecognizer({
    required this.shouldArm,
    required this.shouldEagerVictoryOnDrag,
    super.supportedDevices,
  });

  /// Return true to track this pointer; false leaves the arena to ancestors.
  final bool Function(Offset globalPosition) shouldArm;

  /// When true, claim horizontal drags immediately (active selection).
  final bool Function() shouldEagerVictoryOnDrag;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!shouldArm(event.position)) {
      return;
    }
    eagerVictoryOnDrag = shouldEagerVictoryOnDrag();
    super.addAllowedPointer(event);
  }
}

/// [LongPressGestureRecognizer] that skips the arena off selectable content
/// (same gate as [_ContentGatedTapAndHorizontalDragGestureRecognizer]).
final class _ContentGatedLongPressGestureRecognizer
    extends LongPressGestureRecognizer {
  _ContentGatedLongPressGestureRecognizer({
    required this.shouldArm,
    super.supportedDevices,
  });

  /// Return true to track this pointer; false leaves the arena to ancestors.
  final bool Function(Offset globalPosition) shouldArm;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!shouldArm(event.position)) {
      return;
    }
    super.addAllowedPointer(event);
  }
}
