///|
#warnings("-unused_value")
fn to_html(node : Node) -> String {
  match node {
    Text(s) => escape_html(s)
    Bold(nodes) => "<b>" + nodes.map(to_html).join("") + "</b>"
    Strikethrough(nodes) => "<s>" + nodes.map(to_html).join("") + "</s>"
    Code(s) => "<code>" + escape_html(s) + "</code>"
  }
}
