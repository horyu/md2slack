///|
test "トークン化" {
  assert_eq(tokenize(""), [])
  assert_eq(tokenize("こんにちは"), [Token::Text("こんにちは")])
  assert_eq(tokenize("a*b"), [Token::Text("a*b")])
  assert_eq(tokenize("**太字"), [Token::Delimiter, Token::Text("太字")])
  assert_eq(tokenize("****"), [Token::Delimiter, Token::Delimiter])
  assert_eq(tokenize("前 **太字** 後"), [
    Token::Text("前 "),
    Token::Delimiter,
    Token::Text("太字"),
    Token::Delimiter,
    Token::Text(" 後"),
  ])
}
