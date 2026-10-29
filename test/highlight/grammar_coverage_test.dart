// Feature-dense, realistic samples per bundled grammar.
//
// Nested `inside:` grammars are only built when the tokenizer actually hits a
// matching token, so a trivial sample leaves most of a grammar unexercised.
// Each sample below deliberately reaches the nested constructs of its language
// (interpolation, embedded languages, attributes, heredocs, …) and checks
// that highlighting stays lossless and that the expected tokens get colored.
import 'package:flutter/painting.dart';
import 'package:flutter_md/highlight.dart';
import 'package:flutter_md/highlight/all.dart';
import 'package:flutter_md/highlight/themes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flattens a span tree into (text, effectiveStyle) fragments.
List<(String, TextStyle)> _fragments(InlineSpan span) {
  final out = <(String, TextStyle)>[];
  void walk(InlineSpan node, TextStyle acc) {
    if (node is! TextSpan) return;
    final merged = node.style == null ? acc : acc.merge(node.style);
    final text = node.text;
    if (text != null && text.isNotEmpty) out.add((text, merged));
    for (final child in node.children ?? const <InlineSpan>[]) {
      walk(child, merged);
    }
  }

  walk(span, const TextStyle());
  return out;
}

/// A code sample and the fragments that must end up colored.
typedef _Sample = ({String source, List<String> colored});

const _base = TextStyle(fontFamily: 'monospace', fontSize: 14);

