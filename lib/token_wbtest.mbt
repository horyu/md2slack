///|
test "文字トークンを元の文字列へ戻す" {
  let t = Token::Text("hello")
  assert_eq(t.to_string(), "hello")
}

///|
test "エスケープトークンをバックスラッシュ付きの文字列へ戻す" {
  let t = Token::Escaped('_')
  assert_eq(t.to_string(), "\\_")
}

///|
test "記号トークンを元の文字列へ戻す" {
  assert_eq(Token::SingleAsterisk.to_string(), "*")
  assert_eq(Token::DoubleAsterisk.to_string(), "**")
  assert_eq(Token::SingleUnderscore.to_string(), "_")
  assert_eq(Token::DoubleUnderscore.to_string(), "__")
  assert_eq(Token::DoubleTilde.to_string(), "~~")
  assert_eq(Token::Backtick.to_string(), "`")
  assert_eq(Token::LeftBracket.to_string(), "[")
  assert_eq(Token::RightBracket.to_string(), "]")
  assert_eq(Token::LeftParen.to_string(), "(")
  assert_eq(Token::RightParen.to_string(), ")")
}
