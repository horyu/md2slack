///|
enum Node {
  Text(String)
  Bold(Array[Node])
  Strikethrough(Array[Node])
  Code(String)
} derive(Eq, Debug)

///|
#deprecated
pub extend Node with Eq::{equal, not_equal}

///|
#deprecated
pub extend Node with Debug::{to_repr}
