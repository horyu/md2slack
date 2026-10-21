///|
enum Token {
  Delimiter
  Text(String)
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
  let parts = input.split("**").to_array()
  let len = parts.length()
  for (i, part) in parts.iter2() {
    if !part.is_empty() {
      tokens.push(Token::Text(part.to_owned()))
    }
    if i + 1 < len {
      tokens.push(Token::Delimiter)
    }
  }
  tokens
}
