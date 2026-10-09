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
fn render_bold(text : StringView) -> String {
  let mut remaining = text
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

///|
fn render_links(text : StringView) -> String {
  let mut remaining = text
  let mut html = ""
  while true {
    match remaining.split_once("[") {
      None => {
        html += render_bold(remaining)
        break
      }
      Some((before, after)) =>
        match after.split_once("](") {
          None => {
            html += render_bold(remaining)
            break
          }
          Some((label, after_label)) =>
            match after_label.split_once(")") {
              None => {
                html += render_bold(remaining)
                break
              }
              Some((url, rest)) => {
                html += render_bold(before)
                if url.has_prefix("https://") || url.has_prefix("http://") {
                  html += "<a href=\"" +
                    escape_html(url) +
                    "\">" +
                    escape_html(label) +
                    "</a>"
                } else {
                  html += "[" +
                    escape_html(label) +
                    "](" +
                    escape_html(url) +
                    ")"
                }
                remaining = rest
              }
            }
        }
    }
  }
  html
}

///|
fn render_inline(text : StringView) -> String {
  let mut remaining = text
  let mut html = ""
  while true {
    match remaining.split_once("`") {
      None => {
        html += render_links(remaining)
        break
      }
      Some((before, after)) =>
        match after.split_once("`") {
          None => {
            html += render_links(remaining)
            break
          }
          Some((code, rest)) => {
            html += render_links(before)
            html += "<code data-stringify-type=\"code\">" +
              escape_html(code) +
              "</code>"
            remaining = rest
          }
        }
    }
  }
  html
}

///|
fn render_blocks(text : StringView) -> String {
  let lines = text.split("\n").to_array()
  let mut index = 0
  let mut html = ""
  while index < lines.length() {
    let is_quote = lines[index].has_prefix(">")
    let mut content = ""
    let start = index
    while index < lines.length() && lines[index].has_prefix(">") == is_quote {
      if index > start {
        content += "\n"
      }
      let line = if is_quote {
        let (_, after_marker) = lines[index].split_at(1)
        match after_marker.strip_prefix(" ") {
          Some(rest) => rest
          None => after_marker
        }
      } else {
        lines[index]
      }
      content += line.to_owned()
      index += 1
    }
    if start > 0 {
      html += "\n"
    }
    let rendered = render_inline(content.to_string_view())
    html += if is_quote {
      "<blockquote data-stringify-type=\"quote\">" + rendered + "</blockquote>"
    } else {
      rendered
    }
  }
  html
}

///|
pub fn markdown_to_slack_html(markdown : String) -> String {
  let normalized = markdown
    .replace_all(old="\r\n", new="\n")
    .replace_all(old="\r", new="\n")
  render_blocks(normalized.to_string_view()).replace_all(old="\n", new="<br>")
}
