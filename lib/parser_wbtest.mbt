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
test "閉じられていない斜体の区切りを文字として残す" {
  assert_eq(parse([T::SingleAsterisk]), [N::Text("*")])
  assert_eq(parse([T::Text("前 "), T::SingleAsterisk, T::Text("斜体")]), [
    N::Text("前 "),
    N::Text("*"),
    N::Text("斜体"),
  ])
}

///|
test "コードと太字が両方閉じられていない場合も元の順序で文字を残す" {
  assert_eq(
    parse([
      T::DoubleAsterisk,
      T::Text("前 "),
      T::Backtick,
      T::Text("コード"),
    ]),
    [N::Text("**"), N::Text("前 "), N::Text("`"), N::Text("コード")],
  )
}

///|
test "複数のコードを前の内容を引き継がずに組み立てる" {
  assert_eq(
    parse([
      T::Backtick,
      T::Text("一つ目"),
      T::Backtick,
      T::Text("と"),
      T::Backtick,
      T::Text("二つ目"),
      T::Backtick,
    ]),
    [N::Code("一つ目"), N::Text("と"), N::Code("二つ目")],
  )
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
test "文字列から斜体の構造を組み立てる" {
  assert_eq(parse(tokenize("*斜体*")), [N::Italic([N::Text("斜体")])])
}

///|
test "太字の中にコードの構造を組み立てる" {
  assert_eq(parse(tokenize("**太字 `コード` 続き**")), [
    N::Bold([N::Text("太字 "), N::Code("コード"), N::Text(" 続き")]),
  ])
}

///|
test "斜体の中にコードの構造を組み立てる" {
  assert_eq(parse(tokenize("*斜体 `コード` 続き*")), [
    N::Italic([N::Text("斜体 "), N::Code("コード"), N::Text(" 続き")]),
  ])
}

///|
test "コード内のアスタリスクを文字として扱う" {
  assert_eq(parse(tokenize("`*斜体*`")), [N::Code("*斜体*")])
  assert_eq(parse(tokenize("`**コード**`")), [N::Code("**コード**")])
}

///|
test "取り消し線の構造を組み立てる" {
  assert_eq(parse(tokenize("~~取り消し~~")), [
    N::Strikethrough([N::Text("取り消し")]),
  ])
}

///|
test "太字の中の取り消し線の構造を組み立てる" {
  assert_eq(parse(tokenize("**太字 ~~取り消し~~ 続き**")), [
    N::Bold([
      N::Text("太字 "),
      N::Strikethrough([N::Text("取り消し")]),
      N::Text(" 続き"),
    ]),
  ])
}

///|
test "太字の中の斜体の構造を組み立てる" {
  assert_eq(parse(tokenize("**太字 *斜体* 続き**")), [
    N::Bold([
      N::Text("太字 "),
      N::Italic([N::Text("斜体")]),
      N::Text(" 続き"),
    ]),
  ])
}

///|
test "斜体の中の太字の構造を組み立てる" {
  assert_eq(parse(tokenize("*斜体 **太字** 続き*")), [
    N::Italic([
      N::Text("斜体 "),
      N::Bold([N::Text("太字")]),
      N::Text(" 続き"),
    ]),
  ])
}

///|
test "コード内の二重チルダを取り消し線として解釈しない" {
  assert_eq(parse(tokenize("`~~取り消し~~`")), [N::Code("~~取り消し~~")])
}

///|
test "ParsingNodeをNodeへ変換する" {
  assert_eq(
    ParsingNode::{
      kind: StackType::AsteriskBold,
      children: [N::Text("太字")],
    }.to_node(),
    N::Bold([N::Text("太字")]),
  )
  assert_eq(
    ParsingNode::{
      kind: StackType::Strikethrough,
      children: [N::Text("取り消し")],
    }.to_node(),
    N::Strikethrough([N::Text("取り消し")]),
  )
}

///|
test "スタックが空なら最終結果にノードを追加する" {
  let nodes : Array[Node] = []
  push_node([], nodes, N::Text("追加"))
  assert_eq(nodes, [N::Text("追加")])
}

///|
test "スタック末尾の子にだけノードを追加する" {
  let stack = [
    ParsingNode::{ kind: StackType::AsteriskBold, children: [], },
    ParsingNode::{ kind: StackType::Strikethrough, children: [], },
  ]
  let nodes : Array[Node] = []
  push_node(stack, nodes, N::Text("追加"))
  assert_eq(stack[0].children, [])
  assert_eq(stack[1].children, [N::Text("追加")])
  assert_eq(nodes, [])
}

///|
test "空のスタックを閉じても結果は変わらない" {
  let stack : Array[ParsingNode] = []
  let nodes : Array[Node] = []
  close_node(stack, nodes)
  assert_eq(stack, [])
  assert_eq(nodes, [])
}

///|
test "最後の書式を閉じて最終結果に追加する" {
  let stack = [
    ParsingNode::{
      kind: StackType::AsteriskBold,
      children: [N::Text("太字")],
    },
  ]
  let nodes : Array[Node] = []
  close_node(stack, nodes)
  assert_eq(stack, [])
  assert_eq(nodes, [N::Bold([N::Text("太字")])])
}

///|
test "内側の書式を閉じて外側の子に追加する" {
  let stack = [
    ParsingNode::{
      kind: StackType::AsteriskBold,
      children: [N::Text("太字")],
    },
    ParsingNode::{
      kind: StackType::Strikethrough,
      children: [N::Text("取り消し")],
    },
  ]
  let nodes : Array[Node] = []
  close_node(stack, nodes)
  assert_eq(stack, [
    ParsingNode::{
      kind: StackType::AsteriskBold,
      children: [N::Text("太字"), N::Strikethrough([N::Text("取り消し")])],
    },
  ])
  assert_eq(nodes, [])
}

///|
test "スタックが空なら書式を開く" {
  let stack : Array[ParsingNode] = []
  let nodes : Array[Node] = []
  push_or_close_by_type(stack, nodes, StackType::AsteriskBold)
  assert_eq(stack, [
    ParsingNode::{ kind: StackType::AsteriskBold, children: [], },
  ])
  assert_eq(nodes, [])
}

///|
test "スタック末尾と同じ書式なら閉じる" {
  let stack = [
    ParsingNode::{
      kind: StackType::AsteriskBold,
      children: [N::Text("太字")],
    },
  ]
  let nodes : Array[Node] = []
  push_or_close_by_type(stack, nodes, StackType::AsteriskBold)
  assert_eq(stack, [])
  assert_eq(nodes, [N::Bold([N::Text("太字")])])
}

///|
test "スタック末尾と異なる書式なら内側に開く" {
  let stack = [
    ParsingNode::{
      kind: StackType::AsteriskBold,
      children: [N::Text("太字")],
    },
  ]
  let nodes : Array[Node] = []
  push_or_close_by_type(stack, nodes, StackType::Strikethrough)
  assert_eq(stack, [
    ParsingNode::{
      kind: StackType::AsteriskBold,
      children: [N::Text("太字")],
    },
    ParsingNode::{ kind: StackType::Strikethrough, children: [], },
  ])
  assert_eq(nodes, [])
}

///|
test "未閉鎖の書式を記号と子ノードとして最終結果へ戻す" {
  let stack = [
    ParsingNode::{
      kind: StackType::AsteriskBold,
      children: [N::Text("太字")],
    },
  ]
  let nodes : Array[Node] = []
  restore_unclosed_node(stack, nodes)
  assert_eq(stack, [])
  assert_eq(nodes, [N::Text("**"), N::Text("太字")])
}

///|
test "未閉鎖の内側の書式を外側の子へ戻す" {
  let stack = [
    ParsingNode::{
      kind: StackType::AsteriskBold,
      children: [N::Text("太字")],
    },
    ParsingNode::{
      kind: StackType::Strikethrough,
      children: [N::Text("取り消し")],
    },
  ]
  let nodes : Array[Node] = []
  restore_unclosed_node(stack, nodes)
  assert_eq(stack, [
    ParsingNode::{
      kind: StackType::AsteriskBold,
      children: [N::Text("太字"), N::Text("~~"), N::Text("取り消し")],
    },
  ])
  assert_eq(nodes, [])
}

///|
test "空のスタックを復元しても結果は変わらない" {
  let stack : Array[ParsingNode] = []
  let nodes : Array[Node] = []
  restore_unclosed_node(stack, nodes)
  assert_eq(stack, [])
  assert_eq(nodes, [])
}

///|
test "未閉鎖ノードの子にあるコードを保持する" {
  let stack = [
    ParsingNode::{
      kind: StackType::AsteriskBold,
      children: [N::Text("前 "), N::Code("コード")],
    },
  ]
  let nodes : Array[Node] = []
  restore_unclosed_node(stack, nodes)
  assert_eq(stack, [])
  assert_eq(nodes, [N::Text("**"), N::Text("前 "), N::Code("コード")])
}

///|
test "取り消し線の中に太字の構造を組み立てる" {
  assert_eq(parse(tokenize("~~取り消し **太字** 続き~~")), [
    N::Strikethrough([
      N::Text("取り消し "),
      N::Bold([N::Text("太字")]),
      N::Text(" 続き"),
    ]),
  ])
}

///|
test "文字列から未閉鎖の取り消し線を記号と文字へ戻す" {
  assert_eq(parse(tokenize("~~取り消し")), [
    N::Text("~~"),
    N::Text("取り消し"),
  ])
}

///|
test "複数の未閉鎖書式を元の順序で文字へ戻す" {
  assert_eq(parse(tokenize("**前 ~~後")), [
    N::Text("**"),
    N::Text("前 "),
    N::Text("~~"),
    N::Text("後"),
  ])
}

///|
test "アンダースコアの斜体を組み立てる" {
  assert_eq(parse(tokenize("_斜体_")), [N::Italic([N::Text("斜体")])])
}

///|
test "アンダースコアの太字を組み立てる" {
  assert_eq(parse(tokenize("__太字__")), [N::Bold([N::Text("太字")])])
}

///|
test "アンダースコアの斜体が未閉鎖の場合は記号と文字へ戻す" {
  assert_eq(parse(tokenize("_斜体")), [N::Text("_"), N::Text("斜体")])
}

///|
test "アンダースコアの太字が未閉鎖の場合は記号と文字へ戻す" {
  assert_eq(parse(tokenize("__太字")), [N::Text("__"), N::Text("太字")])
}

///|
test "アスタリスクで開いた斜体をアンダースコアでは閉じない" {
  assert_eq(parse(tokenize("*斜体_")), [
    N::Text("*"),
    N::Text("斜体"),
    N::Text("_"),
  ])
}

///|
test "アンダースコアで開いた斜体をアスタリスクでは閉じない" {
  assert_eq(parse(tokenize("_斜体*")), [
    N::Text("_"),
    N::Text("斜体"),
    N::Text("*"),
  ])
}

///|
test "太字も開始と異なる記号では閉じない" {
  assert_eq(parse(tokenize("**太字__")), [
    N::Text("**"),
    N::Text("太字"),
    N::Text("__"),
  ])
  assert_eq(parse(tokenize("__太字**")), [
    N::Text("__"),
    N::Text("太字"),
    N::Text("**"),
  ])
}

///|
test "コード外ではエスケープのバックスラッシュを取り除く" {
  assert_eq(parse([T::Escaped('_')]), [N::Text("_")])
}

///|
test "コード内ではエスケープのバックスラッシュを保持する" {
  assert_eq(parse([T::Backtick, T::Escaped('_'), T::Backtick]), [N::Code("\\_")])
}

///|
test "リンクのラベルとURLを正しく解析する" {
  assert_eq(parse(tokenize("[ラベル](url)")), [
    N::Link(label="ラベル", url="url"),
  ])
}

///|
test "リンクのラベルが未閉鎖の場合は文字へ戻す" {
  assert_eq(parse(tokenize("[ラベル")), [N::Text("[ラベル")])
}

///|
test "リンクのラベルが閉鎖されURLが未開の場合は文字へ戻す" {
  assert_eq(parse(tokenize("[ラベル]")), [N::Text("[ラベル]")])
}

///|
test "リンクのラベルが閉鎖されURLが未開で文字が続く場合は文字へ戻す" {
  assert_eq(parse(tokenize("[ラベル]だけ")), [
    N::Text("[ラベル]"),
    N::Text("だけ"),
  ])
}

///|
test "リンクのラベルが閉じていて後に斜体が続く場合" {
  assert_eq(parse(tokenize("[ラベル]*斜体*")), [
    N::Text("[ラベル]"),
    N::Italic([N::Text("斜体")]),
  ])
}

///|
test "リンクのURLが未閉鎖の場合は文字へ戻す" {
  assert_eq(parse(tokenize("[ラベル](url")), [N::Text("[ラベル](url")])
}

///|
test "リンクではない括弧はテキストとして扱う" {
  assert_eq(parse(tokenize("普通の(文章)")), [
    N::Text("普通の"),
    N::Text("("),
    N::Text("文章"),
    N::Text(")"),
  ])
  assert_eq(parse(tokenize("a]b")), [N::Text("a"), N::Text("]"), N::Text("b")])
  assert_eq(parse(tokenize("a(b")), [N::Text("a"), N::Text("("), N::Text("b")])
  assert_eq(parse(tokenize("a)b")), [N::Text("a"), N::Text(")"), N::Text("b")])
}

///|
test "リンクのラベルに括弧が含まれる場合" {
  assert_eq(parse(tokenize("[公式(日本語)](url)")), [
    N::Link(label="公式(日本語)", url="url"),
  ])
}

///|
test "リンクのラベルにエスケープが含まれる場合" {
  assert_eq(parse(tokenize("[名\\_前](url)")), [
    N::Link(label="名_前", url="url"),
  ])
}

///|
test "リンクのURLにアンダースコアが含まれる場合" {
  assert_eq(parse(tokenize("[公式](https://horyu.github.io/my_page)")), [
    N::Link(label="公式", url="https://horyu.github.io/my_page"),
  ])
}

///|
test "リンクのURLに複数の記号が含まれる場合" {
  assert_eq(parse(tokenize("[公式](https://horyu.github.io/a__b*~)")), [
    N::Link(label="公式", url="https://horyu.github.io/a__b*~"),
  ])
}

///|
test "リンクのラベルに複数の記号が含まれる場合" {
  assert_eq(parse(tokenize("[名*前*_そのまま](url)")), [
    N::Link(label="名*前*_そのまま", url="url"),
  ])
}

///|
test "未完成のリンクを文字列へ戻す" {
  let label = StringBuilder()
  label.write_string("ラベル")
  assert_eq(LinkState::InLabel(label~).to_string(), "[ラベル")
  assert_eq(
    LinkState::BeforeLeftParen(label="ラベル").to_string(),
    "[ラベル]",
  )
  let url = StringBuilder()
  url.write_string("url")
  assert_eq(
    LinkState::InUrl(label="ラベル", url~).to_string(),
    "[ラベル](url",
  )
}
