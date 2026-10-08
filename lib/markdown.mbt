///|
fn escape_html(text : StringView) -> String {
  text
  .to_owned()
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
  .replace_all(old="'", new="&#39;")
}

///|
pub fn markdown_to_slack_html(markdown : String) -> String {
  let mut remaining = markdown.to_string_view()
  let mut html = ""
  while true {
    match remaining.split_once("**") {
      None => {
        html += escape_html(remaining)
        break
      }
      Some((before, after)) =>
        match after.split_once("**") {
          None => {
            html += escape_html(remaining)
            break
          }
          Some((bold, rest)) => {
            html += escape_html(before)
            html += "<b data-stringify-type=\"bold\">" +
              escape_html(bold) +
              "</b>"
            remaining = rest
          }
        }
    }
  }
  html
}
