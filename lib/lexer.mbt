///|
enum Token {
  Text(String)
  DoubleAsterisk
  DoubleTilde
  Backtick
} derive(Eq, Debug)

///|
#deprecated
pub extend Token with Eq::{equal, not_equal}

///|
#deprecated
pub extend Token with Debug::{to_repr}

///|
// 既存の変換処理に接続するまで、未使用関数の警告を抑制する。
#warnings("-unused_value")
fn tokenize(input : String) -> Array[Token] {
  let tokens : Array[Token] = []
  let len = input.length()
  let mut pos = 0
  let mut text_start = 0
  while pos < len {
    if input[pos:].has_prefix("**") {
      if text_start < pos {
        tokens.push(Token::Text(input[text_start:pos].to_owned()))
      }
      text_start = pos + 2
      tokens.push(Token::DoubleAsterisk)
      pos += 2
    } else if input[pos:].has_prefix("~~") {
      if text_start < pos {
        tokens.push(Token::Text(input[text_start:pos].to_owned()))
      }
      text_start = pos + 2
      tokens.push(Token::DoubleTilde)
      pos += 2
    } else if input[pos] == '`' {
      if text_start < pos {
        tokens.push(Token::Text(input[text_start:pos].to_owned()))
      }
      text_start = pos + 1
      tokens.push(Token::Backtick)
      pos += 1
    } else {
      pos += 1
    }
  }
  if text_start < pos {
    tokens.push(Token::Text(input[text_start:pos].to_owned()))
  }
  tokens
}
