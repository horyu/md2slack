///|
#warnings("-unused_value")
fn Node::to_html(self : Self) -> String {
  match self {
    Text(s) => escape_html(s)
    Bold(nodes) => "<b>" + nodes.map(n => n.to_html()).join("") + "</b>"
    Strikethrough(nodes) =>
      "<s>" + nodes.map(n => n.to_html()).join("") + "</s>"
    Code(s) => "<code>" + escape_html(s) + "</code>"
  }
}
