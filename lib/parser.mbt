///|
enum StackType {
  Bold
  Strikethrough
} derive(Eq, Debug)

///|
#deprecated
pub extend StackType with Eq::{equal, not_equal}

///|
#deprecated
pub extend StackType with Debug::{to_repr}

///|
struct ParsingNode {
  kind : StackType
  children : Array[Node]
} derive(Eq, Debug)

///|
#deprecated
pub extend ParsingNode with Eq::{equal, not_equal}

///|
#deprecated
pub extend ParsingNode with Debug::{to_repr}

///|
fn to_node(parsing_node : ParsingNode) -> Node {
  match parsing_node.kind {
    Bold => Bold(parsing_node.children)
    Strikethrough => Strikethrough(parsing_node.children)
  }
}

///|
#warnings("-unused_value")
fn parse(tokens : Array[Token]) -> Array[Node] {
  let nodes : Array[Node] = []
  let stack : Array[ParsingNode] = []
  let mut code = false
  let mut code_tmp = ""
  for token in tokens {
    if code {
      match token {
        Text(s) => code_tmp += s
        DoubleAsterisk => code_tmp += "**"
        DoubleTilde => code_tmp += "~~"
        Backtick => {
          push_node(stack, nodes, Node::Code(code_tmp))
          code_tmp = ""
          code = false
        }
      }
      continue
    }
    match token {
      Text(s) => push_node(stack, nodes, Node::Text(s))
      DoubleAsterisk => push_or_close_by_type(stack, nodes, StackType::Bold)
      DoubleTilde =>
        push_or_close_by_type(stack, nodes, StackType::Strikethrough)
      Backtick => code = true
    }
  }
  // 未閉鎖のコードを先に戻し、その後で書式を内側から順に戻す。
  if code {
    push_node(stack, nodes, Node::Text("`"))
    push_node(stack, nodes, Node::Text(code_tmp))
  }
  while !stack.is_empty() {
    restore_unclosed_node(stack, nodes)
  }
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
    push_node(stack, nodes, to_node(parsing_node))
  }
}

///|
fn restore_unclosed_node(
  stack : Array[ParsingNode],
  nodes : Array[Node],
) -> Unit {
  if stack.pop() is Some(parsing_node) {
    push_node(
      stack,
      nodes,
      match parsing_node.kind {
        StackType::Bold => Node::Text("**")
        StackType::Strikethrough => Node::Text("~~")
      },
    )
    for child in parsing_node.children {
      push_node(stack, nodes, child)
    }
  }
}
