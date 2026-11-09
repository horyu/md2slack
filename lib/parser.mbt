///|
#derive(Eq, Debug)
enum StackType {
  AsteriskItalic
  AsteriskBold
  UnderscoreItalic
  UnderscoreBold
  Strikethrough
}

///|
pub extend StackType with Eq::{equal, not_equal}

///|
pub extend StackType with Debug::{to_repr}

///|
#derive(Eq, Debug)
struct ParsingNode {
  kind : StackType
  children : Array[Node]
}

///|
pub extend ParsingNode with Eq::{equal, not_equal}

///|
pub extend ParsingNode with Debug::{to_repr}

///|
fn ParsingNode::to_node(self : Self) -> Node {
  match self.kind {
    AsteriskItalic | UnderscoreItalic => Node::Italic(self.children)
    AsteriskBold | UnderscoreBold => Node::Bold(self.children)
    Strikethrough => Node::Strikethrough(self.children)
  }
}

///|
priv enum LinkState {
  InLabel(label~ : StringBuilder)
  BeforeLeftParen(label~ : String)
  InUrl(label~ : String, url~ : StringBuilder)
}

///|
fn LinkState::to_string(self : Self) -> String {
  match self {
    LinkState::InLabel(label~) => "[" + label.to_string()
    LinkState::BeforeLeftParen(label~) => "[" + label + "]"
    LinkState::InUrl(label~, url~) => "[" + label + "](" + url.to_string()
  }
}

///|
#warnings("-unused_value")
fn parse(tokens : Array[Token]) -> Array[Node] {
  let nodes : Array[Node] = []
  let stack : Array[ParsingNode] = []
  let mut code : StringBuilder? = None
  let mut link_state : LinkState? = None
  for token in tokens {
    if code is Some(code_tmp) {
      match token {
        Backtick => {
          push_node(stack, nodes, Node::Code(code_tmp.to_string()))
          code = None
        }
        Escaped('`') => {
          // コード内ではエスケープを解釈せず、バックスラッシュを残して閉じる。
          code_tmp.write_char('\\')
          push_node(stack, nodes, Node::Code(code_tmp.to_string()))
          code = None
        }
        _ => code_tmp.write_string(token.to_string())
      }
      continue
    }
    if link_state is Some(ls) {
      match ls {
        InLabel(label~) => {
          match token {
            RightBracket =>
              link_state = Some(
                LinkState::BeforeLeftParen(label=label.to_string()),
              )
            Escaped(c) => label.write_string(c.to_string())
            _ => label.write_string(token.to_string())
          }
          continue
        }
        BeforeLeftParen(label~) =>
          if token == LeftParen {
            link_state = Some(LinkState::InUrl(label~, url=StringBuilder()))
            continue
          } else {
            push_node(stack, nodes, Node::Text(ls.to_string()))
            link_state = None
            // 今回のトークンは、リンク外の通常処理へ渡す。
          }
        InUrl(label~, url~) => {
          if token == RightParen {
            push_node(stack, nodes, Node::Link(label~, url=url.to_string()))
            link_state = None
          } else {
            url.write_string(token.to_string())
          }
          continue
        }
      }
    }
    match token {
      Text(s) => push_node(stack, nodes, Node::Text(s))
      Escaped(c) => push_node(stack, nodes, Node::Text(c.to_string()))
      SingleAsterisk =>
        push_or_close_by_type(stack, nodes, StackType::AsteriskItalic)
      DoubleAsterisk =>
        push_or_close_by_type(stack, nodes, StackType::AsteriskBold)
      SingleUnderscore =>
        push_or_close_by_type(stack, nodes, StackType::UnderscoreItalic)
      DoubleUnderscore =>
        push_or_close_by_type(stack, nodes, StackType::UnderscoreBold)
      DoubleTilde =>
        push_or_close_by_type(stack, nodes, StackType::Strikethrough)
      Backtick => code = Some(StringBuilder())
      LeftBracket =>
        link_state = Some(LinkState::InLabel(label=StringBuilder()))
      RightBracket => push_node(stack, nodes, Node::Text("]"))
      LeftParen => push_node(stack, nodes, Node::Text("("))
      RightParen => push_node(stack, nodes, Node::Text(")"))
    }
  }
  // コードとリンク候補を文字へ戻してから、外側の書式を内側から順に戻す。
  if code is Some(code_tmp) {
    push_node(stack, nodes, Node::Text("`"))
    push_node(stack, nodes, Node::Text(code_tmp.to_string()))
  }
  if link_state is Some(ls) {
    push_node(stack, nodes, Node::Text(ls.to_string()))
  }
  restore_unclosed_nodes(stack, nodes)
  nodes
}

///|
// 正しく対応する入れ子を対象とする。記号が交差する場合の解釈は未対応。
fn push_or_close_by_type(
  stack : Array[ParsingNode],
  nodes : Array[Node],
  stack_type : StackType,
) -> Unit {
  if stack.last() is Some(parsing_node) && parsing_node.kind == stack_type {
    close_node(stack, nodes)
  } else {
    stack.push(ParsingNode::{ kind: stack_type, children: [], })
  }
}

///|
fn push_node(
  stack : Array[ParsingNode],
  nodes : Array[Node],
  node : Node,
) -> Unit {
  if stack.last() is Some(parsing_node) {
    parsing_node.children.push(node)
  } else {
    nodes.push(node)
  }
}

///|
fn close_node(stack : Array[ParsingNode], nodes : Array[Node]) -> Unit {
  if stack.pop() is Some(parsing_node) {
    push_node(stack, nodes, parsing_node.to_node())
  }
}

///|
fn restore_unclosed_nodes(
  stack : Array[ParsingNode],
  nodes : Array[Node],
) -> Unit {
  while stack.pop() is Some(parsing_node) {
    push_node(
      stack,
      nodes,
      match parsing_node.kind {
        StackType::AsteriskItalic => Node::Text("*")
        StackType::AsteriskBold => Node::Text("**")
        StackType::UnderscoreItalic => Node::Text("_")
        StackType::UnderscoreBold => Node::Text("__")
        StackType::Strikethrough => Node::Text("~~")
      },
    )
    for child in parsing_node.children {
      push_node(stack, nodes, child)
    }
  }
}
