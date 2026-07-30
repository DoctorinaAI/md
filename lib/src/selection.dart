import 'dart:ui' show Offset, Rect, TextRange;

import 'package:flutter/foundation.dart';

import 'markdown.dart';
import 'nodes.dart';

/// Rendered plain text of a single [MD$Block] — the concatenation of its span
/// texts, in the coordinate space that `TextPainter.getPositionForOffset`
/// indexes. This is the single source of truth shared by selection extraction
/// and pointer hit-testing.
///
/// Structural blocks ([MD$Divider], [MD$Spacer]) contribute no text. Lists join
/// items (and nested items, depth-first) with `\n`; tables join cells with `\t`
/// and rows with `\n`.
String markdownBlockRenderedText(MD$Block block) => block.map<String>(
      paragraph: (p) => _spans(p.spans),
      heading: (h) => _spans(h.spans),
      quote: (q) => _spans(q.spans),
      alert: (a) => _spans(a.spans),
      code: (c) => c.text,
      list: (l) {
        final buffer = StringBuffer();
        _listItems(l.items, buffer);
        return buffer.toString();
      },
      table: (t) => <String>[
        t.header.cells.map(_spans).join('\t'),
        for (final row in t.rows) row.cells.map(_spans).join('\t'),
      ].join('\n'),
      divider: (_) => '',
      spacer: (_) => '',
    );

String _spans(List<MD$Span> spans) {
  final buffer = StringBuffer();
  for (final span in spans) buffer.write(span.text);
  return buffer.toString();
}

void _listItems(List<MD$ListItem> items, StringBuffer buffer) {
  for (final item in items) {
    if (buffer.isNotEmpty) buffer.write('\n');
    buffer.write(_spans(item.spans));
    if (item.children.isNotEmpty) _listItems(item.children, buffer);
  }
}

/// A logical caret position inside a selectable Markdown document.
///
/// Anchored on the immutable model — never on a mounted render object — so it
/// stays valid while the widget is scrolled off-screen and disposed.
@immutable
final class MarkdownPosition {
  /// Creates a position in [documentId] at rendered-text [offset] of the block
  /// at [blockIndex] in `Markdown.blocks`.
  const MarkdownPosition({
    required this.documentId,
    required this.blockIndex,
    required this.offset,
  });

  /// Stable id of the document (e.g. a chat message id). Opaque to the library.
  final Object documentId;

  /// Index into the source `Markdown.blocks` (not the painter list).
  final int blockIndex;

  /// Offset into the block's rendered text (see [markdownBlockRenderedText]).
  final int offset;

  @override
  bool operator ==(Object other) =>
      other is MarkdownPosition &&
      other.documentId == documentId &&
      other.blockIndex == blockIndex &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(documentId, blockIndex, offset);

  @override
  String toString() => 'MarkdownPosition($documentId#$blockIndex@$offset)';
}

/// A directed selection between [base] (where the gesture anchored) and
/// [extent] (the moving end). Reading order is resolved by the controller.
@immutable
final class MarkdownSelection {
  /// Creates a selection from [base] to [extent].
  const MarkdownSelection({required this.base, required this.extent});

  /// A collapsed (empty) selection at [at].
  const MarkdownSelection.collapsed(MarkdownPosition at)
      : base = at,
        extent = at;

  /// The fixed anchor of the selection.
  final MarkdownPosition base;

  /// The moving end of the selection.
  final MarkdownPosition extent;

  /// Whether [base] and [extent] coincide (nothing is selected).
  bool get isCollapsed => base == extent;

  @override
  bool operator ==(Object other) =>
      other is MarkdownSelection &&
      other.base == base &&
      other.extent == extent;

  @override
  int get hashCode => Object.hash(base, extent);

  @override
  String toString() => 'MarkdownSelection($base -> $extent)';
}

/// A document registered with a controller, in reading order.
@immutable
final class MarkdownDocumentRef {
  /// Creates a reference binding a stable [id] to its immutable [model].
  const MarkdownDocumentRef(
      {required this.id, required this.model, this.order});

  /// Stable id of the document (e.g. a chat message id).
  final Object id;

  /// The immutable Markdown model. Retained by the app; the controller reads
  /// text from it even while the widget is unmounted.
  final Markdown model;

  /// Explicit reading-order key. When null, registration order is used. Supply
  /// it (e.g. the message index) so unmounted documents still order correctly.
  final int? order;
}