final Map<String, _Sample> _samples = <String, _Sample>{
  'apacheconf': (
    source: r'''
# Main server config
ServerRoot "/etc/httpd"
Listen 80
LoadModule rewrite_module modules/mod_rewrite.so
<VirtualHost *:80>
    ServerName example.com
    DocumentRoot "/var/www/html"
    RewriteEngine On
    RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]
    RewriteRule ^(.*)$ http://%1/$1 [R=301,L]
    <Directory "/var/www/html">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/error.log
</VirtualHost>
<IfModule mod_ssl.c>
    SSLEngine on
</IfModule>
''',
    colored: ['ServerRoot', 'Listen', '"/etc/httpd"'],
  ),
  'bash': (
    source: r'''
#!/usr/bin/env bash
set -euo pipefail
# Deploy script
readonly NAME="world"
declare -a items=(one two three)
export PATH="$HOME/bin:${PATH}"
function greet() {
  local who="${1:-$NAME}"
  echo "Hello, ${who^^}! Today is $(date +%A) and `whoami`"
  printf '%s\n' "$((1 + 2 * 3))"
}
greet "$@"
if [[ -f "$file" && $count -gt 3 ]]; then
  echo 'single $not expanded'
elif [ "$x" == "y" ]; then
  echo $'ansi\tc\n'
else
  : "${VAR:?missing}"
fi
for i in {1..5}; do echo "$i"; done
while read -r line; do echo "$line"; done < input.txt
case "$1" in
  start|run) echo start ;;
  *) echo "usage" >&2; exit 1 ;;
esac
cat <<EOF
Heredoc with $NAME and $(pwd)
EOF
cat <<'RAW'
No $expansion here
RAW
cat <<-"QUOTED"
	tabbed $x
	QUOTED
arr[0]=x
echo ${#arr[@]} $? $$ $! $0 $_
ls -la /tmp | grep -v '^d' 2>/dev/null && echo ok || true
VAR=1 cmd --flag=value
sudo apt-get install -y curl
x=$(( 0x1F + 077 + 2#101 ))
''',
    colored: ['#!/usr/bin/env bash', 'echo', 'if'],
  ),
  'batch': (
    source: r'''
@echo off
:: comment line
rem another comment
setlocal enabledelayedexpansion
set "NAME=world"
set /a COUNT=%COUNT% + 1
set /p INPUT=Enter value:
if exist "%~dp0config.ini" (
    echo Found config for %NAME%
) else if /i "%1"=="help" (
    goto :usage
) else (
    echo !COUNT! items
)
if not defined NAME set NAME=default
if %ERRORLEVEL% neq 0 exit /b 1
for /f "tokens=1,2 delims=," %%a in (data.csv) do (
    echo %%a - %%b
)
for %%i in (*.txt) do echo %%i
for /l %%n in (1,1,10) do @echo %%n
call :sub arg1 "arg 2"
goto :eof
:usage
echo Usage: %0 [options] > nul 2>&1
:sub
echo %~1 %~2
exit /b 0
''',
    colored: ['echo', 'set', 'if'],
  ),
  'c': (
    source: r'''
#include <stdio.h>
#include "local.h"
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define VERSION "1.0"
#ifdef DEBUG
#  pragma once
#endif
/* Block comment */
typedef struct point { int x, y; } point_t;
static const char *msg = "hello\n";
int main(int argc, char **argv) {
  unsigned long n = 0x1Fu + 10UL + 1.5e3f;
  char c = 'a';
  for (int i = 0; i < argc; ++i) {
    printf("%s %d\n", argv[i], MAX(i, 2));
  }
  if (n >= 10 && c != '\0') return 1;
  sizeof(point_t);
  return 0; // done
}
''',
    colored: ['#include', 'int', 'return'],
  ),
  'clike': (
    source: r'''
// line comment
/* block */
class Foo extends Bar {
  if (x == 1) { return "str" + 'c'; }
  while (true) { foo(1.5e3, 0xFF); }
  new Baz() instanceof Qux;
  a = b ? c : d;
}
''',
    colored: ['return', '"str"'],
  ),
  'clojure': (
    source: r'''
; comment
(ns my.app (:require [clojure.string :as str]))
(defn greet "Docstring" [name & {:keys [loud]}]
  (let [msg (str "Hello, " name)]
    (if loud (str/upper-case msg) msg)))
#{1 2 3} #"regex\d+" \a 'sym ~@xs @atom ^:meta
(def x 1.5M) (def y 22/7) (def z nil) true false
''',
    colored: ['defn', '"Docstring"'],
  ),
  'coffeescript': (
    source: r'''
# Comment
###
Block comment
###
class Animal extends Base
  constructor: (@name) ->
  move: (meters = 5) =>
    alert "#{@name} moved #{meters}m."
    console.log 'single #{not}'
square = (x) -> x * x
list = [1..10]
cubes = (math.cube num for num in list when num % 2 is 0)
html = """
  <div class="#{cls}">#{content}</div>
"""
'''
        r"""raw = '''
  multi 'line'
'''
"""
        r'''re = /// ^ (\d+) # digits
  \s* ///gi
small = /^[a-z\-]+(\d)\1(?<n>x)\k<n>$/i
js = `function() { return 1; }`
embedded = ```
  var x = 1;
```
obj =
  key: 'value'
  "quoted": 2
  other: yes
unless done then go() else stop()
@instance = on
x = 0b101 + 0o17 + 0xFF
''',
    colored: ['class', 'extends', '->'],
  ),
  'cpp': (
    source: r'''
#include <iostream>
#include <vector>
#define SQUARE(x) ((x) * (x))
module;
import <string>;
export module math;
import math.core;
namespace app::detail {
template <typename T, class U = std::vector<T>>
class Box final : public Base<T>, private Mixin {
public:
  explicit Box(T v) noexcept : value_{v} {}
  [[nodiscard]] constexpr auto get() const -> T { return value_; }
  virtual ~Box() override = default;
  operator bool() const { return true; }
  template <typename V> requires std::integral<V>
  friend bool operator==(const Box&, const Box&);
private:
  T value_;
};
enum class Color : std::uint8_t { Red, Green };
struct Point { int x = 0; };
struct Derived : public Base<int>, std::enable_shared_from_this<Derived> {};
concept Hashable = requires(T a) { a.hash(); };
}  // namespace app::detail
auto main() -> int {
  std::cout << R"raw(literal \n "quoted")raw" << u8"utf" << L'c' << '\n';
  auto lambda = [&, x = 1](int y) mutable { return x + y; };
  long long big = 1'000'000LL + 0x1Fu + 0b1010 + 1.5e-3f;
  std::unique_ptr<Box<int>> p = std::make_unique<Box<int>>(42);
  static_cast<double>(big); nullptr; co_await task; alignas(16) char buf[4];
  using namespace std;
  using std::string;
  if constexpr (sizeof(int) == 4) { return 0; }
  return 0;
}
''',
    colored: ['class', 'template', 'return'],
  ),
  'csharp': (
    source: r'''
using System;
using System.Collections.Generic;
using static System.Math;
using Alias = System.Text.StringBuilder;
#nullable enable
#region Models
namespace App.Models
{
    [Serializable]
    [System.Flags]
    [assembly: ComVisible(false)]
    [Range(1, 10)]
    public sealed record Person(string Name, int Age);
    public partial class Repo<T> : IRepo<T>, IDisposable where T : class, new()
    {
        private readonly List<T> _items = new List<T>();
        public event EventHandler<T>? Changed;
        public T this[int index] => _items[index];
        public async Task<IEnumerable<T>> GetAllAsync(
            CancellationToken ct = default)
        {
            var name = "world";
            var s = $"Hello {name,10:N2} and {(x > 1 ? "a" : "b")}";
            var v = $@"verbatim {name} ""quoted"" {total:N2}";
            var user = JsonSerializer.Deserialize<User>(json);
            var r = @"C:\path\file";
            var raw = """
                raw "string"
                """;
            char c = 'x';
            int n = 0xFF + 0b1010 + 1_000 + 3.14e2f + 10m + 5L;
            dynamic d = typeof(List<int>);
            if (obj is Person { Age: > 18 } p && p.Name is not null) { }
            await Task.Delay(100, ct).ConfigureAwait(false);
            Func<int, int> sq = x => x * x;
            nameof(GetAllAsync); default(T); sizeof(int);
            return _items.Where(i => i != null).ToList() as IEnumerable<T>;
        }
        // single line
        /* multi
           line */
        /// <summary>Doc comment</summary>
        public static explicit operator int(Repo<T> r) => 0;
    }
}
#endregion
''',
    colored: ['using', 'class', 'public'],
  ),
  'css': (
    source: r'''
@charset "utf-8";
@import url("theme.css") screen and (min-width: 600px);
@media (max-width: 768px) and (orientation: landscape) {
  .nav > li:not(.active)::before { content: "\201C"; }
}
@supports (display: grid) { .grid { display: grid; } }
@font-face { font-family: "Inter"; src: url(inter.woff2) format("woff2"); }
:root { --main-color: #ff0000; --gap: calc(1rem + 2px); }
/* comment */
#id.class[data-x="1"], a:hover, input[type=text] {
  color: var(--main-color) !important;
  background: url(img.png) no-repeat,
    linear-gradient(to right, #fff 0%, rgba(0,0,0,.5) 100%);
  margin: -1.5em auto 0 10px;
  transform: rotate(45deg) translateX(10%);
}
@keyframes spin { from { opacity: 0; } to { opacity: 1; } }
''',
    colored: ['@media', 'color', '#id.class'],
  ),
  'dart': (
    source: r'''
// comment
/// Doc comment
import 'package:flutter/material.dart' as m show Widget;
part of 'lib.dart';
@immutable
@JsonSerializable(explicitToJson: true)
abstract class Repo<T extends Object?> with Mixin implements Base {
  static const int max = 0xFF;
  late final String name = "hi $world and ${a.b + c}";
  final raw = r'raw $not';
  final multi = """
    multi ${line}
  """;
'''
        r"""  final single = '''
    another $x
  ''';
"""
        r'''  Future<List<T>> load({required int id}) async {
    await for (final x in stream) yield* x;
    return <T>[];
  }
  external factory Repo.named();
  operator ==(Object other) => other is Repo && other.name == name;
  num n = 1.5e3 + 42;
  final m.Widget child = m.Text('x');
  bool? flag = null ?? true;
  void f() => print(#symbol);
  typedef Cb = void Function(int);
}
''',
    colored: ['class', 'import', 'final'],
  ),
  'diff': (
    source: r'''
diff --git a/lib/foo.dart b/lib/foo.dart
index 1234567..89abcde 100644
--- a/lib/foo.dart
+++ b/lib/foo.dart
@@ -1,7 +1,8 @@ class Foo
 unchanged context line
-removed line
+added line
+another added line
! changed line
< left side
> right side
*** 1,3 ****
--- 1,3 ----
 context
- deleted
+ inserted
@@ -20 +21 @@
-a
+b
\ No newline at end of file
1a2
3,4d5
5c6
''',
    colored: [],
  ),
  'docker': (
    source: r'''
# syntax=docker/dockerfile:1
ARG BASE=node:20-alpine
FROM --platform=$BUILDPLATFORM ${BASE} AS build
LABEL maintainer="dev@example.com" version="1.0"
ENV NODE_ENV=production \
    PORT=3000
WORKDIR /app
COPY --chown=node:node --from=deps package*.json ./
RUN npm ci --omit=dev \
    # inline comment
    && npm cache clean --force
RUN ["sh", "-c", "echo $HOME"]
EXPOSE 3000/tcp
VOLUME ["/data"]
USER node
HEALTHCHECK --interval=30s --timeout="5s" --retries='3' \
  CMD curl -f http://localhost:3000/health || exit 1
HEALTHCHECK NONE
ONBUILD COPY . /app/src
ONBUILD RUN make
SHELL ["/bin/bash", "-c"]
STOPSIGNAL SIGTERM
ENTRYPOINT ["node", "server.js"]
CMD ["--port", "3000"]
FROM scratch AS final
''',
    colored: ['FROM', 'RUN', 'HEALTHCHECK'],
  ),
  'elixir': (
    source: r'''
# comment
defmodule MyApp.User do
  @moduledoc """
  Documentation with #{interp}
  """
  @doc ~S"""
  Raw sigil doc
  """
  use Ecto.Schema
  import Ecto.Changeset, only: [cast: 3]
  alias MyApp.{Repo, Account}
  @default_age 18
  defstruct name: nil, age: @default_age
  def greet(%{name: name} = user, opts \\ []) when is_binary(name) do
    msg = "Hello, #{name}! You are #{user.age + 1}"
    re = ~r/^\w+@\w+\.com$/i
    words = ~w(foo bar baz)a
    chars = 'charlist'
    atom = :ok
    quoted = :"quoted atom"
    map = %{key: "v", "str" => 1, 0x1F => 2.5e3}
    tuple = {:error, 0b1010, 0o17, 1_000}
    list = [1, 2 | rest]
    fun = &String.upcase/1
    pipeline = name |> String.trim() |> String.downcase()
    case opts[:mode] do
      :loud -> IO.puts(String.upcase(msg))
      _ -> IO.puts(msg)
    end
    plain = """
    plain heredoc text
    """
    ?a
  end
  defp private_fun, do: :ok
  defmacro my_macro(ast), do: quote(do: unquote(ast))
end
''',
    colored: ['defmodule', 'def', ':ok'],
  ),
  'elm': (
    source: r'''
module Main exposing (main, Model, Msg(..))
import Html exposing (Html, div, text)
import Html.Attributes as A
-- line comment
{- block comment -}
type alias Model = { count : Int, name : String }
type Msg = Increment | Decrement
update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment -> { model | count = model.count + 1 }
        Decrement -> { model | count = model.count - 1 }
view model = div [] [ text ("Count: " ++ String.fromInt model.count) ]
c = 'x'
s = """multi
line"""
n = 0x1F + 3.14 + 1e3
f = \x -> x * 2 |> identity
port sendMessage : String -> Cmd msg
''',
    colored: ['module', 'import', 'case'],
  ),
  'erlang': (
    source: r'''
%% comment
-module(hello).
-export([start/0, loop/1]).
-define(TIMEOUT, 5000).
-record(state, {count = 0 :: integer()}).
start() ->
    Pid = spawn(fun() -> loop(#state{}) end),
    Pid ! {self(), "hello", 'quoted atom', $a, 16#FF, 2.5e3},
    receive
        {ok, Msg} when is_list(Msg) -> io:format("~p~n", [Msg]);
        _ -> ok
    after ?TIMEOUT -> timeout
    end.
loop(S = #state{count = C}) -> loop(S#state{count = C + 1}).
''',
    colored: ['receive', '"hello"'],
  ),
  'fsharp': (
    source: r'''
// line comment
(* block comment *)
/// doc comment
module App.Main
open System
#if DEBUG
#nowarn "40"
#endif
[<EntryPoint>]
[<Literal>]
let main argv =
    let name = "world"
    let s = $"Hello {name}!"
    let v = @"verbatim \ path"
    let t = """triple "quoted" """
    let c = 'c'
    let b = "bytes"B
    let n = 0x1F + 0b101 + 1_000 + 3.14e2 + 10uy + 5L + 2.0m
    let rec fib n = if n < 2 then n else fib (n - 1) + fib (n - 2)
    let opt : int option = Some 1
    match opt with
    | Some x when x > 0 -> printfn "%d" x
    | _ -> ()
    let comp = async { let! x = getAsync () in return x }
    let record = { Name = "a"; Age = 1 }
    let lst = [ 1 .. 10 ] |> List.map (fun x -> x * x)
    let arr = [| 1; 2 |]
    type Shape = Circle of float | Square of float
    0
''',
    colored: ['let', 'match', '"world"'],
  ),
  'git': (
    source: r'''
$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   README.md
# Please enter the commit message
$ git log -n 1 --oneline
commit a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0
Author: Jane Doe <jane@example.com>
Date:   Mon Jan 1 12:00:00 2024 +0000

    Initial commit
diff --git a/file.txt b/file.txt
@@ -1 +1 @@
-old
+new
''',
    colored: ['# Please enter the commit message'],
  ),
  'go': (
    source: r'''
// Package main does things.
package main
import (
  "fmt"
  str "strings"
)
/* block */
type Point struct { X, Y int `json:"x"` }
func (p *Point) Add(o Point) Point { return Point{p.X + o.X, p.Y + o.Y} }
func main() {
  ch := make(chan int, 10)
  go func() { ch <- 0x1F; close(ch) }()
  defer fmt.Println("done", 'r', 1.5e3, 3i, nil, true)
  for i := range ch { if i > 0 { continue } }
  select { case v := <-ch: _ = v; default: }
  var m map[string]interface{} = nil
  raw := `raw\n`
}
''',
    colored: ['func', 'package', '"fmt"'],
  ),
  'graphql': (
    source: r'''
# comment
query GetUser($id: ID!, $withPosts: Boolean = false) @cached(ttl: 60) {
  user(id: $id) {
    ...UserFields
    posts(first: 10) @include(if: $withPosts) {
      edges { node { id title } }
    }
  }
}
fragment UserFields on User { id name email }
mutation {
  createUser(input: {name: "Ann", age: 3, score: 1.5e2,
    active: true, role: ADMIN, tags: null}) { id }
}
"""
Block description
"""
type User implements Node & Entity {
  "Field description"
  id: ID!
  posts(first: Int): [Post!]!
}
enum Role { ADMIN USER }
input UserInput { name: String! }
scalar DateTime
directive @cached(ttl: Int) on FIELD_DEFINITION
schema { query: Query mutation: Mutation }
extend type Query { me: User }
interface Node { id: ID! }
union SearchResult = User | Post
subscription OnEvent { event { id } }
''',
    colored: ['query', 'fragment', 'mutation'],
  ),
  'groovy': (
    source: r'''
#!/usr/bin/env groovy
// comment
@Grab('org.foo:bar:1.0')
import groovy.transform.*
class Person {
  String name
  def greet() { "Hello, ${name.toUpperCase()} and $name" }
}
def p = new Person(name: 'Ann')
def gs = """multi ${p.name} line"""
'''
        r"""def sq = '''single 'multi' '''
"""
        r'''def slashy = /regex\d+/
def dollar = $/dollar slashy $x/$
def list = [1, 2, 3].collect { it * 2 }
def map = [a: 1, b: 0x1F, c: 1.5e3G, d: 10L]
assert list.size() == 3
p?.name ?: 'default'
list*.toString()
def range = 1..<10
println "done"
''',
    colored: ['class', 'def', 'import'],
  ),
  'handlebars': (
    source: r'''
<div class="entry">
  {{!-- block comment --}}
  {{! short comment }}
  <h1>{{title}}</h1>
  {{#if author}}
    <p>{{author.firstName}} {{author.lastName}}</p>
  {{else}}
    <p>Unknown</p>
  {{/if}}
  {{#each items as |item index|}}
    {{> partial name="x" count=3 flag=true}}
    {{{raw item.html}}}
    {{lookup this [my-key]}} {{[weird key]}}
    {{helper "string" 'single' 1.5 null @index ../parent}}
  {{/each}}
</div>
''',
    colored: ['if', 'each'],
  ),
  'haskell': (
    source: r'''
{-# LANGUAGE OverloadedStrings #-}
-- line comment
{- block comment -}
module Main (main) where
import qualified Data.Map as M
import Data.List (sortBy)
data Shape = Circle Double | Rect Double Double deriving (Show, Eq)
class Area a where area :: a -> Double
instance Area Shape where
  area (Circle r) = pi * r ^ 2
  area (Rect w h) = w * h
main :: IO ()
main = do
  let xs = [1, 2, 3] :: [Int]
      c = 'x'
      n = 0x1F + 0o17 + 3.14e2
  putStrLn $ "Sum: " ++ show (sum xs)
  mapM_ print . filter even $ xs
  case xs of
    [] -> return ()
    (y:_) | y > 0 -> print y
          | otherwise -> pure ()
  if null xs then return () else print `seq` ()
''',
    colored: ['module', 'import', 'where'],
  ),
  'html': (
    source: r'''
<!DOCTYPE html>
<?xml version="1.0" encoding="UTF-8"?>
<![CDATA[ raw <data> ]]>
<!-- A comment -->
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Test &amp; demo &#169; &#x00A9;</title>
  <style type="text/css">
    @media screen { body { color: #333; margin: 0 !important; } }
    .a > .b::after { content: "x"; }
  </style>
  <style>p { font-size: 12px; }</style>
  <script type="module">
    import { x } from './x.js';
    const t = `template ${x + 1}`;
    const re = /ab+c/gi;
    if (x > 1) { console.log("hi", 'there', 42); }
  </script>
  <script>var y = 1;</script>
  <script><![CDATA[ var z = 2; ]]></script>
  <style><![CDATA[ a { color: blue; } ]]></style>
</head>
<body>
  <svg:rect xlink:href="#a" width="10"/>
  <div id="main" class='box' style="color: red; margin: 0"
       onclick="handle(event); return false;" data-x=unquoted hidden>
    <a href="https://example.com?a=1&amp;b=2">Link</a>
    <img src="a.png" alt="" />
    <input type="text" disabled>
  </div>
</body>
</html>
''',
    colored: ['html', 'head', 'body'],
  ),
  'http': (
    source: r'''
POST /api/v1/users?id=1 HTTP/1.1
Host: example.com
Content-Type: application/json; charset=utf-8
Authorization: Bearer abc.def.ghi
Accept: */*

{"name": "Ann", "age": 30, "admin": false, "tags": ["a", null]}

HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Set-Cookie: id=a3fWa; Max-Age=2592000

<html><body class="ok">Done</body></html>

HTTP/1.1 404 Not Found
Content-Type: application/xml

<error code="404">missing</error>

HTTP/1.1 200 OK
Content-Type: text/xml

<ok/>

HTTP/1.1 200 OK
Content-Type: application/javascript

var x = 1;

HTTP/1.1 200 OK
Content-Type: text/css

body { margin: 0; }

HTTP/1.1 200 OK
Content-Type: text/plain

plain body
''',
    colored: ['POST', 'Host'],
  ),
  'ini': (
    source: r'''
; comment
# another comment
[section]
key = value
quoted = "quoted value"
single = 'single'
[other.section]
path=/usr/local
empty =
''',
    colored: ['[section]', 'key'],
  ),
  'java': (
    source: r'''
package com.example.app;
import java.util.*;
import static java.lang.Math.max;
/**
 * Javadoc with {@link Foo} and @param x
 */
@SuppressWarnings("unchecked")
@Entity(name = "users")
public final class Repo<T extends Comparable<? super T>>
    implements Iterable<T> {
  private static final long serialVersionUID = 0x1FL + 1_000 + 3.14e2f + 0b1010;
  private final Map<String, List<T>> cache = new HashMap<>();
  public sealed interface Shape permits Circle, Square {}
  public record Point(int x, int y) {}
  @Override
  public Iterator<T> iterator() {
    var text = """
        Text block "quoted"
        """;
    char c = '\n';
    String s = "hello" + c;
    switch (s) {
      case "a" -> System.out.println(s);
      default -> {}
    }
    Runnable r = () -> { throw new IllegalStateException(); };
    if (obj instanceof String str && !str.isEmpty()) { return null; }
    List<String>[] arr = new ArrayList[10];
    return cache.values().stream().flatMap(List::stream).iterator();
  }
  enum Color { RED, GREEN }
  module com.foo { requires java.base; exports com.foo.api; }
}
''',
    colored: ['package', 'class', 'public'],
  ),
  'js': (
    source: r'''
#!/usr/bin/env node
'use strict';
// line comment
/* block comment */
/** JSDoc @param {string} name */
import React, { useState } from 'react';
import * as path from "path";
export default class Greeter extends Base {
  #secret = 1;
  static count = 0;
  constructor(name = 'world') { super(); this.name = name; }
  get upper() { return this.name.toUpperCase(); }
  async *gen() {
    yield* await fetch(`/api/${this.name}?q=${encodeURIComponent(q)}`);
  }
}
const re = /^(?<year>\d{4})-(?:\d{2})[a-z\-0-9]\1$/giu;
const re2 = /[^abc]+|x*?/;
const tagged = html`<div>${value}</div>`;
const nested = `outer ${`inner ${deep}`} end`;
let n = 0x1F + 0o17 + 0b101 + 1_000n + 3.14e-2 + .5;
const fn = async (a, { b, c }, ...rest) => a ?? b?.c ?? rest[0];
label: for (const [k, v] of Object.entries(obj)) { if (k in o) continue label; }
typeof x === 'undefined' && void 0 || null instanceof Object;
try { throw new Error("x"); } catch { } finally { }
console.log(NaN, Infinity, undefined, true, false);
new.target; import.meta.url; debugger;
''',
    colored: ['import', 'class', 'const'],
  ),
  'json': (
    source: r'''
{
  // comment
  /* block */
  "string": "value with \"escapes\"",
  "number": -1.5e10,
  "array": [true, false, null],
  "object": {"nested": {}}
}
''',
    colored: ['"value with \\"escapes\\""'],
  ),
  'json5': (
    source: r'''
// JSON5
{
  unquoted: 'single',
  "quoted": "double",
  hex: 0xDEADbeef,
  leading: .5, trailing: 5.,
  positive: +1, inf: Infinity, nan: NaN,
  trailingComma: [1, 2,],
  /* block */ multi: 'line \
continued',
}
''',
    colored: ['unquoted', '0xDEADbeef'],
  ),
  'julia': (
    source: r'''
# comment
#= block
   comment =#
module Demo
using LinearAlgebra
export greet
struct Point{T<:Real}
    x::T
    y::T
end
function greet(name::String="world"; loud=false)
    msg = "Hello, $name and $(uppercase(name))"
    c = 'c'
    r = r"^\d+$"
    raw = """triple"""
    cmd = `ls -la`
    n = 0x1F + 0b101 + 1_000 + 3.14e-2 + 1im
    A = [1 2; 3 4]'
    x = A \ [1, 2]
    return loud ? uppercase(msg) : msg
end
@time greet()
macro m(ex) esc(ex) end
:symbol
end
''',
    colored: ['function', 'end', 'module'],
  ),
  'jsx': (
    source: r'''
import React, { useState } from 'react';
// Component
export default function App({ items, onSelect }) {
  const [open, setOpen] = useState(false);
  const style = { color: 'red', fontSize: 12 };
  return (
    <>
      <Header title="Hello" subtitle='World' count={items.length} {...rest} />
      <div className={`box ${open ? 'open' : ''}`}
           style={{ margin: 0, padding: `${1}px` }}
           onClick={() => setOpen(!open)} data-id="x" aria-hidden>
        {items.map((item, i) => (
          <Item key={item.id} index={i} onSelect={() => onSelect(item)}>
            {item.label} &amp; more &nbsp;
            {/* comment inside JSX */}
          </Item>
        ))}
        <svg:circle xlink:href="#a" r={5} />
        <Foo.Bar render={<span>nested {value}</span>} />
        {open && <p>Open!</p>}
        <input value={value} disabled
               onChange={e => setValue(e.target.value)} />
      </div>
    </>
  );
}
const re = /^[a-z]+(\d)\1(?:x)$/gi;
class Panel extends React.Component {}
const page = '<!DOCTYPE html>' + body;
export const Head = () => (
  <head>
    <style>{`@media (max-width: 600px) {
      .a { background: url(bg.png); }
    }`}</style>
    <script>
      window.re = /^[a-z](x)\1(?<n>y)\k<n>$/; new Tracker();
      window.t = `a ${b}`;
    </script>
    <a style="color: blue" onclick="track(1)">plain html attrs</a>
  </head>
);
const tpl = `t ${x}`;
''',
    colored: ['import', 'function', 'return'],
  ),
  'kotlin': (
    source: r'''
@file:JvmName("Main")
package com.example
import kotlinx.coroutines.*
// comment
/* block */
@Target(AnnotationTarget.CLASS)
annotation class Marker
data class User(val name: String, var age: Int = 0) : Base(), Comparable<User> {
    companion object { const val MAX = 0x1F + 0b101 + 1_000L + 3.14e2f + 1u }
    override fun compareTo(other: User): Int = age - other.age
}
sealed interface Shape
suspend fun main() = coroutineScope {
    val name = "world"
    val s = "Hello, $name and ${name.uppercase()}!"
    val raw = """
        |raw $name ${1 + 2}
    """.trimMargin()
    val c = 'c'
    val list = listOf(1, 2, 3).filter { it > 1 }.map { it * 2 }
    when (val x = list.firstOrNull()) {
        null -> println("none")
        in 1..10 -> println("small")
        is Int -> println(x)
        else -> {}
    }
    val nullable: String? = null
    nullable?.length ?: 0
    launch { delay(100L) }
    infix fun Int.plus(o: Int) = this + o
    label@ for (i in 0 until 10) { if (i > 5) break@label }
}
''',
    colored: ['fun', 'val', 'class'],
  ),
  'latex': (
    source: r'''
% comment
\documentclass[12pt]{article}
\usepackage{amsmath}
\newcommand{\R}{\mathbb{R}}
\begin{document}
\section{Introduction}\label{sec:intro}
\subsection*{Part}
\chapter{One}
Text with \emph{emphasis} and $x^2 + y_1$ inline, \(a+b\) too.
\[ E = mc^2 \]
$$ \int_0^\infty e^{-x} dx $$
\begin{equation}
  \frac{a}{b} \cdot \sqrt{c}
\end{equation}
\begin{align*} a &= b \\ c &= d \end{align*}
\begin{verbatim} raw \text \end{verbatim}
\cite{ref} \ref{fig:1} \url{https://x.y}
\end{document}
''',
    colored: ['\\documentclass', '\\section'],
  ),
  'less': (
    source: r'''
@import (reference) "foo.less";
// line comment
/* block */
@primary: #428bca;
@min768: ~"(min-width: 768px)";
.mixin(@color; @padding: 2px) when (iscolor(@color)) {
  color: @color;
  padding: @padding;
}
.box {
  .mixin(#fff; 4px);
  &:hover { color: darken(@primary, 10%); }
  @media @min768 { width: ~"calc(100% - @{gutter})"; }
  @r: { color: red; };
  width: (@base * 2);
  background: url("img/bg.png") no-repeat;
  .bordered() !important;
}
#ns { .m() { color: blue } }
.use { #ns > .m(); }
@plugin "my-plugin";
@selector: ~".my";
@{selector}-class { a: b; }
''',
    colored: ['@primary', '@import'],
  ),
  'lua': (
    source: r'''
-- comment
--[[ block
comment ]]
local function greet(name, ...)
  local msg = "Hello, " .. name .. '!'
  local long = [[long
string]]
  local n = 0x1F + 3.14e2 + #arg
  for i = 1, 10, 2 do print(i) end
  for k, v in pairs({a = 1, [2] = "b"}) do end
  if n ~= nil and not false then return msg elseif n then else end
  repeat n = n - 1 until n <= 0
  goto done
  ::done::
  return setmetatable({}, {__index = M})
end
''',
    colored: ['local', 'function', 'end'],
  ),
  'makefile': (
    source: r'''
# Build configuration
CC := gcc
CFLAGS ?= -O2 -Wall
SRCS = $(wildcard src/*.c)
OBJS := $(SRCS:.c=.o)
export PATH
.PHONY: all clean
all: app
app: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^
%.o: %.c
	@echo "Compiling $<"
	$(CC) -c $< -o $@
clean:
	rm -f $(OBJS) app
ifeq ($(DEBUG),1)
  CFLAGS += -g
else
  CFLAGS += -DNDEBUG
endif
include config.mk
define HELP
usage text
endef
''',
    colored: ['.PHONY', 'ifeq'],
  ),
  'markdown': (
    source: r'''
---
title: "Front matter"
tags: [a, b]
---
# Heading 1
Setext Heading
==============
Sub heading
-----------
## Heading with `code` and **bold**
> Blockquote with *emphasis* and a [link](https://x.y "Title").
> > Nested quote
- item one
* item two
+ item three
1. ordered
2) ordered paren
- [ ] task
- [x] done
**Bold with *nested italic* and ~~strike~~ and [link](u)**
__underscore bold__ and _underscore italic_ and
*star italic with **bold** inside*
~~strike with **bold** and *italic*~~
~single strike~
Inline `code span` and ``double `tick` code``.
Autolink <https://example.com> and <mail@example.com>.
![Image alt](img.png "Image title")
[Reference link][ref] and [collapsed][] and [shortcut].
[ref]: https://example.com/ref "Ref Title"
[other]: <https://example.com/angle> 'Single'
***
- - -
___
    indented code block
    more code
```js
const x = `tpl ${y}`;
```
~~~python
def f(): pass
~~~
```
plain fenced
```
| Col A | Col B | Col C |
|:------|:-----:|------:|
| **a** | `b`   | [c](d) |
| 1     | 2     | 3     |
Line with trailing spaces for break
<div class="raw" style="color: red" onclick="go()">
Inline <b>HTML</b> &amp; entity &#169;</div>
<!-- html comment -->
<style>
@media screen { p { color: red; background: url("bg.png"); } }
</style>
<style><![CDATA[ p { margin: 0; } ]]></style>
<script>
let x = /^[a-z]+(\d)\1(?<y>x)\k<y>$/g; new Widget();
const t = `line
${b}`;
</script>
<script><![CDATA[ var a = 1; ]]></script>
<?xml version="1.0"?>
<!DOCTYPE html>
<![CDATA[ cdata ]]>
''',
    colored: ['# Heading 1', '**', '```'],
  ),
  'markup-templating': (
    source: r'''
<div class="x">{{ value }}</div>
<!-- comment -->
''',
    colored: [],
  ),
  'nginx': (
    source: r'''
# comment
user www-data;
worker_processes auto;
events { worker_connections 1024; }
http {
  include mime.types;
  server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
    set $root /var/www;
    location ~* \.(jpg|png)$ {
      expires 30d;
      add_header Cache-Control "public, max-age=$age";
    }
    location / { proxy_pass http://backend; try_files $uri $uri/ =404; }
    if ($host = 'x') { return 301 https://$host$request_uri; }
  }
}
''',
    colored: ['server', 'listen'],
  ),
  'objectivec': (
    source: r'''
#import <Foundation/Foundation.h>
#include "local.h"
// comment
/* block */
@interface Person : NSObject <NSCopying>
@property (nonatomic, strong) NSString *name;
- (instancetype)initWithName:(NSString *)name;
+ (void)classMethod;
@end
@implementation Person
- (instancetype)initWithName:(NSString *)name {
  if (self = [super init]) {
    _name = [name copy];
    NSLog(@"Hello, %@! %d", name, 0x1F);
    NSArray *arr = @[@1, @2.5, @YES];
    NSDictionary *d = @{@"key": @"value"};
    void (^block)(int) = ^(int x) { printf("%d\n", x); };
    char c = 'c';
    @try { @throw nil; } @catch (NSException *e) {} @finally {}
    @autoreleasepool {}
    SEL s = @selector(foo:);
  }
  return self;
}
@end
''',
    colored: ['@interface', '#import'],
  ),
  'ocaml': (
    source: r'''
(* comment *)
open Printf
module M : sig val x : int end = struct let x = 1 end
type 'a tree = Leaf | Node of 'a tree * 'a * 'a tree
let rec sum = function
  | [] -> 0
  | x :: xs -> x + sum xs
let () =
  let s = "hello" ^ {|quoted string|} in
  let c = 'c' in
  let n = 0x1F + 0b101 + 1_000 + int_of_float 3.14e2 in
  printf "%s %c %d\n" s c n;
  match Some `Poly with Some `Poly -> () | _ -> ()
let f ~label ?(opt = 1) x = x + label + opt
external ext : int -> int = "c_ext"
''',
    colored: ['let', 'match', 'open'],
  ),
  'perl': (
    source: r'''
#!/usr/bin/perl
use strict;
use warnings;
# comment
=pod
Documentation block
=cut
my $name = "world";
my @list = (1, 2, 3);
my %hash = (key => 'value', other => 0x1F);
print "Hello, $name! @list $hash{key} ${name}\n";
my $re = qr/^\w+\d*$/i;
if ($name =~ m{w(or)ld}x) { print $1; }
$name =~ s/world/perl/g;
$name =~ tr/a-z/A-Z/;
my @w = qw(foo bar baz);
my $q = q{single}; my $qq = qq{double $name};
my $heredoc = <<"END";
Heredoc $name
END
sub greet { my ($self, %args) = @_; return $self->{name}; }
foreach my $i (0..$#list) { next unless $i; }
open(my $fh, '<', 'file.txt') or die "Cannot open: $!";
__END__
''',
    colored: ['my', 'sub', 'use'],
  ),
  'php': (
    source: r'''
<!DOCTYPE html>
<html>
<head><title><?= htmlspecialchars($title) ?></title></head>
<body class="<?php echo $cls; ?>">
<?php
declare(strict_types=1);
namespace App\Http\Controllers;
use App\Models\{User, Post};
use function strlen;
// comment
# hash comment
/* block */
/** @var string $doc */
#[Attribute(Attribute::TARGET_CLASS)]
#[Route('/users', methods: ['GET'])]
#[\App\Attributes\Cached]
final class UserController extends \App\Http\Controller implements HasMiddleware
{
    public const MAX = 0x1F + 0b101 + 1_000 + 3.14e2;
    private static ?array $cache = null;
    public function __construct(private readonly UserRepo $repo) {}
    public function show(int $id, string ...$rest): ?User
    {
        $user = $this->repo->find($id) ?? throw new NotFound();
        $name = "Hi {$user->name}, ${id}, $user->email, {$arr['k']}";
        $single = 'single $not';
        $heredoc = <<<EOT
Heredoc {$user->name} and $id
EOT;
        $quoted = <<<"EOT"
Quoted heredoc $id
EOT;
        $nowdoc = <<<'EOT'
Nowdoc $raw
EOT;
        $model = new \App\Models\User();
        \App\Support\Str::slug($name);
        $handler = fn(\Psr\Log\LoggerInterface $log): \App\Result => $log;
        $either = \App\A|\App\B::class;
        $fn = fn($x) => $x * 2;
        $result = match (true) { $id > 0 => 'positive', default => 'other' };
        static::helper(); self::MAX; parent::__construct();
        if ($user instanceof User && !empty($rest)) { return $user; }
        foreach ($rest as $key => $value) { echo $key, PHP_EOL; }
        $arr = ['a' => 1, "b" => true, 'c' => null, 'd' => FALSE];
        enum_exists(Status::class);
        return null;
    }
}
enum Status: string { case Active = 'active'; }
?>
<ul>
<?php foreach ($items as $item): ?>
  <li data-id="<?= $item->id ?>"><?php echo $item->name ?></li>
<?php endforeach; ?>
</ul>
<script>var x = 1;</script>
<style>a { color: red; }</style>
</body>
</html>
''',
    colored: ['<?php', 'namespace', 'declare'],
  ),
  'plain': (source: 'just some plain text\nwith lines\n', colored: []),
  'powershell': (
    source: r'''
# comment
<# block
   comment #>
param([Parameter(Mandatory)][string]$Name = "world")
function Get-Greeting {
    [CmdletBinding()]
    param([int]$Count = 1)
    $msg = "Hello, $Name and $($Name.ToUpper()) and $env:USERNAME"
    $single = 'single $not'
    $here = @"
Here-string $Name
"@
    $raw = @'
Raw $Name
'@
    $arr = @(1, 2, 3); $hash = @{ Key = 'Value'; Num = 0x1F }
    if ($Count -gt 0 -and $Name -like "w*") { Write-Output $msg }
    elseif (-not $true) { } else { }
    foreach ($i in 1..10) { $i | Where-Object { $_ % 2 -eq 0 } }
    switch -regex ($Name) { '^w' { 'starts with w' } default { 'other' } }
    try { throw "err" }
    catch [System.Exception] { $_.Exception.Message }
    finally { }
    Get-ChildItem -Path C:\ -Recurse | Select-Object -First 5
    [System.Math]::Max(1, 2)
    return $null
}
''',
    colored: ['function', 'param', 'if'],
  ),
  'protobuf': (
    source: r'''
// comment
/* block */
syntax = "proto3";
package com.example.v1;
import "google/protobuf/timestamp.proto";
option java_package = "com.example";
message User {
  string name = 1;
  int32 age = 2 [deprecated = true];
  repeated string tags = 3;
  map<string, int64> counts = 4;
  google.protobuf.Timestamp created = 5;
  .com.example.v1.Role role = 6;
  optional bytes data = 7;
  oneof contact { string email = 8; string phone = 9; }
  enum Role { UNKNOWN = 0; ADMIN = 1; }
  reserved 10, 11 to 15;
  float score = 12;
  double ratio = 0x1F;
}
service UserService {
  rpc GetUser (GetUserRequest) returns (stream User) {
    option (google.api.http) = { get: "/v1/users" };
  }
}
''',
    colored: ['message', 'syntax', 'service'],
  ),
  'python': (
    source: r'''
#!/usr/bin/env python3
# comment
"""Module docstring."""
from __future__ import annotations
import os.path as osp
from typing import List, Optional
@dataclass(frozen=True)
@property
class Point(Base, metaclass=Meta):
    """Class docstring with 'quotes'."""
    x: int = 0
    def __init__(self, x: int, *args, **kwargs) -> None:
        self.x = x
    async def fetch(self, url: str) -> Optional[bytes]:
        name = "world"
        s = f"Hi {name!r:>10}, {x + 1:.2f}, {{literal}}, {f'{nested}'}"
        b = b"bytes\x00"
        r = r"raw\d+"
        rb = rb'raw bytes'
        t = """triple
        quoted"""
'''
        r"""        u = '''single triple'''
"""
        r'''        n = 0x1F + 0o17 + 0b101 + 1_000 + 3.14e-2 + 2j
        lam = lambda a, b=2: a ** b
        async with session.get(url) as resp:
            return await resp.read()
        for i in range(10):
            if i % 2 == 0 and not i is None or i in [1, 2]:
                continue
            elif i > 5: break
            else: pass
        try: raise ValueError("x") from None
        except (TypeError, ValueError) as e: print(e)
        finally: del x
        global g; nonlocal_ = True; yield from gen(); assert x, "msg"
        match point:
            case Point(x=0): print(None, True, False, ...)
            case _: pass
        while x := next(it): ...
''',
    colored: ['def', 'import', 'return'],
  ),
  'r': (
    source: r'''
# comment
library(dplyr)
greet <- function(name = "world", ...) {
  msg <- paste0("Hello, ", name, '!')
  n <- 0x1F + 3.14e2 + 1L + 2i
  x <- c(TRUE, FALSE, NA, NULL, Inf, NaN)
  if (n > 1 && !is.na(x[1])) msg else NULL
  for (i in seq_len(10)) next
  df %>% filter(a > 1) %in% b
  `weird name` = 1
  r"(raw string)"
}
''',
    colored: ['function', 'if', 'for'],
  ),
  'regex': (
    source: r'^(?<year>\d{4})-(?:0[1-9]|1[0-2])-(?=\d)(?!x)(?<=a)(?<!b)'
        r'[^\s\-a-z\]]+?\k<year>\1\b\B.*$|'
        r'[\x41-\u0042\p{L}\cA\0\t]{2,}|(a)+?(?i:x)\.\/',
    colored: ['^', '(?<year>'],
  ),
  'ruby': (
    source: r'''
#!/usr/bin/env ruby
# frozen_string_literal: true
=begin
Block comment
=end
require 'json'
require_relative "lib/helper"
module App
  class User < Base
    include Comparable
    attr_accessor :name, :age
    CONSTANT = 0x1F + 0b101 + 1_000 + 3.14e2 + 1r + 2i
    def initialize(name:, age: 0, **opts, &block)
      @name = name
      @@count ||= 0
      $global = true
      super()
    end
    def to_s = "User(#{@name}, #{age + 1})"
    def self.build(*args) = new(*args)
    def greet
      s = "Hello #{name}!"
      single = 'no #{interp}'
      sym = :symbol
      sym2 = :"quoted #{sym}"
      hash = { key: 'value', "str" => 1, sym => nil }
      re = /^\w+[a-z]$/imx
      pct = %w[foo bar] + %i(a b)
      pq = %q(single) + %Q{double} + %(paren)
      pr = %r{regex/\d+}i
      cmd = `ls -la`
      sh = %x(git status)
      heredoc = <<~EOS
        Indented text
      EOS
      raw = <<-'RAW'
        Raw text
      RAW
      [1, 2, 3].each_with_index.map { |x, i| x * i }.select(&:even?)
      lambda = ->(x) { x * 2 }
      return unless defined?(name)
      case age
      when 0..17 then :minor
      when Integer, Float then :adult
      else nil
      end
      begin
        raise ArgumentError, "bad"
      rescue StandardError => e
        retry if e
      ensure
        puts __method__
      end
      yield self if block_given?
    end
    private def secret; end
  end
end
__END__
data section
''',
    colored: ['class', 'def', 'module'],
  ),
  'rust': (
    source: r'''
//! Crate docs
/// Item docs
// comment
/* block /* nested */ */
#![allow(dead_code)]
#[derive(Debug, Clone)]
pub struct Point<'a, T: Copy + 'static> { x: T, name: &'a str }
impl<'a, T> Point<'a, T> where T: Copy + std::fmt::Display {
    pub const fn new(x: T, name: &'a str) -> Self { Self { x, name } }
}
pub trait Shape { fn area(&self) -> f64; }
enum Color { Red, Rgb(u8, u8, u8) }
macro_rules! square { ($x:expr) => { $x * $x }; }
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut v: Vec<i32> = vec![1, 2, 3];
    let s = String::from("hello\n");
    let raw = r#"raw "string""#;
    let b = b"bytes"; let c = 'c'; let bc = b'x';
    let n = 0x1F_u32 + 0o17 + 0b1010 + 1_000 + 3.14e-2f64 as u32;
    println!("{} {:?} {name}", s, v, name = "x");
    for (i, x) in v.iter_mut().enumerate() { *x += i as i32; }
    match v.get(0) { Some(&x) if x > 0 => {}, Some(_) | None => {} }
    let closure = |a: i32| -> i32 { a + 1 };
    unsafe { std::ptr::null::<u8>(); }
    async move { fut.await? };
    loop { break 'outer; }
    Ok(())
}
mod tests { use super::*; use crate::foo::{self, Bar as Baz}; }
''',
    colored: ['fn', 'let', 'struct'],
  ),
  'sass': (
    source: r'''
// line comment
/* block comment */
@import "base", "mixins"
@use "sass:math"
$primary: #333 !default
$map: (key: value, other: 1px)
=large-text($size: 20px)
  font-size: $size
  font-weight: bold
+large-text(24px)
.nav
  color: $primary
  &:hover
    color: darken($primary, 10%)
  ul
    margin: 0 auto
    padding: math.div(10px, 2) + 1em
  @extend .base
  @include mixin($a, $b)
  @if $a == 1
    width: 100%
  @else
    width: 50%
  @each $name in a, b
    .icon-#{$name}
      background: url("/#{$name}.png")
  :font
    family: Arial
@function double($n)
  @return $n * 2
''',
    colored: ['@import', '\$primary'],
  ),
  'scala': (
    source: r'''
package com.example
import scala.concurrent.{Future, ExecutionContext}
import scala.util._
import scala.collection.mutable.ListBuffer;
// comment
/* block */
/** Scaladoc */
@deprecated("use v2", "1.0")
sealed trait Shape
case class Circle(r: Double) extends Shape with Serializable
object Main extends App {
  implicit val ec: ExecutionContext = ExecutionContext.global
  val name = "world"
  val s = s"Hello, $name and ${name.toUpperCase}!"
  val f = f"$name%s is ${1.5}%.2f"
  val raw = raw"raw\n$name"
  val multi = """multi
    |line "quoted"""".stripMargin
  val c = 'c'
  val sym = 'symbol
  val n = 0x1F + 1_000L + 3.14e2f + 2.0d
  def area[T <: Shape](shape: T)(implicit ev: Numeric[Double]): Double =
    shape match {
    case Circle(r) if r > 0 => math.Pi * r * r
    case _ => 0.0
  }
  lazy val xs = for { x <- List(1, 2, 3) if x > 1; y = x * 2 } yield y
  Future { 42 }.map(_ + 1)
  type Alias = Map[String, List[Int]]
  given Ordering[Int] = Ordering.Int
  enum Color { case Red, Green }
  extension (s: String) def shout: String = s.toUpperCase
  null; true; false; this; super.toString
}
''',
    colored: ['package', 'object', 'val'],
  ),
  'scss': (
    source: r'''
@use 'sass:math';
@import 'variables', 'mixins';
// line comment
/* block */
$primary: #3498db !default;
$breakpoints: (small: 576px, medium: 768px);
%placeholder { color: red; }
@supports (display: grid) { .grid { display: grid; } }
@mixin respond($bp) {
  @media (min-width: map-get($breakpoints, $bp)) { @content; }
}
@function rem($px, $base: 16px) { @return math.div($px, $base) * 1rem; }
.card {
  @extend %placeholder;
  @include respond(medium) { padding: rem(24px); }
  color: rgba($primary, .8);
  &__title { font: #{$size}/#{$lh} $family; }
  &:hover:not(.disabled) > .icon::after { content: "\2192"; }
  @if $theme == dark { background: #000; }
  @else if $theme == light { background: #fff; }
  @else { background: gray; }
  @each $name, $glyph in $icons { .icon-#{$name}:before { content: $glyph; } }
  @for $i from 1 through 3 { .m-#{$i} { margin: #{$i * 4}px; } }
  @while $i > 0 { $i: $i - 1; }
  width: calc(100% - #{$gutter});
  @debug "value: #{$x}";
  @warn "deprecated";
  @forward "src/list" hide list-reset;
}
''',
    colored: ['@mixin', '@include', '\$primary'],
  ),
  'solidity': (
    source: r'''
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
/// @title Token
contract Token is ERC20, Ownable {
  uint256 public constant MAX = 1e18 + 0x1F;
  mapping(address => uint256) private balances;
  event Transfer(address indexed from, address indexed to, uint256 value);
  error Insufficient(uint256 needed);
  modifier onlyAdmin() { require(msg.sender == owner(), "not admin"); _; }
  function transfer(address to, uint256 amt) external payable returns (bool) {
    if (balances[msg.sender] < amt) revert Insufficient(amt);
    emit Transfer(msg.sender, to, amt);
    return true;
  }
  receive() external payable {}
}
''',
    colored: ['contract', 'function', 'pragma'],
  ),
  'sql': (
    source: r'''
-- comment
/* block comment */
# hash comment
CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL DEFAULT 'anon',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO users (name) VALUES ('Ann'), ("Bob");
SELECT u.id, COUNT(*) AS cnt, `quoted col`
FROM users u LEFT JOIN posts p ON p.user_id = u.id
WHERE u.name LIKE 'A%' AND u.id IN (1, 2, 3) OR u.id BETWEEN 0x1F AND 3.14
GROUP BY u.id HAVING cnt > 1 ORDER BY cnt DESC LIMIT 10;
UPDATE users SET name = @var WHERE id = 1;
DELETE FROM users WHERE name IS NULL;
''',
    colored: ['SELECT', 'FROM', 'CREATE'],
  ),
  'swift': (
    source: r'''
import UIKit
// comment
/* block /* nested */ */
/// Doc
@available(iOS 15, *)
@MainActor
final class ViewModel: ObservableObject {
    @Published private(set) var items: [String] = []
    static let shared = ViewModel()
    let n = 0x1F + 0b101 + 0o17 + 1_000 + 3.14e-2
    func load(id: Int, completion: @escaping (Result<[String], Error>) -> Void)
        async throws -> Int? {
        let name = "world"
        let s = "Hello, \(name) and \(id + 1)!"
        let multi = """
            Multi \(name)
            """
        let raw = #"raw \(not) "quoted""#
        let rawInterp = #"value \#(name)"#
        guard let first = items.first else { return nil }
        if case .some(let x) = Optional(first) { print(x) }
        switch id {
        case 0..<10: break
        case let v where v > 100: fallthrough
        default: ()
        }
        defer { print("done") }
        items.map { $0.uppercased() }.filter { !$0.isEmpty }
        let r = /\d+/
        #if DEBUG
        print(#file, #line)
        #endif
        return try await Task { 42 }.value
    }
}
struct Point: Hashable { var x, y: Double }
enum Direction: String, CaseIterable { case north, south }
protocol Shape { associatedtype T; func area() -> Double }
extension Int { var squared: Int { self * self } }
''',
    colored: ['import', 'class', 'func'],
  ),
  'toml': (
    source: r'''
# comment
title = "TOML Example"
[owner]
name = 'Tom'
dob = 1979-05-27T07:32:00-08:00
time = 07:32:00
date = 1979-05-27
[database]
ports = [ 8001, 8002, 0x1F, 0o17, 0b101, +1_000, 3.14e2, inf, nan ]
enabled = true
"quoted key" = """multi
line"""
'''
        r"""literal = '''raw'''
"""
        r'''[[products]]
dotted.key.name = { inline = true, x = -1 }
''',
    colored: ['title', '"TOML Example"'],
  ),
  'tsx': (
    source: r'''
import React, { type FC, useState } from 'react';
import type { Props } from './types';
// comment
interface ItemProps<T extends object = {}> {
  readonly id: string;
  item?: T;
  onSelect: (item: T) => void;
  [key: string]: unknown;
}
type Union = 'a' | 'b' | `tpl-${string}`;
enum Color { Red = 1, Green }
declare module 'x' { export const y: number; }
namespace NS { export type Z = keyof typeof obj; }
@Component({ selector: 'app' })
export class Store<S> implements IStore {
  private state!: S;
  constructor(public readonly name: string, protected opts?: Options) {}
  abstract get value(): S;
}
export const List: FC<ItemProps<Item>> = (
  { items, onSelect, ...rest }: Props,
) => {
  const [sel, setSel] = useState<string | null>(null);
  const cast = value as unknown as number;
  const generic = <T,>(x: T): T => x;
  const assertion = obj!.prop satisfies Shape;
  return (
    <ul className={`list ${sel ? 'active' : ''}`}
        style={{ margin: 0 }} {...rest}>
      {items.map((it: Item, i: number) => (
        <li key={it.id} data-index={i} aria-selected="true"
            onClick={() => setSel(it.id)}>
          <Label<string> text="hello" count={42} enabled />
          {it.label} &amp; &#169;
          {/* comment */}
          {sel === it.id && <span className='sel'>selected {sel}</span>}
          <svg:path d="M0 0" xlink:href='#a' />
          <Foo.Bar render={<b>nested {x}</b>} />
        </li>
      ))}
    </ul>
  );
};
function assertIsString(val: any): asserts val is string {}
let tuple: [number, string?, ...boolean[]] = [1];
const re = /^[a-z]+(\d)\1(?:\d{4})$/gi;
const n = 0x1F + 1_000n + 3.14e2;
const page = '<!DOCTYPE html>' + body;
class Tagged extends Base<`id-${string}`> {}
@sealed
class Sealed {}
export const Head = () => (
  <head>
    <style>{`@media (max-width: 600px) {
      .a { background: url(bg.png); }
    }`}</style>
    <script>
      window.re = /^[a-z](x)\1(?<n>y)\k<n>$/; new Tracker();
      window.t = `a ${b}`;
    </script>
    <a style="color: blue" onclick="track(1)">plain html attrs</a>
  </head>
);
''',
    colored: ['import', 'interface', 'return'],
  ),
  'typescript': (
    source: r'''
import { Injectable } from '@angular/core';
import type { User } from './models';
export * as utils from './utils';
// comment
/* block */
/** JSDoc @param x */
@Injectable({ providedIn: 'root' })
export abstract class Service<T extends { id: number } = User>
    implements OnInit {
  private readonly cache = new Map<string, T>();
  protected static instance?: Service<any>;
  declare foo: string;
  constructor(
    private http: HttpClient,
    @Inject(TOKEN) public token: string,
  ) { super(); }
  public async get<K extends keyof T>(
    id: number, key: K): Promise<T[K] | undefined> {
    const url = `/api/users/${id}?key=${String(key)}`;
    const res = await this.http.get<T>(url).toPromise();
    return res?.[key] ?? undefined;
  }
  abstract render(): void;
  get size(): number { return this.cache.size; }
}
export interface Shape { readonly kind: 'circle' | 'square'; area(): number; }
export type Mapped<T> = {
  [P in keyof T]?: T[P] extends Function ? never : T[P];
};
type Cond<T> = T extends string ? 'str' : T extends infer U ? U : never;
enum Direction { Up = 1, Down, Left = 'L' }
const enum Flags { None = 0 }
declare global { interface Window { app: any } }
namespace Validation { export const re = /^[A-Za-z]+$/; }
function isString(x: unknown): x is string { return typeof x === 'string'; }
let v = <string>someValue;
let tuple: readonly [x: number, y?: string] = [1];
const fn = (a: number, b = 2, ...rest: number[]): void => {};
let big: bigint = 100n;
class Tagged extends Base<`id-${string}`> {}
const ref = useRef<HTMLElement>(null);
const iso = /^(\d{4})-[0-9]{2}\1(?<day>\d+)\k<day>$/u;
let sym: unique symbol;
for (const k in obj) {} for (const v of arr) {}
''',
    colored: ['import', 'class', 'interface'],
  ),
  'vim': (
    source: r'''
" Vim config comment
set nocompatible
set tabstop=4 shiftwidth=4 expandtab
syntax on
let g:mapleader = ","
let s:count = 0x1F + 10
nnoremap <leader>w :w<CR>
function! MyFunc(arg) abort
  if a:arg ==# 'x' | echo "yes" | endif
  for i in range(10) | call add(l:list, i) | endfor
  return a:arg
endfunction
autocmd BufWritePre *.py :%s/\s\+$//e
''',
    colored: ['set', 'let', 'function'],
  ),
  'wasm': (
    source: r'''
;; line comment
(; block comment ;)
(module
  (import "env" "log" (func $log (param i32)))
  (memory $mem 1)
  (export "add" (func $add))
  (func $add (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.add)
  (data (i32.const 0) "Hello\n")
  (global $g (mut f64) (f64.const 3.14e2))
  (func (export "x") i64.const 0x1F drop nan:0x7 inf)
  (table 1 funcref)
  (elem (i32.const 0) $add)
  (start $add)
  (func call_indirect (type $t) offset=8 align=4)
)
''',
    colored: ['module', 'func'],
  ),
  'xml': (
    source: r'''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE note [
  <!ENTITY writer "Writer: Donald Duck.">
  <!ELEMENT note (to,from)>
]>
<!-- comment -->
<ns:root xmlns:ns="http://example.com/ns" attr='single'>
  <ns:child id="1" ns:attr="x">Text &amp; &writer; &#169; &#x00A9;</ns:child>
  <![CDATA[ <raw> & data ]]>
  <empty/>
  <style>p { color: red; }</style>
  <script>var x = 1;</script>
  <item style="color: blue" onload="init()" />
</ns:root>
''',
    colored: ['ns:root', 'xmlns:ns'],
  ),
  'yaml': (
    source: r'''
%YAML 1.2
---
# comment
name: "quoted"
single: 'single'
plain: value
number: 0x1F
float: -3.14e2
bool: true
null_value: ~
date: 2024-01-01T12:00:00Z
anchors: &anchor
  key: value
ref: *anchor
merge:
  <<: *anchor
tagged: !!str 123
custom: !custom value
list:
  - one
  - two: 2
inline: {a: 1, b: [x, y]}
multi: |
  literal block
  text
folded: >-
  folded
  text
? complex key
: complex value
...
''',
    colored: ['name', '"quoted"'],
  ),
};

