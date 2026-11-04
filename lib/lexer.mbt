///|
enum Token {
  Text(String)
  Escaped(Char)
  SingleAsterisk
  DoubleAsterisk
  SingleUnderscore
  DoubleUnderscore
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
    let matched_token = match (input[pos], input.get(pos + 1)) {
      // 対象をASCII記号に限定しているため、Charへの変換は必ず成功する。
      ('\\', Some(c)) if c == '*' || c == '_' || c == '~' || c == '\\' =>
        Some((Token::Escaped(c.to_char().unwrap()), 2))
      ('*', Some('*')) => Some((Token::DoubleAsterisk, 2))
      ('*', _) => Some((Token::SingleAsterisk, 1))
      ('~', Some('~')) => Some((Token::DoubleTilde, 2))
      ('_', Some('_')) => Some((Token::DoubleUnderscore, 2))
      ('_', _) => Some((Token::SingleUnderscore, 1))
      ('`', _) => Some((Token::Backtick, 1))
      _ => None
    }
    if matched_token is Some((token, advance)) {
      if text_start < pos {
        tokens.push(Token::Text(input[text_start:pos].to_owned()))
      }
      tokens.push(token)
      pos += advance
      text_start = pos
    } else {
      pos += 1
    }
  }
  if text_start < pos {
    tokens.push(Token::Text(input[text_start:pos].to_owned()))
  }
  tokens
}
