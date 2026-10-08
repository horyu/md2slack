///|
fn main {
  let markdown = "前 **太字** 後"
  let html = @lib.markdown_to_slack_html(markdown)
  println(html)
}
