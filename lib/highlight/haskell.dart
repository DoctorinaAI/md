// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `haskell`.
///
/// Import this library only when you need `haskell` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightHaskell {
  /// The grammar for `haskell`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "(^|[^-!#\$%*+=?&@|~.:<>^\\\\\\/])(?:--(?:(?=.)[^-!#\$%*+=?&@|~.:<>^\\\\\\/].*|\$)|\\{-[\\s\\S]*?-\\})",
          multiLine: true),
      lookbehind: true),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:[^\\\\']|\\\\(?:[abfnrtv\\\\\"'&]|\\^[A-Z@[\\]^_]|ACK|BEL|BS|CAN|CR|DC1|DC2|DC3|DC4|DEL|DLE|EM|ENQ|EOT|ESC|ETB|ETX|FF|FS|GS|HT|LF|NAK|NUL|RS|SI|SO|SOH|SP|STX|SUB|SYN|US|VT|\\d+|o[0-7]+|x[0-9a-fA-F]+))'"),
      alias: "string"),
  GrammarToken("string",
      compileHighlightPattern("\"(?:[^\\\\\"]|\\\\(?:\\S|\\s+\\\\))*\""),
      greedy: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:case|class|data|deriving|do|else|if|in|infixl|infixr|instance|let|module|newtype|of|primitive|then|type|where)\\b")),
  GrammarToken(
      "import-statement",
      compileHighlightPattern(
          "(^[\\t ]*)import\\s+(?:qualified\\s+)?(?:[A-Z][\\w']*)(?:\\.[A-Z][\\w']*)*(?:\\s+as\\s+(?:[A-Z][\\w']*)(?:\\.[A-Z][\\w']*)*)?(?:\\s+hiding\\b)?",
          multiLine: true),
      lookbehind: true,
      inside: () => _g1),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "\\b(?:abs|acos|acosh|all|and|any|appendFile|approxRational|asTypeOf|asin|asinh|atan|atan2|atanh|basicIORun|break|catch|ceiling|chr|compare|concat|concatMap|const|cos|cosh|curry|cycle|decodeFloat|denominator|digitToInt|div|divMod|drop|dropWhile|either|elem|encodeFloat|enumFrom|enumFromThen|enumFromThenTo|enumFromTo|error|even|exp|exponent|fail|filter|flip|floatDigits|floatRadix|floatRange|floor|fmap|foldl|foldl1|foldr|foldr1|fromDouble|fromEnum|fromInt|fromInteger|fromIntegral|fromRational|fst|gcd|getChar|getContents|getLine|group|head|id|inRange|index|init|intToDigit|interact|ioError|isAlpha|isAlphaNum|isAscii|isControl|isDenormalized|isDigit|isHexDigit|isIEEE|isInfinite|isLower|isNaN|isNegativeZero|isOctDigit|isPrint|isSpace|isUpper|iterate|last|lcm|length|lex|lexDigits|lexLitChar|lines|log|logBase|lookup|map|mapM|mapM_|max|maxBound|maximum|maybe|min|minBound|minimum|mod|negate|not|notElem|null|numerator|odd|or|ord|otherwise|pack|pi|pred|primExitWith|print|product|properFraction|putChar|putStr|putStrLn|quot|quotRem|range|rangeSize|read|readDec|readFile|readFloat|readHex|readIO|readInt|readList|readLitChar|readLn|readOct|readParen|readSigned|reads|readsPrec|realToFrac|recip|rem|repeat|replicate|return|reverse|round|scaleFloat|scanl|scanl1|scanr|scanr1|seq|sequence|sequence_|show|showChar|showInt|showList|showLitChar|showParen|showSigned|showString|shows|showsPrec|significand|signum|sin|sinh|snd|sort|span|splitAt|sqrt|subtract|succ|sum|tail|take|takeWhile|tan|tanh|threadToIOResult|toEnum|toInt|toInteger|toLower|toRational|toUpper|truncate|uncurry|undefined|unlines|until|unwords|unzip|unzip3|userError|words|writeFile|zip|zip3|zipWith|zipWith3)\\b")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b(?:\\d+(?:\\.\\d+)?(?:e[+-]?\\d+)?|0o[0-7]+|0x[0-9a-f]+)\\b",
          caseSensitive: false)),
  GrammarToken("operator",
      compileHighlightPattern("`(?:[A-Z][\\w']*\\.)*[_a-z][\\w']*`"),
      greedy: true),
  GrammarToken("operator", compileHighlightPattern("(\\s)\\.(?=\\s)"),
      lookbehind: true),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "[-!#\$%*+=?&@|~:<>^\\\\\\/][-!#\$%*+=?&@|~.:<>^\\\\\\/]*|\\.[-!#\$%*+=?&@|~.:<>^\\\\\\/]+")),
  GrammarToken("hvariable",
      compileHighlightPattern("\\b(?:[A-Z][\\w']*\\.)*[_a-z][\\w']*"),
      inside: () => _g2),
  GrammarToken("constant",
      compileHighlightPattern("\\b(?:[A-Z][\\w']*\\.)*[A-Z][\\w']*"),
      inside: () => _g3),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("keyword",
      compileHighlightPattern("\\b(?:as|hiding|import|qualified)\\b")),
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);

final Grammar _g2 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);

final Grammar _g3 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);
