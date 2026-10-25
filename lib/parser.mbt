///|
enum Node {
  Text(String)
  Bold(Array[Node])
  Code(String)
} derive(Eq, Debug)

///|
#deprecated
pub extend Node with Eq::{equal, not_equal}

///|
#deprecated
pub extend Node with Debug::{to_repr}

///|
fn to_html(node : Node) -> String {
  match node {
    Text(s) => escape_html(s)
    Bold(nodes) => "<b>" + nodes.map(to_html).join("") + "</b>"
    Code(s) => "<code>" + escape_html(s) + "</code>"
  }
}

///|
#warnings("-unused_value")
fn parse(tokens : Array[Token]) -> Array[Node] {
  let nodes : Array[Node] = []
  let mut bold = false
  let mut bold_tmp : Array[Node] = []
  let mut code = false
  let mut code_tmp = ""
  for token in tokens {
    if code {
      match token {
        Text(s) => code_tmp += s
        DoubleAsterisk => code_tmp += "**"
        Backtick => {
          push_by_bold(bold, bold_tmp, nodes, Code(code_tmp))
          code_tmp = ""
          code = false
        }
      }
      continue
    }
    match token {
      Text(s) => push_by_bold(bold, bold_tmp, nodes, Text(s))
      DoubleAsterisk => {
        if bold {
          nodes.push(Bold(bold_tmp))
          bold_tmp = []
        }
        bold = !bold
      }
      Backtick => code = true
    }
  }
  // 未閉鎖のコードを先に戻し、その後で未閉鎖の太字を戻す。
  if code {
    push_by_bold(bold, bold_tmp, nodes, Node::Text("`"))
    push_by_bold(bold, bold_tmp, nodes, Node::Text(code_tmp))
  }
  if bold {
    nodes.push(Node::Text("**"))
    nodes.push_iter(bold_tmp.iter())
  }
  nodes
}

///|
fn push_by_bold(
  bold : Bool,
  bold_tmp : Array[Node],
  nodes : Array[Node],
  node : Node,
) -> Unit {
  if bold {
    bold_tmp.push(node)
  } else {
    nodes.push(node)
  }
}