/// One block's contribution to a selection: the guaranteed [text] slice plus
/// structured metadata for custom formatters.
@immutable
final class MarkdownSelectedBlock {
  /// Creates a selected-block segment.
  const MarkdownSelectedBlock({
    required this.blockIndex,
    required this.type,
    required this.text,
    required this.renderedRange,
    required this.block,
    this.sourceRange,
  });

  /// Index of the block in `Markdown.blocks`.
  final int blockIndex;

  /// The block's `MD$Block.type` (`'paragraph'`, `'table'`, ...).
  final String type;

  /// The selected slice of the block's rendered text. Always populated.
  final String text;

  /// The selected range within the block's rendered text.
  final TextRange renderedRange;

  /// Best-effort range within the block's Markdown source (may be null).
  final TextRange? sourceRange;

  /// The immutable block, for consumers that reconstruct richer output.
  final MD$Block block;
}

/// One document's contribution to a selection.
@immutable
final class MarkdownSelectedDocument {
  /// Creates a selected-document segment.
  const MarkdownSelectedDocument({
    required this.documentId,
    required this.blocks,
  });

  /// The document's stable id.
  final Object documentId;

  /// The selected blocks of this document, in reading order.
  final List<MarkdownSelectedBlock> blocks;
}

/// The structured result of a selection, spanning one or more documents.
///
/// This is the canonical representation; render it to a string with a
/// [MarkdownSelectionFormatter] (or the default [MarkdownPlainTextFormatter]).
@immutable
final class MarkdownSelectedContent {
  /// Creates structured selected content.
  const MarkdownSelectedContent({required this.documents});

  /// The selected documents, in reading order.
  final List<MarkdownSelectedDocument> documents;

  /// Whether nothing is selected.
  bool get isEmpty => documents.isEmpty;

  /// Whether something is selected.
  bool get isNotEmpty => documents.isNotEmpty;

  /// Convenience: format with the default [MarkdownPlainTextFormatter].
  String toPlainText() => const MarkdownPlainTextFormatter().format(this);
}

/// Turns [MarkdownSelectedContent] into a string. Implement this to customize
/// how a selection is copied (e.g. "Copy as Markdown").
abstract interface class MarkdownSelectionFormatter {
  /// Formats [content] into a single string.
  String format(MarkdownSelectedContent content);
}

/// The default formatter: joins block slices with [blockSeparator] and
/// documents with [documentSeparator]. Structural blocks (empty text) are
/// skipped. Table/list cell structure is already baked into each block's text.
@immutable
final class MarkdownPlainTextFormatter implements MarkdownSelectionFormatter {
  /// Creates a plain-text formatter.
  const MarkdownPlainTextFormatter({
    this.blockSeparator = '\n',
    this.documentSeparator = '\n\n',
  });

  /// Inserted between blocks within a document.
  final String blockSeparator;

  /// Inserted between documents.
  final String documentSeparator;

  @override
  String format(MarkdownSelectedContent content) {
    final docs = <String>[];
    for (final doc in content.documents) {
      final blocks = <String>[];
      for (final block in doc.blocks) {
        if (block.text.isEmpty) continue;
        blocks.add(block.text);
      }
      if (blocks.isNotEmpty) docs.add(blocks.join(blockSeparator));
    }
    return docs.join(documentSeparator);
  }
}

/// Decides how a selection anchor is remapped when a document's model is
/// replaced (e.g. streaming). Returning null drops the anchor (collapsing the
/// selection). No stable block id is required — remapping is content-based.
abstract interface class MarkdownReconciliationPolicy {
  /// Append-only fast path, else clamp indices/offsets into the new bounds.
  /// Cheapest; correct for streaming appends, drifts on front/mid inserts.
  const factory MarkdownReconciliationPolicy.appendFastPath() =
      _AppendFastPathPolicy;

  /// Append fast path, then relocate by matching block rendered text, else
  /// clamp. The default — robust to inserts/reorders without a model id.
  const factory MarkdownReconciliationPolicy.contentAnchored() =
      _ContentAnchoredPolicy;

  /// Drop the selection whenever the anchor's document changes at all.
  const factory MarkdownReconciliationPolicy.clearOnChange() = _ClearPolicy;

  /// Remaps [anchor] from [oldModel] to [newModel]; null drops it.
  MarkdownPosition? remap(
    MarkdownPosition anchor,
    Markdown oldModel,
    Markdown newModel,
  );
}

