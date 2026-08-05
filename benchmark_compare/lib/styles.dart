/// Shared, normalized styling so all three libraries render the corpus with the
/// same base text style, the same heading sizes and matched block spacing. This
/// removes layout *density* as a variable from the render/raster comparison —
/// the whole point being that a more compact renderer otherwise rasterizes more
/// content per frame (see RESULTS.md).
///
/// The key lever is an explicit line `height`: when set, every line box is
/// `fontSize * height`, independent of the font's own metrics — so the three
/// libraries (and the headless-test vs profile-desktop environments) all lay
/// text out at the same vertical rhythm.
///
/// Structural chrome that each library draws its own way — code-block frames,
/// table borders, list bullets/indents, gpt_markdown's code header — cannot be
/// unified through public style APIs and is left as-is; it is called out in the
/// height report.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as fm;
import 'package:flutter_md/flutter_md.dart' as fmd;
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Base body text: identical for all three libraries.
const double kFontSize = 14;
const double kLineHeight = 1.4;
const Color kTextColor = Color(0xFF000000);

const TextStyle kBaseTextStyle = TextStyle(
  fontSize: kFontSize,
  height: kLineHeight,
  color: kTextColor,
);

/// Heading sizes mirror flutter_md's scheme: base + {10, 8, 6, 4, 2, 0}, bold.
/// Index 0 == h1 … index 5 == h6.
const List<double> _headingSizes = <double>[24, 22, 20, 18, 16, 14];

TextStyle _heading(int levelIndex) => kBaseTextStyle.copyWith(
      fontSize: _headingSizes[levelIndex],
      fontWeight: FontWeight.bold,
    );

/// Monospace body used for code, sized like the base text (no 0.85 shrink).
final TextStyle _monospace = kBaseTextStyle.copyWith(fontFamily: 'monospace');

/// Block gap: flutter_md inserts a spacer `fontSize` px tall per blank line, so
/// we match that for the libraries that expose a block-spacing knob.
const double kBlockSpacing = kFontSize;

/// flutter_md theme.
fmd.MarkdownThemeData flutterMdTheme() => fmd.MarkdownThemeData(
      textStyle: kBaseTextStyle,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

/// flutter_markdown style sheet. Starts from `fromTheme` (so every derived
/// style — em/strong/del/a/checkbox — exists and stays a delta merged onto the
/// base) and overrides the size/spacing-driving fields to match.
fm.MarkdownStyleSheet flutterMarkdownStyle(BuildContext context) =>
    fm.MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: kBaseTextStyle,
      h1: _heading(0),
      h2: _heading(1),
      h3: _heading(2),
      h4: _heading(3),
      h5: _heading(4),
      h6: _heading(5),
      code: _monospace,
      blockquote: kBaseTextStyle,
      listBullet: kBaseTextStyle,
      tableBody: kBaseTextStyle,
      tableHead: kBaseTextStyle.copyWith(fontWeight: FontWeight.bold),
      blockSpacing: kBlockSpacing,
      textScaler: TextScaler.noScaling,
    );

/// gpt_markdown theme override (headings matched to the shared scheme). The base
/// body style is passed to `GptMarkdown(style: kBaseTextStyle)` separately.
GptMarkdownThemeData gptMarkdownTheme(BuildContext context) =>
    GptMarkdownThemeData(
      brightness: Theme.of(context).brightness,
      h1: _heading(0),
      h2: _heading(1),
      h3: _heading(2),
      h4: _heading(3),
      h5: _heading(4),
      h6: _heading(5),
    );

/// The three library widgets, each built from `source` with the normalized
/// styles above. gpt_markdown needs a [BuildContext] for its inherited theme,
/// so every factory takes one (the others ignore it).
typedef StyledFactory = Widget Function(BuildContext context, String source);

final Map<String, StyledFactory> styledLibraries = <String, StyledFactory>{
  'flutter_md': (context, src) => fmd.MarkdownWidget(
        markdown: fmd.Markdown.fromString(src),
        theme: flutterMdTheme(),
      ),
  'flutter_markdown': (context, src) => fm.MarkdownBody(
        data: src,
        styleSheet: flutterMarkdownStyle(context),
        extensionSet: md.ExtensionSet.gitHubFlavored,
        shrinkWrap: true,
      ),
  'gpt_markdown': (context, src) => GptMarkdownTheme(
        gptThemeData: gptMarkdownTheme(context),
        child: GptMarkdown(src, style: kBaseTextStyle),
      ),
};
