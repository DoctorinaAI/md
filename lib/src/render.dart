/// Rendering layer for `flutter_md`.
///
/// The block-painter framework, the default block painters, and the render
/// object / painter that drive them live under `render/`. This file re-exports
/// them so existing imports of `src/render.dart` keep resolving unchanged.
library;

export 'render/block_painter.dart';
export 'render/markdown_painter.dart';
export 'render/markdown_render_object.dart';
export 'render/span_builder.dart';

export 'render/blocks/alert.dart';
export 'render/blocks/code.dart';
export 'render/blocks/divider.dart';
export 'render/blocks/heading.dart';
export 'render/blocks/list.dart';
export 'render/blocks/paragraph.dart';
export 'render/blocks/quote.dart';
export 'render/blocks/spacer.dart';
export 'render/blocks/table.dart';
