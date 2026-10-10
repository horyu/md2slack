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
/// 戻り値は Some((階層の深さ, 項目の本文))。箇条書きの行でなければ None。
/// 深さは先頭のスペース2個につき1増える。本文には先頭のスペースと「- 」を含まない。
fn list_item(line : StringView) -> (Int, StringView)? {
  let mut remaining = line
  let mut depth = 0
  while remaining.has_prefix("  ") {
    let (_, rest) = remaining.split_at(2)
    remaining = rest
    depth += 1
  }
  match remaining.strip_prefix("- ") {
    Some(item) => Some((depth, item))
    None => None
  }
}

///|
/// 戻り値は (生成したHTML, 次に処理する行の添字)。
/// 添字は0から始まり、処理済みの最後の行ではなく、未処理の次の行を指す。
/// 最後まで処理した場合、添字は lines.length() になる。
fn render_list(
  lines : Array[StringView],
  start : Int,
  depth : Int,
) -> (String, Int) {
  let mut index = start
  let mut html = "<ul data-stringify-type=\"unordered-list\" data-list-tree=\"true\" data-indent=\"\{depth}\" data-border=\"0\">"
  while index < lines.length() {
    match list_item(lines[index]) {
      Some((item_depth, item)) if item_depth == depth => {
        html += "<li data-stringify-indent=\"\{depth}\" data-stringify-border=\"0\">" +
          render_inline(item)
        index += 1
        if index < lines.length() {
          match list_item(lines[index]) {
            Some((child_depth, _)) if child_depth == depth + 1 => {
              let (children, next) = render_list(lines, index, child_depth)
              html += children
              index = next
            }
            _ => ()
          }
        }
        html += "</li>"
      }
      _ => break
    }
  }
  (html + "</ul>", index)
}

///|
fn render_blocks(text : StringView) -> String {
  let lines = text.split("\n").to_array()
  let mut index = 0
  let mut html = ""
  while index < lines.length() {
    if index > 0 {
      html += "\n"
    }
    if lines[index].has_prefix("- ") {
      let (list, next) = render_list(lines, index, 0)
      html += list
      index = next
      continue
    }
    let is_quote = lines[index].has_prefix(">")
    let mut content = ""
    let start = index
    while index < lines.length() &&
          lines[index].has_prefix(">") == is_quote &&
          !lines[index].has_prefix("- ") {
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
