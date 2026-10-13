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
fn render_italic(text : StringView) -> String {
  let mut remaining = text
  let mut html = ""
  while true {
    match remaining.split_once("*") {
      None => {
        html += escape_html(remaining)
        break
      }
      Some((before, after)) =>
        match after.split_once("*") {
          None => {
            html += escape_html(remaining)
            break
          }
          Some((italic, rest)) => {
            html += escape_html(before)
            if italic.is_empty() {
              html += "**"
            } else {
              html += "<i data-stringify-type=\"italic\">" +
                escape_html(italic) +
                "</i>"
            }
            remaining = rest
          }
        }
    }
  }
  html
}

///|
fn render_strike(text : StringView) -> String {
  let mut remaining = text
  let mut html = ""
  while true {
    match remaining.split_once("~~") {
      None => {
        html += render_italic(remaining)
        break
      }
      Some((before, after)) =>
        match after.split_once("~~") {
          None => {
            html += render_italic(remaining)
            break
          }
          Some((strike, rest)) => {
            html += render_italic(before)
            html += "<s data-stringify-type=\"strike\">" +
              escape_html(strike) +
              "</s>"
            remaining = rest
          }
        }
    }
  }
  html
}

///|
fn render_bold(text : StringView) -> String {
  let mut remaining = text
  let mut html = ""
  while true {
    match remaining.split_once("**") {
      None => {
        html += render_strike(remaining)
        break
      }
      Some((before, after)) =>
        match after.split_once("**") {
          None => {
            html += render_strike(remaining)
            break
          }
          Some((bold, rest)) => {
            html += render_strike(before)
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
/// 深さは先頭のスペース2個につき1増える。本文には字下げと箇条書きの記号・直後のスペースを含まない。
fn list_item(line : StringView) -> (Int, StringView)? {
  let mut remaining = line
  let mut depth = 0
  while remaining.has_prefix("  ") {
    remaining = remaining[2:]
    depth += 1
  }
  for marker in ["- ", "* ", "+ "] {
    if remaining.strip_prefix(marker) is Some(item) {
      return Some((depth, item))
    }
  }
  None
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
/// 戻り値は見出しの記号と直後のスペースを除いた本文。見出しの行でなければ None。
fn heading_content(line : StringView) -> StringView? {
  let mut remaining = line
  let mut level = 0
  while remaining.has_prefix("#") && level < 6 {
    remaining = remaining[1:]
    level += 1
  }
  if level == 0 {
    return None
  }
  remaining.strip_prefix(" ")
}

///|
fn is_code_block_start(line : StringView) -> Bool {
  line.has_prefix("```") && !line.has_prefix("````")
}

///|
fn render_blocks(text : StringView) -> String {
  let lines = text.split("\n").to_array()
  let mut index = 0
  let mut html = ""
  let mut previous_is_block = false
  while index < lines.length() {
    if index > 0 && !previous_is_block && !is_code_block_start(lines[index]) {
      html += "<br>"
    }
    previous_is_block = false
    if is_code_block_start(lines[index]) {
      index += 1
      let start = index
      let mut code = ""
      while index < lines.length() && lines[index] != "```" {
        if index > start {
          code += "\n"
        }
        code += lines[index].to_owned()
        index += 1
      }
      if index < lines.length() {
        index += 1
      }
      html += "<pre data-stringify-type=\"pre\">" +
        escape_html(code.to_string_view()) +
        "</pre>"
      previous_is_block = true
      continue
    }
    if heading_content(lines[index]) is Some(heading) {
      html += "<b data-stringify-type=\"bold\">" +
        render_inline(heading) +
        "</b>"
      index += 1
      continue
    }
    if list_item(lines[index]) is Some((0, _)) {
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
          !(list_item(lines[index]) is Some((0, _))) &&
          !is_code_block_start(lines[index]) &&
          heading_content(lines[index]) is None {
      if index > start {
        content += "\n"
      }
      let line = if is_quote {
        let after_marker = lines[index][1:]
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
    let rendered = render_inline(content.to_string_view()).replace_all(
      old="\n",
      new="<br>",
    )
    previous_is_block = is_quote
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
  render_blocks(normalized.to_string_view())
}
