///|
#derive(Eq, Debug)
enum Node {
  Text(String)
  Bold(Array[Node])
  Strikethrough(Array[Node])
  Italic(Array[Node])
  Code(String)
  Link(label~ : String, url~ : String)
}

///|
pub extend Node with Eq::{equal, not_equal}

///|
pub extend Node with Debug::{to_repr}
