///|
type T = Token

///|
type N = Node

///|
test "トークン列から太字の構造を組み立てる" {
  assert_eq(
    parse([
      T::Text("前 "),
      T::Delimiter,
      T::Text("太字"),
      T::Delimiter,
      T::Text(" 後"),
    ]),
    [N::Text("前 "), N::Bold([N::Text("太字")]), N::Text(" 後")],
  )
}

///|
test "複数の太字を別々の構造として組み立てる" {
  assert_eq(
    parse([
      T::Delimiter,
      T::Text("一つ目"),
      T::Delimiter,
      T::Text("と"),
      T::Delimiter,
      T::Text("二つ目"),
      T::Delimiter,
    ]),
    [
      N::Bold([N::Text("一つ目")]),
      N::Text("と"),
      N::Bold([N::Text("二つ目")]),
    ],
  )
}

///|
test "閉じられていない区切りを文字として残す" {
  assert_eq(parse([T::Delimiter]), [N::Text("**")])
  assert_eq(parse([T::Text("前 "), T::Delimiter, T::Text("太字")]), [
    N::Text("前 "),
    N::Text("**"),
    N::Text("太字"),
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
test "Markdown文字列をトークンと構造を経由してHTMLへ変換する" {
  assert_eq(
    parse(tokenize("前 **太字** 後")).map(to_html).join(""),
    "前 <b>太字</b> 後",
  )
}
