library;

export 'src/image.dart';
export 'src/markdown.dart';
export 'src/nodes.dart';
export 'src/parser.dart';
export 'src/render.dart'
    show
        // Block-painter framework — implement/extend to customize rendering.
        BlockPainter,
        SelectableBlockPainter,
        SelectableTextBlock,
        MultiPainterSelectable,
        SelectableFragment,
        ParagraphGestureHandler,
        paragraphFromMarkdownSpans,
        // Inline images — lay out / paint text that may hold pictures.
        MarkdownImageSpan,
        layoutMarkdownText,
        paintMarkdownText,
        // Default block painters — reuse, wrap or subclass them.
        BlockPainter$Paragraph,
        BlockPainter$Heading,
        BlockPainter$Quote,
        BlockPainter$Alert,
        BlockPainter$Code,
        BlockPainter$List,
        BlockPainter$Table,
        BlockPainter$Divider,
        BlockPainter$Spacer;
export 'src/highlight/engine.dart' show CodeHighlightTheme, SyntaxHighlighter;
export 'src/selection.dart';
export 'src/selection_autoscroll.dart'
    show
        MarkdownAutoscrollRequest,
        MarkdownAutoscrollTarget,
        MarkdownAutoscrollTargetResolver,
        MarkdownAutoscrollViewport,
        MarkdownCallbackAutoscrollTarget,
        MarkdownScrollableAutoscrollTarget,
        MarkdownSelectionAutoscrollConfig;
export 'src/selection_scope.dart';
export 'src/theme.dart';
export 'src/widget.dart';
