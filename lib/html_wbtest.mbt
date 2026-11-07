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
test "斜体をHTMLへ変換する" {
  assert_eq(Node::Italic([Node::Text("斜体")]).to_html(), "<i>斜体</i>")
}

///|
test "リンクをHTMLへ変換する" {
  assert_eq(
    Node::Link(label="リンク", url="https://github.com/horyu/md2slack").to_html(),
    "<a href=\"https://github.com/horyu/md2slack\">リンク</a>",
  )
  assert_eq(
    Node::Link(label="<公式> & 案内", url="https://example.com/?a=1&b=2").to_html(),
    "<a href=\"https://example.com/?a=1&amp;b=2\">&lt;公式&gt; &amp; 案内</a>",
  )
}

///|
test "リンクの文字列を解析してHTMLへ変換する" {
  assert_eq(
    parse(tokenize("[公式](https://example.com/)"))
    .map(Node::to_html)
    .join(""),
    "<a href=\"https://example.com/\">公式</a>",
  )
}

///|
test "Markdown文字列をトークンと構造を経由してHTMLへ変換する" {
  assert_eq(
    parse(tokenize("前 **太字** 後")).map(Node::to_html).join(""),
    "前 <b>太字</b> 後",
  )
  assert_eq(
    parse(tokenize("**太字 `コード` 続き**")).map(Node::to_html).join(""),
    "<b>太字 <code>コード</code> 続き</b>",
  )
  assert_eq(
    parse(tokenize("*斜体*")).map(Node::to_html).join(""),
    "<i>斜体</i>",
  )
  assert_eq(
    parse(tokenize("_斜体_")).map(Node::to_html).join(""),
    "<i>斜体</i>",
  )
  assert_eq(
    parse(tokenize("__太字__")).map(Node::to_html).join(""),
    "<b>太字</b>",
  )
  assert_eq(
    parse(tokenize("`__コード__`")).map(Node::to_html).join(""),
    "<code>__コード__</code>",
  )
}

///|
test "バックスラッシュでエスケープされた記号をHTMLへ変換する" {
  assert_eq(
    parse(tokenize("\\*文字\\*")).map(Node::to_html).join(""),
    "*文字*",
  )
  assert_eq(
    parse(tokenize("\\_文字\\_")).map(Node::to_html).join(""),
    "_文字_",
  )
  assert_eq(
    parse(tokenize("\\~\\~文字\\~\\~")).map(Node::to_html).join(""),
    "~~文字~~",
  )
  assert_eq(parse(tokenize("a\\*b")).map(Node::to_html).join(""), "a*b")
  assert_eq(parse(tokenize("a\\_b")).map(Node::to_html).join(""), "a_b")
  assert_eq(parse(tokenize("a\\~b")).map(Node::to_html).join(""), "a~b")
  assert_eq(parse(tokenize("a\\\\b")).map(Node::to_html).join(""), "a\\b")
}

///|
test "コード内のバックスラッシュを保持してHTMLへ変換する" {
  assert_eq(
    parse(tokenize("`\\*`")).map(Node::to_html).join(""),
    "<code>\\*</code>",
  )
  assert_eq(
    parse(tokenize("`\\\\`")).map(Node::to_html).join(""),
    "<code>\\\\</code>",
  )
}
