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
  LeftBracket
  RightBracket
  LeftParen
  RightParen
} derive(Eq, Debug)

///|
#deprecated
pub extend Token with Eq::{equal, not_equal}

///|
#deprecated
pub extend Token with Debug::{to_repr}

///|
/// 入力時の文字列表現を返す。エスケープのバックスラッシュも保持する。
fn Token::to_string(self : Self) -> String {
  match self {
    Token::Text(s) => s
    Token::Escaped(c) => "\\\{c}"
    Token::SingleAsterisk => "*"
    Token::DoubleAsterisk => "**"
    Token::SingleUnderscore => "_"
    Token::DoubleUnderscore => "__"
    Token::DoubleTilde => "~~"
    Token::Backtick => "`"
    Token::LeftBracket => "["
    Token::RightBracket => "]"
    Token::LeftParen => "("
    Token::RightParen => ")"
  }
}