MarkdownPosition _clampInto(MarkdownPosition anchor, Markdown model) {
  if (model.blocks.isEmpty) {
    return MarkdownPosition(
        documentId: anchor.documentId, blockIndex: 0, offset: 0);
  }
  final bi = anchor.blockIndex.clamp(0, model.blocks.length - 1);
  final len = markdownBlockRenderedText(model.blocks[bi]).length;
  return MarkdownPosition(
    documentId: anchor.documentId,
    blockIndex: bi,
    offset: anchor.offset.clamp(0, len),
  );
}

bool _appendPrefixKeeps(MarkdownPosition anchor, Markdown o, Markdown n) {
  if (anchor.blockIndex >= o.blocks.length ||
      anchor.blockIndex >= n.blocks.length) {
    return false;
  }
  for (var i = 0; i < anchor.blockIndex; i++) {
    if (i >= n.blocks.length ||
        markdownBlockRenderedText(o.blocks[i]) !=
            markdownBlockRenderedText(n.blocks[i])) {
      return false;
    }
  }
  final oldText = markdownBlockRenderedText(o.blocks[anchor.blockIndex]);
  final newText = markdownBlockRenderedText(n.blocks[anchor.blockIndex]);
  return newText.startsWith(oldText) || oldText.startsWith(newText);
}

@immutable
class _AppendFastPathPolicy implements MarkdownReconciliationPolicy {
  const _AppendFastPathPolicy();
  @override
  MarkdownPosition? remap(MarkdownPosition anchor, Markdown o, Markdown n) {
    if (_appendPrefixKeeps(anchor, o, n)) {
      final len = markdownBlockRenderedText(n.blocks[anchor.blockIndex]).length;
      return MarkdownPosition(
        documentId: anchor.documentId,
        blockIndex: anchor.blockIndex,
        offset: anchor.offset.clamp(0, len),
      );
    }
    return _clampInto(anchor, n);
  }
}

@immutable
class _ContentAnchoredPolicy implements MarkdownReconciliationPolicy {
  const _ContentAnchoredPolicy();
  @override
  MarkdownPosition? remap(MarkdownPosition anchor, Markdown o, Markdown n) {
    if (anchor.blockIndex >= o.blocks.length) return _clampInto(anchor, n);
    if (_appendPrefixKeeps(anchor, o, n)) {
      final len = markdownBlockRenderedText(n.blocks[anchor.blockIndex]).length;
      return MarkdownPosition(
        documentId: anchor.documentId,
        blockIndex: anchor.blockIndex,
        offset: anchor.offset.clamp(0, len),
      );
    }
    // Relocate by matching the anchor block's rendered text in the new model.
    final oldText = markdownBlockRenderedText(o.blocks[anchor.blockIndex]);
    if (oldText.isNotEmpty) {
      for (var i = 0; i < n.blocks.length; i++) {
        if (markdownBlockRenderedText(n.blocks[i]) == oldText) {
          return MarkdownPosition(
            documentId: anchor.documentId,
            blockIndex: i,
            offset: anchor.offset.clamp(0, oldText.length),
          );
        }
      }
    }
    return _clampInto(anchor, n);
  }
}

@immutable
class _ClearPolicy implements MarkdownReconciliationPolicy {
  const _ClearPolicy();
  @override
  MarkdownPosition? remap(MarkdownPosition anchor, Markdown o, Markdown n) =>
      null;
}

/// A mounted document's geometry bridge — the controller's window onto a live
/// render object. Implemented by the render layer; used for hit-testing.
abstract interface class MarkdownSelectionSurface {
  /// The document id this surface renders.
  Object get documentId;

  /// The surface's bounds in global (screen) coordinates.
  Rect get globalBounds;

  /// Maps a global point to a logical position, or null if outside any text.
  MarkdownPosition? positionForGlobal(Offset globalPosition);
}

class _DocEntry {
  _DocEntry(this.id, this.model, this.order);
  final Object id;
  Markdown model;
  int order;
}

/// The single source of truth for a Markdown selection.
///
/// Holds the selection as logical anchors over an app-supplied registry of
/// immutable models, so selected text can always be extracted — even for
/// documents whose widgets are currently unmounted (e.g. scrolled out of a
/// chat list). Mounted render objects register as [MarkdownSelectionSurface]s
/// for hit-testing and listen for repaints.
class MarkdownSelectionController extends ChangeNotifier {
  /// Creates a controller with an optional [reconciliation] policy (defaults to
  /// [MarkdownReconciliationPolicy.contentAnchored]) and default [formatter].
  MarkdownSelectionController({
    MarkdownReconciliationPolicy? reconciliation,
    MarkdownSelectionFormatter formatter = const MarkdownPlainTextFormatter(),
    MarkdownSelectionGroup? group,
  })  : reconciliation = reconciliation ??
            const MarkdownReconciliationPolicy.contentAnchored(),
        _formatter = formatter,
        _group = group {
    group?._add(this);
  }

