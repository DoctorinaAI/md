import 'package:flutter/cupertino.dart'
    show
        cupertinoTextSelectionHandleControls,
        cupertinoDesktopTextSelectionHandleControls;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'selection.dart';

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
class MarkdownSelectionScopeState extends State<MarkdownSelectionScope> {
  final ContextMenuController _contextMenuController = ContextMenuController();
  final LayerLink _startHandleLink = LayerLink();
  final LayerLink _endHandleLink = LayerLink();
  final LayerLink _toolbarLink = LayerLink();
  SelectionOverlay? _selectionOverlay;
  FocusNode? _internalFocusNode;
  Offset? _lastSecondaryTapDown;
  MarkdownSelection? _lastSelection;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applySelectionColor();
  }

  @override
  void didUpdateWidget(covariant MarkdownSelectionScope oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    widget.controller.removeListener(_onControllerChanged);
    _contextMenuController.remove();
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    _internalFocusNode?.dispose();
    super.dispose();
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
    }
    if (sel == null || sel.isCollapsed) hideToolbar();
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

  /// Syncs the handle overlay, deferring to a post-frame callback when called
  /// during a build/layout/paint phase (e.g. a streaming `setState`).
  void _syncOverlay() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateHandlesAndOverlay();
      });
    } else {
      _updateHandlesAndOverlay();
    }
  }

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
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
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
    final overlay = _selectionOverlay;
    if (overlay == null) {
      if (Overlay.maybeOf(context) == null) return; // no host for handles
      _selectionOverlay = SelectionOverlay(
        context: context,
        startHandleType: TextSelectionHandleType.left,
        lineHeightAtStart: endpoints.startLocal.height,
        onStartHandleDragStart: (d) => _onHandleDragStart(d, isStart: true),
        onStartHandleDragUpdate: (d) => _onHandleDragUpdate(d, isStart: true),
        onStartHandleDragEnd: (_) => _onHandleDragEnd(),
        endHandleType: TextSelectionHandleType.right,
        lineHeightAtEnd: endpoints.endLocal.height,
        onEndHandleDragStart: (d) => _onHandleDragStart(d, isStart: false),
        onEndHandleDragUpdate: (d) => _onHandleDragUpdate(d, isStart: false),
        onEndHandleDragEnd: (_) => _onHandleDragEnd(),
        selectionEndpoints: <TextSelectionPoint>[startPoint, endPoint],
        selectionControls: _effectiveControls,
        selectionDelegate: null,
        clipboardStatus: null,
        startHandleLayerLink: _startHandleLink,
        endHandleLayerLink: _endHandleLink,
        toolbarLayerLink: _toolbarLink,
        magnifierConfiguration: _effectiveMagnifier,
      )..showHandles();
    } else {
      overlay
        ..startHandleType = TextSelectionHandleType.left
        ..lineHeightAtStart = endpoints.startLocal.height
        ..endHandleType = TextSelectionHandleType.right
        ..lineHeightAtEnd = endpoints.endLocal.height
        ..selectionEndpoints = <TextSelectionPoint>[startPoint, endPoint];
    }
  }

  /// Assigns the two handle leader layers to their owning surfaces (and clears
  /// them everywhere else) in a single pass, so nothing repaints needlessly.
  void _applyHandles(MarkdownHandleEndpoints? e) {
    final startSurface = e?.startSurface;
    final endSurface = e?.endSurface;
    final startLocal =
        e == null ? null : Offset(e.startLocal.left, e.startLocal.bottom);
    final endLocal =
        e == null ? null : Offset(e.endLocal.right, e.endLocal.bottom);
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
    _selectionOverlay
        ?.showMagnifier(_magnifierInfo(d.globalPosition, isStart: isStart));
  }

  void _onHandleDragUpdate(DragUpdateDetails d, {required bool isStart}) {
    final e = controller.selectionHandleEndpoints();
    final lineHeight =
        e == null ? 0.0 : (isStart ? e.startLocal.height : e.endLocal.height);
    controller.moveSelectionEdgeToGlobal(
      d.globalPosition - Offset(0, lineHeight / 2),
      isStart: isStart,
    );
    _selectionOverlay
        ?.updateMagnifier(_magnifierInfo(d.globalPosition, isStart: isStart));
  }

  void _onHandleDragEnd() {
    _selectionOverlay?.hideMagnifier();
    showToolbar();
  }

  MagnifierInfo _magnifierInfo(Offset gesture, {required bool isStart}) {
    final e = controller.selectionHandleEndpoints();
    final caret = e == null
        ? Rect.fromCenter(center: gesture, width: 0, height: 24)
        : (isStart ? e.startGlobal : e.endGlobal);
    final bounds = e == null
        ? caret
        : (isStart ? e.startSurface.globalBounds : e.endSurface.globalBounds);
    return MagnifierInfo(
      globalGesturePosition: gesture,
      caretRect: caret,
      fieldBounds: bounds,
      currentLineBoundaries: bounds,
    );
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
    final sel = controller.selection;
    if (sel != null && !sel.isCollapsed) {
      items.add(ContextMenuButtonItem(
        type: ContextMenuButtonType.copy,
        onPressed: copySelection,
      ));
    }
    if (controller.documents.isNotEmpty) {
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

  /// Where to anchor the toolbar: the last right-click point, else the top /
  /// bottom center of the selection's bounding box.
  TextSelectionToolbarAnchors get contextMenuAnchors {
    final secondary = _lastSecondaryTapDown;
    if (secondary != null) {
      return TextSelectionToolbarAnchors(primaryAnchor: secondary);
    }
    final rects = controller.globalSelectionRects();
    if (rects.isEmpty) {
      final box = context.findRenderObject() as RenderBox?;
      final bounds = box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.zero;
      return TextSelectionToolbarAnchors(
        primaryAnchor: bounds.topCenter,
        secondaryAnchor: bounds.bottomCenter,
      );
    }
    var bounds = rects.first;
    for (final rect in rects.skip(1)) {
      bounds = bounds.expandToInclude(rect);
    }
    return TextSelectionToolbarAnchors(
      primaryAnchor: bounds.topCenter,
      secondaryAnchor: bounds.bottomCenter,
    );
  }

  /// Whether the toolbar is currently visible.
  bool get toolbarIsVisible => _contextMenuController.isShown;

  /// Shows the context toolbar. [location] anchors it at a point (e.g. the
  /// right-click position); otherwise it anchors to the selection.
  void showToolbar([Offset? location]) {
    final builder = widget.contextMenuBuilder;
    if (builder == null) return;
    if (Overlay.maybeOf(context, rootOverlay: true) == null) return;
    _lastSecondaryTapDown = location;
    _contextMenuController.remove();
    _contextMenuController.show(
      context: context,
      contextMenuBuilder: (context) => builder(context, this),
    );
  }

  /// Hides the context toolbar.
  void hideToolbar() {
    _lastSecondaryTapDown = null;
    _contextMenuController.remove();
  }

  // --- gestures ------------------------------------------------------------

  void _onDragDown(Offset globalPosition) {
    _focusNode.requestFocus();
    hideToolbar();
    controller.startAtGlobal(globalPosition);
  }

  Map<Type, GestureRecognizerFactory> get _gestures =>
      <Type, GestureRecognizerFactory>{
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
            ..onStart = ((d) => _onDragDown(d.globalPosition))
            ..onUpdate = ((d) => controller.extendToGlobal(d.globalPosition)),
        ),
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(),
          (recognizer) => recognizer
            ..onLongPressStart = ((d) => _onDragDown(d.globalPosition))
            ..onLongPressMoveUpdate =
                ((d) => controller.extendToGlobal(d.globalPosition))
            ..onLongPressEnd = ((_) => showToolbar()),
        ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (recognizer) => recognizer
            ..onTapDown = ((_) => hideToolbar())
            ..onSecondaryTapDown =
                ((d) => _lastSecondaryTapDown = d.globalPosition)
            ..onSecondaryTapUp = ((d) {
              _focusNode.requestFocus();
              showToolbar(d.globalPosition);
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
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: _gestures,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
