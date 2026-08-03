// Tests for the opt-in inline LaTeX math feature
// (`MarkdownDecoder(inlineMath: true)`).
//
// Math is disabled by default (see regression_test.dart for the off-by-default
// behaviour); this file exercises the enabled path: command substitution,
// super/subscripts, code protection, escaping, and configurability.
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// A decoder with inline math enabled.
const MarkdownDecoder _math = MarkdownDecoder(inlineMath: true);

/// Concatenated span text of the first paragraph, using [decoder].
String _render(String input, [MarkdownDecoder decoder = _math]) {
  final blocks = decoder.convert(input).blocks;
  final paragraph = blocks.whereType<MD$Paragraph>().first;
  return paragraph.spans.map((s) => s.text).join();
}

List<MD$Span> _spans(String input, [MarkdownDecoder decoder = _math]) =>
    (decoder.convert(input).blocks.first as MD$Paragraph).spans;

void main() {
  group('Commands', () {
    test('single greek command', () {
      expect(_render(r'$\alpha$'), 'α');
    });

    test('command within a sentence', () {
      expect(_render(r'A $\rightarrow$ B'), 'A → B');
    });

    test('multiple commands in one expression', () {
      expect(_render(r'$\alpha + \beta \leq \gamma$'), 'α + β ≤ γ');
    });

    test('newly added symbols convert', () {
      expect(_render(r'$\implies$'), '⟹');
      expect(_render(r'$\perp$'), '⊥');
      expect(_render(r'$\oplus$'), '⊕');
      expect(_render(r'$\hbar$'), 'ℏ');
      expect(_render(r'$\therefore$'), '∴');
    });

    test('unknown command is left literal', () {
      expect(_render(r'$\foobar$'), r'$\foobar$');
    });

    test('two separate math spans on one line', () {
      expect(_render(r'$\alpha$ and $\beta$'), 'α and β');
    });
  });

  group('Superscripts and subscripts', () {
    test('single-digit superscript', () {
      expect(_render(r'$x^2$'), 'x²');
    });

    test('single-digit subscript', () {
      expect(_render(r'$x_1$'), 'x₁');
    });

    test('water formula', () {
      expect(_render(r'$H_2O$'), 'H₂O');
    });

    test('braced multi-digit superscript', () {
      expect(_render(r'$x^{10}$'), 'x¹⁰');
    });

    test('braced multi-char subscript', () {
      expect(_render(r'$a_{12}$'), 'a₁₂');
    });

    test('subscript letter i', () {
      expect(_render(r'$a_i$'), 'aᵢ');
    });

    test('superscript with sign', () {
      expect(_render(r'$x^{-1}$'), 'x⁻¹');
    });

    test('combined with a command', () {
      expect(_render(r'$\alpha^2$'), 'α²');
    });

    test('unmappable script char is left literal', () {
      // `z` has no subscript form, so the run stays verbatim.
      expect(_render(r'$q_z$'), r'$q_z$');
    });

    test('superscript letter n', () {
      expect(_render(r'$2^n$'), '2ⁿ');
    });

    test('unterminated brace group is left literal', () {
      expect(_render(r'$x^{2$'), r'$x^{2$');
    });
  });

  group('Code is protected', () {
    test('inline code span is never converted', () {
      final span = _spans(r'`$\alpha$`').single;
      expect(span.text, r'$\alpha$');
      expect(span.style, MD$Style.monospace);
    });

    test('text around code is still converted', () {
      final rendered =
          _spans(r'$\alpha$ `$\beta$` $\gamma$').map((s) => s.text).join();
      expect(rendered, r'α $\beta$ γ');
    });

    test('fenced code block is never converted', () {
      final code =
          _math.convert('```\n\$\\alpha\$\n```').blocks.single as MD$Code;
      expect(code.text, r'$\alpha$');
    });
  });

  group('Dollars that must not convert', () {
    test('currency is untouched even with math on', () {
      expect(_render(r'I have $5 and $10 left'), r'I have $5 and $10 left');
    });

    test('a single dollar is untouched', () {
      expect(_render(r'costs $5 total'), r'costs $5 total');
    });

    test('non-command dollar span is untouched', () {
      expect(_render(r'$x$'), r'$x$');
    });

    test(r'escaped \$ is a literal dollar and blocks math', () {
      expect(_render(r'price \$5'), r'price $5');
      expect(_render(r'\$\alpha\$'), r'$\alpha$');
    });
  });

  group('Configurability', () {
    test('Markdown.fromString gates math behind the flag', () {
      expect(Markdown.fromString(r'$\alpha$').text, r'$\alpha$');
      expect(Markdown.fromString(r'$\alpha$', inlineMath: true).text, 'α');
    });

    test('custom replacements replace the defaults', () {
      const decoder = MarkdownDecoder(
        inlineMath: true,
        mathReplacements: {r'\R': 'ℝ'},
      );
      expect(_render(r'$\R$', decoder), 'ℝ');
      // A default command is no longer known with a fully custom table.
      expect(_render(r'$\alpha$', decoder), r'$\alpha$');
    });

    test('extending the defaults keeps them working', () {
      const decoder = MarkdownDecoder(
        inlineMath: true,
        mathReplacements: {...kMarkdownMathCommands, r'\R': 'ℝ'},
      );
      expect(_render(r'$\R$', decoder), 'ℝ');
      expect(_render(r'$\alpha$', decoder), 'α');
    });

    test('kMarkdownMathCommands is non-empty and contains greek', () {
      expect(kMarkdownMathCommands, isNotEmpty);
      expect(kMarkdownMathCommands[r'\alpha'], 'α');
    });
  });

  group('Span integrity with math on', () {
    test('converted math still yields well-formed spans', () {
      for (final input in const [
        r'$\alpha$ + $\beta$ = result',
        r'water is $H_2O$ here',
        r'x equals $x^{2}$ today',
      ]) {
        final spans = _spans(input);
        for (var i = 0; i < spans.length; i++) {
          expect(spans[i].start, lessThanOrEqualTo(spans[i].end),
              reason: input);
          if (i > 0) {
            expect(spans[i].start, greaterThanOrEqualTo(spans[i - 1].start),
                reason: input);
          }
        }
      }
    });
  });
}