  /// The anchor-remapping policy used on document updates.
  final MarkdownReconciliationPolicy reconciliation;

  final MarkdownSelectionGroup? _group;

  MarkdownSelectionFormatter _formatter;

  /// The default formatter used by [getText] when none is supplied.
  MarkdownSelectionFormatter get formatter => _formatter;
  set formatter(MarkdownSelectionFormatter value) {
    if (identical(value, _formatter)) return;
    _formatter = value;
    notifyListeners();
  }

  final List<_DocEntry> _docs = <_DocEntry>[];
  final Map<Object, MarkdownSelectionSurface> _surfaces =
      <Object, MarkdownSelectionSurface>{};

  MarkdownSelection? _selection;

  /// The current selection, or null when nothing is selected.
  MarkdownSelection? get selection => _selection;
  set selection(MarkdownSelection? value) {
    if (value == _selection) return;
    _selection = value;
    if (value != null && !value.isCollapsed) _group?._claim(this);
    notifyListeners();
  }

  @override
  void dispose() {
    _group?._remove(this);
    super.dispose();
  }

  /// The registered documents, in reading order.
  List<MarkdownDocumentRef> get documents => <MarkdownDocumentRef>[
        for (final e in _docs)
          MarkdownDocumentRef(id: e.id, model: e.model, order: e.order),
      ];

  // --- registry -----------------------------------------------------------

  /// Replaces the whole registry (initial/bulk load), preserving a still-valid
  /// selection by clamping it into the new documents.
  void setDocuments(Iterable<MarkdownDocumentRef> docs) {
    _docs
      ..clear()
      ..addAll(<_DocEntry>[
        for (final (i, d) in docs.indexed)
          _DocEntry(d.id, d.model, d.order ?? i),
      ]);
    _sort();
    _validateSelection();
    notifyListeners();
  }

  /// Inserts or updates one document. On a model change the selection is
  /// reconciled via [reconciliation] (this is the streaming entry point).
  void putDocument(Object id, Markdown model, {int? order}) {
    final idx = _docs.indexWhere((e) => e.id == id);
    if (idx < 0) {
      _docs.add(_DocEntry(id, model, order ?? _docs.length));
      _sort();
      notifyListeners();
      return;
    }
    final entry = _docs[idx];
    final old = entry.model;
    if (order != null) entry.order = order;
    if (identical(old, model)) {
      _sort();
      notifyListeners();
      return;
    }
    entry.model = model;
    _sort();
    _reconcile(id, old, model);
    notifyListeners();
  }

  /// Removes a document. If the selection touched it, the selection is dropped.
  void removeDocument(Object id) {
    _docs.removeWhere((e) => e.id == id);
    final sel = _selection;
    if (sel != null &&
        (sel.base.documentId == id || sel.extent.documentId == id)) {
      _selection = null;
    }
    notifyListeners();
  }

  void _sort() {
    _docs.sort((a, b) => a.order.compareTo(b.order));
  }

  void _reconcile(Object id, Markdown oldModel, Markdown newModel) {
    final sel = _selection;
    if (sel == null) return;
    final base = sel.base.documentId == id
        ? reconciliation.remap(sel.base, oldModel, newModel)
        : sel.base;
    final extent = sel.extent.documentId == id
        ? reconciliation.remap(sel.extent, oldModel, newModel)
        : sel.extent;
    _selection = (base == null || extent == null)
        ? null
        : MarkdownSelection(base: base, extent: extent);
  }

  void _validateSelection() {
    final sel = _selection;
    if (sel == null) return;
    if (_orderIndex(sel.base.documentId) < 0 ||
        _orderIndex(sel.extent.documentId) < 0) {
      _selection = null;
      return;
    }
    _selection = MarkdownSelection(
      base: _clampInto(sel.base, _modelOf(sel.base.documentId)),
      extent: _clampInto(sel.extent, _modelOf(sel.extent.documentId)),
    );
  }

  // --- surfaces (mounted geometry) ----------------------------------------

  /// Registers a mounted [surface] for hit-testing. Called on RenderObject
  /// attach.
  void attachSurface(MarkdownSelectionSurface surface) {
    _surfaces[surface.documentId] = surface;
  }

