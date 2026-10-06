///|
fn repeat_twice(text : String) -> String {
  text + text
}

///|
fn main {
  let text = "hello"
  let repeated = repeat_twice(text)
  println(repeated)
}
