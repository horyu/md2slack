///|
test "文字をHTMLへ変換する" {
  assert_eq(Node::Text("前 ").to_html(), "前 ")
}

///|
test "HTMLの特殊文字をエスケープする" {
  assert_eq(Node::Text("<").to_html(), "&lt;")
}

///|
test "太字の子をHTMLへ変換して結合する" {
  assert_eq(
    Node::Bold([Node::Text("太"), Node::Text("字")]).to_html(),
    "<b>太字</b>",
  )
}

///|
test "コードをHTMLへ変換する" {
  assert_eq(Node::Code("x < y").to_html(), "<code>x &lt; y</code>")
  assert_eq(Node::Code("**太字**").to_html(), "<code>**太字**</code>")
}

///|
test "取り消し線をHTMLへ変換する" {
  assert_eq(
    Node::Strikethrough([Node::Text("取り消し")]).to_html(),
    "<s>取り消し</s>",
  )
}

///|
test "太字の中の取り消し線をHTMLへ変換する" {
  assert_eq(
    Node::Bold([
      Node::Text("太字 "),
      Node::Strikethrough([Node::Text("取り消し")]),
      Node::Text(" 続き"),
    ]).to_html(),
    "<b>太字 <s>取り消し</s> 続き</b>",
  )
}

///|
test "Markdown文字列をトークンと構造を経由してHTMLへ変換する" {
  assert_eq(
    parse(tokenize("前 **太字** 後")).map(n => n.to_html()).join(""),
    "前 <b>太字</b> 後",
  )
  assert_eq(
    parse(tokenize("**太字 `コード` 続き**"))
    .map(n => n.to_html())
    .join(""),
    "<b>太字 <code>コード</code> 続き</b>",
  )
}
