/// Tree-shakeable syntax highlighting for fenced code blocks.
///
/// Import this entrypoint for the engine and the [MarkdownHighlighter], then
/// one small library per language you use (e.g. `highlight/dart.dart`).
/// Languages you never import are dropped by the compiler.
///
/// ```dart
/// import 'package:flutter_md/highlight.dart';
/// import 'package:flutter_md/highlight/dart.dart';
/// import 'package:flutter_md/highlight/themes.dart';
///
/// final theme = MarkdownThemeData(
///   textStyle: const TextStyle(),
///   highlighter: MarkdownHighlighter(
///     languages: {'dart': HighlightDart.grammar},
///     theme: HighlightThemes.githubDark,
///   ),
/// );
/// ```
library;

export 'src/highlight/engine.dart';
