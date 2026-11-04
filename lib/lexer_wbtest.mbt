///|
test "空文字列や記号のない文字列をトークン化する" {
  assert_eq(tokenize(""), [])
  assert_eq(tokenize("こんにちは"), [T::Text("こんにちは")])
}

///|
test "二重アスタリスクを文字と区別してトークン化する" {
  assert_eq(tokenize("**太字"), [T::DoubleAsterisk, T::Text("太字")])
  assert_eq(tokenize("****"), [T::DoubleAsterisk, T::DoubleAsterisk])
  assert_eq(tokenize("**太字**"), [
    T::DoubleAsterisk,
    T::Text("太字"),
    T::DoubleAsterisk,
  ])
  assert_eq(tokenize("前 **太字** 後"), [
    T::Text("前 "),
    T::DoubleAsterisk,
    T::Text("太字"),
    T::DoubleAsterisk,
    T::Text(" 後"),
  ])
}

///|
test "単一アスタリスクを文字と区別してトークン化する" {
  assert_eq(tokenize("*斜体*"), [
    T::SingleAsterisk,
    T::Text("斜体"),
    T::SingleAsterisk,
  ])
  assert_eq(tokenize("a*b"), [T::Text("a"), T::SingleAsterisk, T::Text("b")])
}

///|
test "バッククォートを文字と区別してトークン化する" {
  assert_eq(tokenize("`コード`"), [
    T::Backtick,
    T::Text("コード"),
    T::Backtick,
  ])
}

///|
test "二重アスタリスクとバッククォートの混在をトークン化する" {
  assert_eq(tokenize("**太字 `コード` 続き**"), [
    T::DoubleAsterisk,
    T::Text("太字 "),
    T::Backtick,
    T::Text("コード"),
    T::Backtick,
    T::Text(" 続き"),
    T::DoubleAsterisk,
  ])
}

///|
test "単一アンダースコアを文字と区別してトークン化する" {
  assert_eq(tokenize("_斜体_"), [
    T::SingleUnderscore,
    T::Text("斜体"),
    T::SingleUnderscore,
  ])
  assert_eq(tokenize("a_b"), [T::Text("a"), T::SingleUnderscore, T::Text("b")])
}

///|
test "二重アンダースコアを文字と区別してトークン化する" {
  assert_eq(tokenize("__太字__"), [
    T::DoubleUnderscore,
    T::Text("太字"),
    T::DoubleUnderscore,
  ])
  assert_eq(tokenize("a__b"), [T::Text("a"), T::DoubleUnderscore, T::Text("b")])
}

///|
test "二重チルダを文字と区別してトークン化する" {
  assert_eq(tokenize("~~取り消し~~"), [
    T::DoubleTilde,
    T::Text("取り消し"),
    T::DoubleTilde,
  ])
}

///|
test "1つのチルダを文字としてトークン化する" {
  assert_eq(tokenize("a~b"), [T::Text("a~b")])
}

///|
test "絵文字の直後の記号を正しい位置でトークン化する" {
  assert_eq(tokenize("😀**太字**"), [
    T::Text("😀"),
    T::DoubleAsterisk,
    T::Text("太字"),
    T::DoubleAsterisk,
  ])
  assert_eq(tokenize("😀~~取り消し~~"), [
    T::Text("😀"),
    T::DoubleTilde,
    T::Text("取り消し"),
    T::DoubleTilde,
  ])
}

///|
test "バックスラッシュでエスケープされた記号をトークン化する" {
  assert_eq(tokenize("\\*"), [T::Escaped('*')])
  assert_eq(tokenize("a\\*b"), [T::Text("a"), T::Escaped('*'), T::Text("b")])
  assert_eq(tokenize("\\_"), [T::Escaped('_')])
  assert_eq(tokenize("a\\_b"), [T::Text("a"), T::Escaped('_'), T::Text("b")])
  assert_eq(tokenize("\\~"), [T::Escaped('~')])
  assert_eq(tokenize("a\\~b"), [T::Text("a"), T::Escaped('~'), T::Text("b")])
  assert_eq(tokenize("\\\\"), [T::Escaped('\\')])
  assert_eq(tokenize("a\\\\b"), [T::Text("a"), T::Escaped('\\'), T::Text("b")])
}

///|
test "エスケープ対象外の文字の前ではバックスラッシュも保持する" {
  assert_eq(tokenize("\\a"), [T::Text("\\a")])
}

///|
test "末尾のバックスラッシュは文字としてトークン化する" {
  assert_eq(tokenize("\\"), [T::Text("\\")])
}
