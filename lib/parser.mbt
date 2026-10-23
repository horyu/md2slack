///|
enum Node {
  Text(String)
  Bold(Array[Node])
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
    Text(s) =>
      s
      .iter()
      .map(c => {
        match c {
          '<' => "&lt;"
          '>' => "&gt;"
          '&' => "&amp;"
          '"' => "&quot;"
          '\'' => "&#39;"
          _ => c.to_string()
        }
      })
      .join("")
    Bold(nodes) => "<b>" + nodes.map(to_html).join("") + "</b>"
  }
}

///|
#warnings("-unused_value")
fn parse(tokens : Array[Token]) -> Array[Node] {
  let nodes : Array[Node] = []
  let mut tmp : Array[Node] = []
  let mut bold = false
  for token in tokens {
    match token {
      Delimiter => {
        if bold {
          nodes.push(Bold(tmp))
          tmp = []
        }
        bold = !bold
      }
      Text(s) => if bold { tmp.push(Text(s)) } else { nodes.push(Text(s)) }
    }
  }
  if bold {
    nodes.push(Node::Text("**"))
    nodes.push_iter(tmp.iter())
  }
  nodes
}
