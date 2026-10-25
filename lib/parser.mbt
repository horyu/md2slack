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
    match token {
      Text(s) => {
        if code {
          code_tmp += s
        } else if bold {
          bold_tmp.push(Text(s))
        } else {
          nodes.push(Text(s))
        }
      }
      DoubleAsterisk => {
        if code {
          code_tmp += "**"
          continue
        }
        if bold {
          nodes.push(Bold(bold_tmp))
          bold_tmp = []
        }
        bold = !bold
      }
      Backtick => {
        if code {
          if bold {
            bold_tmp.push(Code(code_tmp))
          } else {
            nodes.push(Code(code_tmp))
          }
          code_tmp = ""
        }
        code = !code
      }
    }
  }
  // 未閉鎖のコードを先に戻し、その後で未閉鎖の太字を戻す。
  if code {
    if bold {
      bold_tmp.push(Node::Text("`"))
      bold_tmp.push(Node::Text(code_tmp))
    } else {
      nodes.push(Node::Text("`"))
      nodes.push(Node::Text(code_tmp))
    }
  }
  if bold {
    nodes.push(Node::Text("**"))
    nodes.push_iter(bold_tmp.iter())
  }
  nodes
}
