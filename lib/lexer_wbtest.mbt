///|
test "空文字列や記号のない文字列をトークン化する" {
  assert_eq(tokenize(""), [])
  assert_eq(tokenize("こんにちは"), [T::Text("こんにちは")])
  assert_eq(tokenize("a*b"), [T::Text("a*b")])
}

///|
test "二重アスタリスクを文字と区別してトークン化する" {
  assert_eq(tokenize("**太字"), [T::DoubleAsterisk, T::Text("太字")])
  assert_eq(tokenize("****"), [T::DoubleAsterisk, T::DoubleAsterisk])
  assert_eq(tokenize("前 **太字** 後"), [
    T::Text("前 "),
    T::DoubleAsterisk,
    T::Text("太字"),
    T::DoubleAsterisk,
    T::Text(" 後"),
  ])
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
