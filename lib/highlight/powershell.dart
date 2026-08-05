// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `powershell`.
///
/// Import this library only when you need `powershell` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightPowershell {
  /// The grammar for `powershell`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("(^|[^`])<#[\\s\\S]*?#>"),
      lookbehind: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^`])#.*"),
      lookbehind: true),
  GrammarToken("string", compileHighlightPattern("\"(?:`[\\s\\S]|[^`\"])*\""),
      greedy: true, inside: () => _g1),
  GrammarToken("string", compileHighlightPattern("'(?:[^']|'')*'"),
      greedy: true),
  GrammarToken(
      "namespace",
      compileHighlightPattern(
          "\\[[a-z](?:\\[(?:\\[[^\\]]*\\]|[^\\[\\]])*\\]|[^\\[\\]])*\\]",
          caseSensitive: false)),
  GrammarToken("boolean",
      compileHighlightPattern("\\\$(?:false|true)\\b", caseSensitive: false)),
  GrammarToken("variable", compileHighlightPattern("\\\$\\w+\\b")),
  GrammarToken(
      "function",
      compileHighlightPattern(
          "\\b(?:Add|Approve|Assert|Backup|Block|Checkpoint|Clear|Close|Compare|Complete|Compress|Confirm|Connect|Convert|ConvertFrom|ConvertTo|Copy|Debug|Deny|Disable|Disconnect|Dismount|Edit|Enable|Enter|Exit|Expand|Export|Find|ForEach|Format|Get|Grant|Group|Hide|Import|Initialize|Install|Invoke|Join|Limit|Lock|Measure|Merge|Move|New|Open|Optimize|Out|Ping|Pop|Protect|Publish|Push|Read|Receive|Redo|Register|Remove|Rename|Repair|Request|Reset|Resize|Resolve|Restart|Restore|Resume|Revoke|Save|Search|Select|Send|Set|Show|Skip|Sort|Split|Start|Step|Stop|Submit|Suspend|Switch|Sync|Tee|Test|Trace|Unblock|Undo|Uninstall|Unlock|Unprotect|Unpublish|Unregister|Update|Use|Wait|Watch|Where|Write)-[a-z]+\\b",
          caseSensitive: false)),
  GrammarToken(
      "function",
      compileHighlightPattern(
          "\\b(?:ac|cat|chdir|clc|cli|clp|clv|compare|copy|cp|cpi|cpp|cvpa|dbp|del|diff|dir|ebp|echo|epal|epcsv|epsn|erase|fc|fl|ft|fw|gal|gbp|gc|gci|gcs|gdr|gi|gl|gm|gp|gps|group|gsv|gu|gv|gwmi|iex|ii|ipal|ipcsv|ipsn|irm|iwmi|iwr|kill|lp|ls|measure|mi|mount|move|mp|mv|nal|ndr|ni|nv|ogv|popd|ps|pushd|pwd|rbp|rd|rdr|ren|ri|rm|rmdir|rni|rnp|rp|rv|rvpa|rwmi|sal|saps|sasv|sbp|sc|select|set|shcm|si|sl|sleep|sls|sort|sp|spps|spsv|start|sv|swmi|tee|trcm|type|write)\\b",
          caseSensitive: false)),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:Begin|Break|Catch|Class|Continue|Data|Define|Do|DynamicParam|Else|ElseIf|End|Exit|Filter|Finally|For|ForEach|From|Function|If|InlineScript|Parallel|Param|Process|Return|Sequence|Switch|Throw|Trap|Try|Until|Using|Var|While|Workflow)\\b",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "(^|\\W)(?:!|-(?:b?(?:and|x?or)|as|(?:Not)?(?:Contains|In|Like|Match)|eq|ge|gt|is(?:Not)?|Join|le|lt|ne|not|Replace|sh[lr])\\b|-[-=]?|\\+[+=]?|[*\\/%]=?)",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken("punctuation", compileHighlightPattern("[|{}[\\];(),.]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "function",
      compileHighlightPattern(
          "(^|[^`])\\\$\\((?:\\\$\\([^\\r\\n()]*\\)|(?!\\\$\\()[^\\r\\n)])*\\)"),
      lookbehind: true,
      inside: () => _g0),
  GrammarToken("boolean",
      compileHighlightPattern("\\\$(?:false|true)\\b", caseSensitive: false)),
  GrammarToken("variable", compileHighlightPattern("\\\$\\w+\\b")),
]);