void main() {
  group('Highlight › grammar coverage samples', () {
    test('every bundled grammar has a sample', () {
      final grammars = {...allHighlightLanguages.values};
      final covered = {for (final t in _samples.keys) allHighlightLanguages[t]};
      final missing = [
        for (final MapEntry(:key, :value) in allHighlightLanguages.entries)
          if (grammars.contains(value) && !covered.contains(value)) key,
      ];
      expect(missing, isEmpty, reason: 'no sample for: $missing');
    });

    for (final MapEntry(key: tag, value: sample) in _samples.entries) {
      test('$tag sample is lossless and colored', () {
        final grammar = allHighlightLanguages[tag];
        expect(grammar, isNotNull, reason: 'unknown language $tag');
        final highlighter = MarkdownHighlighter(
          languages: {tag: grammar!},
          theme: HighlightThemes.githubDark,
        );
        final spans = highlighter.highlight(sample.source, tag, _base);
        final root = TextSpan(style: _base, children: spans);
        expect(root.toPlainText(), sample.source,
            reason: 'highlighting must not alter text');

        // Per-character "is colored" map over the source.
        final colored = <bool>[];
        for (final (text, style) in _fragments(root)) {
          colored.addAll(List.filled(text.length, style.color != null));
        }
        for (final needle in sample.colored) {
          final at = sample.source.indexOf(needle);
          expect(at, isNonNegative, reason: '"$needle" not in $tag sample');
          final uncolored = [
            for (var i = at; i < at + needle.length; i++)
              if (!colored[i] && sample.source[i].trim().isNotEmpty) i,
          ];
          expect(uncolored, isEmpty,
              reason: '"$needle" should be colored in $tag');
        }
      });
    }
  });
}