  /// Unregisters a [surface]. Called on RenderObject detach/dispose.
  void detachSurface(MarkdownSelectionSurface surface) {
    if (identical(_surfaces[surface.documentId], surface)) {
      _surfaces.remove(surface.documentId);
    }
  }

  /// The currently mounted surfaces.
  Iterable<MarkdownSelectionSurface> get mountedSurfaces => _surfaces.values;

  /// Maps a global point to a logical position by asking mounted surfaces.
  ///
  /// When the point is inside a surface it is used directly; otherwise the
  /// vertically-nearest surface is chosen and the point clamped into it, so a
  /// drag through the gaps/edges between widgets still extends the selection.
  MarkdownPosition? positionForGlobal(Offset globalPosition) {
    MarkdownSelectionSurface? nearest;
    var bestDistance = double.infinity;
    for (final surface in _surfaces.values) {
      final bounds = surface.globalBounds;
      // A zero-area surface (an empty document, or one that lays out to zero
      // width/height) has nothing to select and would invert the clamp below.
      if (bounds.isEmpty) continue;
      if (bounds.contains(globalPosition)) {
        return surface.positionForGlobal(globalPosition);
      }
      final dy = globalPosition.dy < bounds.top
          ? bounds.top - globalPosition.dy
          : (globalPosition.dy > bounds.bottom
              ? globalPosition.dy - bounds.bottom
              : 0.0);
      if (dy < bestDistance) {
        bestDistance = dy;
        nearest = surface;
      }
    }
    if (nearest == null) return null;
    final bounds = nearest.globalBounds;
    // Clamp INTO the surface, keeping the upper bound >= the lower bound so a
    // very small surface never inverts the limits (num.clamp throws then).
    final maxX = bounds.right - 0.01;
    final maxY = bounds.bottom - 0.01;
    final clamped = Offset(
      globalPosition.dx
          .clamp(bounds.left, maxX < bounds.left ? bounds.left : maxX),
      globalPosition.dy
          .clamp(bounds.top, maxY < bounds.top ? bounds.top : maxY),
    );
    return nearest.positionForGlobal(clamped);
  }

  // --- mutation ------------------------------------------------------------

  /// Clears the selection.
  void clear() => selection = null;

  /// Collapses the selection at [position].
  void collapseAt(MarkdownPosition position) =>
      selection = MarkdownSelection.collapsed(position);

  /// Extends the moving end of the selection to [position] (anchoring [base]
  /// first if there is no selection yet).
  void extendTo(MarkdownPosition position) {
    final sel = _selection;
    selection = sel == null
        ? MarkdownSelection.collapsed(position)
        : MarkdownSelection(base: sel.base, extent: position);
  }

  /// Begins a selection at a global point (e.g. a drag start).
  void startAtGlobal(Offset globalPosition) {
    final p = positionForGlobal(globalPosition);
    if (p != null) collapseAt(p);
  }

  /// Extends the selection to a global point (e.g. a drag update).
  void extendToGlobal(Offset globalPosition) {
    final p = positionForGlobal(globalPosition);
    if (p != null) extendTo(p);
  }

  /// Selects everything across every registered document.
  void selectAll() {
    if (_docs.isEmpty) return;
    final first = _docs.first, last = _docs.last;
    if (first.model.blocks.isEmpty || last.model.blocks.isEmpty) return;
    final lastBlock = last.model.blocks.length - 1;
    selection = MarkdownSelection(
      base: MarkdownPosition(documentId: first.id, blockIndex: 0, offset: 0),
      extent: MarkdownPosition(
        documentId: last.id,
        blockIndex: lastBlock,
        offset: markdownBlockRenderedText(last.model.blocks[lastBlock]).length,
      ),
    );
  }

  /// The selected range within [documentId]'s block [blockIndex], or null when
  /// that block is not part of the current selection. Used by surfaces to paint
  /// their highlight.
  TextRange? rangeFor(Object documentId, int blockIndex) {
    final sel = _selection;
    if (sel == null) return null;
    final (a, b) = _ordered(sel);
    final di = _orderIndex(documentId);
    if (di < 0) return null;
    final startDoc = _orderIndex(a.documentId);
    final endDoc = _orderIndex(b.documentId);
    if (di < startDoc || di > endDoc) return null;
    final model = _modelOf(documentId);
    if (blockIndex < 0 || blockIndex >= model.blocks.length) return null;
    final len = markdownBlockRenderedText(model.blocks[blockIndex]).length;
    final startBlock = di == startDoc ? a.blockIndex : 0;
    final endBlock = di == endDoc ? b.blockIndex : model.blocks.length - 1;
    if (blockIndex < startBlock || blockIndex > endBlock) return null;
    final from = (di == startDoc && blockIndex == a.blockIndex) ? a.offset : 0;
    final to = (di == endDoc && blockIndex == b.blockIndex) ? b.offset : len;
    return TextRange(start: from.clamp(0, len), end: to.clamp(0, len));
  }

