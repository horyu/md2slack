///|
test "文字をHTMLへ変換する" {
  assert_eq(to_html(Node::Text("前 ")), "前 ")
}

///|
test "HTMLの特殊文字をエスケープする" {
  assert_eq(to_html(Node::Text("<")), "&lt;")
}

///|
test "太字の子をHTMLへ変換して結合する" {
  assert_eq(to_html(Node::Bold([Node::Text("太"), Node::Text("字")])), "<b>太字</b>")
}

///|
test "コードをHTMLへ変換する" {
  assert_eq(to_html(Node::Code("x < y")), "<code>x &lt; y</code>")
  assert_eq(to_html(Node::Code("**太字**")), "<code>**太字**</code>")
}

///|
test "取り消し線をHTMLへ変換する" {
  assert_eq(
    to_html(Node::Strikethrough([Node::Text("取り消し")])),
    "<s>取り消し</s>",
  )
}

///|
test "太字の中の取り消し線をHTMLへ変換する" {
  assert_eq(
    to_html(
      Node::Bold([
        Node::Text("太字 "),
        Node::Strikethrough([Node::Text("取り消し")]),
        Node::Text(" 続き"),
      ]),
    ),
    "<b>太字 <s>取り消し</s> 続き</b>",
  )
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
