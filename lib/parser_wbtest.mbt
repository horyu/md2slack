///|
type T = Token

///|
type N = Node

///|
test "トークン列から太字の構造を組み立てる" {
  assert_eq(
    parse([
      T::Text("前 "),
      T::DoubleAsterisk,
      T::Text("太字"),
      T::DoubleAsterisk,
      T::Text(" 後"),
    ]),
    [N::Text("前 "), N::Bold([N::Text("太字")]), N::Text(" 後")],
  )
}

///|
test "複数の太字を別々の構造として組み立てる" {
  assert_eq(
    parse([
      T::DoubleAsterisk,
      T::Text("一つ目"),
      T::DoubleAsterisk,
      T::Text("と"),
      T::DoubleAsterisk,
      T::Text("二つ目"),
      T::DoubleAsterisk,
    ]),
    [
      N::Bold([N::Text("一つ目")]),
      N::Text("と"),
      N::Bold([N::Text("二つ目")]),
    ],
  )
}

///|
test "閉じられていない太字の区切りを文字として残す" {
  assert_eq(parse([T::DoubleAsterisk]), [N::Text("**")])
  assert_eq(parse([T::Text("前 "), T::DoubleAsterisk, T::Text("太字")]), [
    N::Text("前 "),
    N::Text("**"),
    N::Text("太字"),
  ])
}

///|
test "閉じられていないコードの区切りを文字として残す" {
  assert_eq(parse([T::Text("前 "), T::Backtick, T::Text("太字")]), [
    N::Text("前 "),
    N::Text("`"),
    N::Text("太字"),
  ])
}

///|
test "コードと太字が両方閉じられていない場合も元の順序で文字を残す" {
  assert_eq(parse([T::DoubleAsterisk, T::Text("前 "), T::Backtick, T::Text("コード")]), [
    N::Text("**"),
    N::Text("前 "),
    N::Text("`"),
    N::Text("コード"),
  ])
}

///|
test "文字列から太字の構造を組み立てる" {
  assert_eq(parse(tokenize("前 **太字** 後")), [
    N::Text("前 "),
    N::Bold([N::Text("太字")]),
    N::Text(" 後"),
  ])
}

///|
test "文字列からコードの構造を組み立てる" {
  assert_eq(parse(tokenize("`コード`")), [N::Code("コード")])
}

///|
test "太字の中にコードの構造を組み立てる" {
  assert_eq(parse(tokenize("**太字 `コード` 続き**")), [
    N::Bold([N::Text("太字 "), N::Code("コード"), N::Text(" 続き")]),
  ])
}

///|
test "コード内の二重アスタリスクを太字として解釈しない" {
  assert_eq(parse(tokenize("`**コード**`")), [N::Code("**コード**")])
}

///|
test "文字をHTMLへ変換する" {
  assert_eq(to_html(N::Text("前 ")), "前 ")
}

///|
test "HTMLの特殊文字をエスケープする" {
  assert_eq(to_html(N::Text("<")), "&lt;")
}

///|
test "太字の子をHTMLへ変換して結合する" {
  assert_eq(to_html(N::Bold([N::Text("太"), N::Text("字")])), "<b>太字</b>")
}

///|
test "コードをHTMLへ変換する" {
  assert_eq(to_html(N::Code("x < y")), "<code>x &lt; y</code>")
  assert_eq(to_html(N::Code("**太字**")), "<code>**太字**</code>")
}

///|
test "Markdown文字列をトークンと構造を経由してHTMLへ変換する" {
  assert_eq(
    parse(tokenize("前 **太字** 後")).map(to_html).join(""),
    "前 <b>太字</b> 後",
  )
  assert_eq(
    parse(tokenize("**太字 `コード` 続き**")).map(to_html).join(""),
    "<b>太字 <code>コード</code> 続き</b>",
  )
}