  // --- extraction ----------------------------------------------------------

  /// The structured selected content, assembled from the models in reading
  /// order (works regardless of which surfaces are mounted).
  MarkdownSelectedContent selectedContent() {
    final sel = _selection;
    if (sel == null) {
      return const MarkdownSelectedContent(
          documents: <MarkdownSelectedDocument>[]);
    }
    final (a, b) = _ordered(sel);
    final startDoc = _orderIndex(a.documentId);
    final endDoc = _orderIndex(b.documentId);
    if (startDoc < 0 || endDoc < 0) {
      return const MarkdownSelectedContent(
          documents: <MarkdownSelectedDocument>[]);
    }
    final out = <MarkdownSelectedDocument>[];
    for (var d = startDoc; d <= endDoc; d++) {
      final entry = _docs[d];
      final blocks = entry.model.blocks;
      final fromBlock = d == startDoc ? a.blockIndex : 0;
      final toBlock = d == endDoc ? b.blockIndex : blocks.length - 1;
      final segs = <MarkdownSelectedBlock>[];
      for (var bi = fromBlock; bi <= toBlock && bi < blocks.length; bi++) {
        if (bi < 0) continue;
        final text = markdownBlockRenderedText(blocks[bi]);
        final from = (d == startDoc && bi == a.blockIndex)
            ? a.offset.clamp(0, text.length)
            : 0;
        final to = (d == endDoc && bi == b.blockIndex)
            ? b.offset.clamp(0, text.length)
            : text.length;
        if (to <= from) continue;
        segs.add(MarkdownSelectedBlock(
          blockIndex: bi,
          type: blocks[bi].type,
          text: text.substring(from, to),
          renderedRange: TextRange(start: from, end: to),
          block: blocks[bi],
        ));
      }
      if (segs.isNotEmpty) {
        out.add(MarkdownSelectedDocument(documentId: entry.id, blocks: segs));
      }
    }
    return MarkdownSelectedContent(documents: out);
  }

  /// The selected text, formatted with [formatter] (or the default when null).
  String getText([MarkdownSelectionFormatter? formatter]) =>
      (formatter ?? _formatter).format(selectedContent());

  // --- ordering helpers ----------------------------------------------------

  int _orderIndex(Object id) => _docs.indexWhere((e) => e.id == id);

  Markdown _modelOf(Object id) => _docs[_orderIndex(id)].model;

  int _compare(MarkdownPosition a, MarkdownPosition b) {
    final ai = _orderIndex(a.documentId), bi = _orderIndex(b.documentId);
    if (ai != bi) return ai.compareTo(bi);
    if (a.blockIndex != b.blockIndex)
      return a.blockIndex.compareTo(b.blockIndex);
    return a.offset.compareTo(b.offset);
  }

  (MarkdownPosition, MarkdownPosition) _ordered(MarkdownSelection sel) =>
      _compare(sel.base, sel.extent) <= 0
          ? (sel.base, sel.extent)
          : (sel.extent, sel.base);
}

/// Coordinates several controllers (and external selectables) so that at most
/// one has an active selection at a time. Pass the same group
/// to each controller; when one starts a (non-collapsed) selection the others
/// are cleared. Call [clearExternal] when a non-Markdown selectable (e.g. a
/// plain `SelectableText` / `SelectionArea`) begins its own selection.
class MarkdownSelectionGroup {
  final Set<MarkdownSelectionController> _members =
      <MarkdownSelectionController>{};

  void _add(MarkdownSelectionController controller) => _members.add(controller);

  void _remove(MarkdownSelectionController controller) =>
      _members.remove(controller);

  void _claim(MarkdownSelectionController owner) {
    for (final member in _members) {
      if (!identical(member, owner)) member.clear();
    }
  }

  /// Clears the selection of every member controller in this group.
  void clearExternal() {
    for (final member in _members) member.clear();
  }
}
