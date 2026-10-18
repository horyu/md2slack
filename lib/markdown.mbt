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
fn render_italic(text : StringView, marker? : StringView = "*") -> String {
  let mut remaining = text
  let mut html = ""
  while true {
    match remaining.split_once(marker) {
      None => {
        html += if marker == "*" {
          render_italic(remaining, marker="_")
        } else {
          escape_html(remaining)
        }
        break
      }
      Some((before, after)) =>
        match after.split_once(marker) {
          None => {
            html += if marker == "*" {
              render_italic(remaining, marker="_")
            } else {
              escape_html(remaining)
            }
            break
          }
          Some((italic, rest)) => {
            html += if marker == "*" {
              render_italic(before, marker="_")
            } else {
              escape_html(before)
            }
            if italic.is_empty() {
              html += marker.to_owned() + marker.to_owned()
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
fn render_bold(text : StringView, marker? : StringView = "**") -> String {
  let mut remaining = text
  let mut html = ""
  while true {
    match remaining.split_once(marker) {
      None => {
        html += if marker == "**" {
          render_bold(remaining, marker="__")
        } else {
          render_strike(remaining)
        }
        break
      }
      Some((before, after)) =>
        match after.split_once(marker) {
          None => {
            html += if marker == "**" {
              render_bold(remaining, marker="__")
            } else {
              render_strike(remaining)
            }
            break
          }
          Some((bold, rest)) => {
            html += if marker == "**" {
              render_bold(before, marker="__")
            } else {
              render_strike(before)
            }
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
        let (children, next) = render_child_lists(lines, index, depth + 1)
        html += children
        index = next
        html += "</li>"
      }
      _ => break
    }
  }
  (html + "</ul>", index)
}

///|
/// 戻り値は Some((階層の深さ, 番号の文字列, 項目の本文))。番号付きリストの行でなければ None。
/// 深さは先頭のスペース2個につき1増える。本文には字下げ・番号・「. 」を含まない。
fn ordered_item(line : StringView) -> (Int, StringView, StringView)? {
  let mut remaining = line
  let mut depth = 0
  while remaining.has_prefix("  ") {
    remaining = remaining[2:]
    depth += 1
  }
  let (number, item) = match remaining.split_once(". ") {
    Some(parts) => parts
    None => return None
  }
  if number.is_empty() || number.length() > 9 {
    return None
  }
  for digit in number {
    if !(digit is ('0'..='9')) {
      return None
    }
  }
  Some((depth, number, item))
}

///|
/// 戻り値は (生成したHTML, 次に処理する行の添字)。
/// 最後まで処理した場合、添字は lines.length() になる。
fn render_ordered_list(
  lines : Array[StringView],
  start : Int,
  depth : Int,
  start_number : StringView,
) -> (String, Int) {
  let mut index = start
  let mut html = "<ol data-stringify-type=\"ordered-list\" data-list-tree=\"true\" data-indent=\"\{depth}\" data-border=\"0\" start=\"" +
    start_number.to_owned() +
    "\">"
  while index < lines.length() {
    match ordered_item(lines[index]) {
      Some((item_depth, _, item)) if item_depth == depth => {
        html += "<li data-stringify-indent=\"\{depth}\" data-stringify-border=\"0\">" +
          render_inline(item)
        index += 1
        let (children, next) = render_child_lists(lines, index, depth + 1)
        html += children
        index = next
        html += "</li>"
      }
      _ => break
    }
  }
  (html + "</ol>", index)
}

///|
/// 戻り値は (子リストのHTML, 次に処理する行の添字)。
/// 指定した深さの子リストがなければ、HTMLは空文字列、添字は start のまま。
fn render_child_lists(
  lines : Array[StringView],
  start : Int,
  depth : Int,
) -> (String, Int) {
  let mut index = start
  let mut html = ""
  while index < lines.length() {
    let (child, next) = if list_item(lines[index]) is Some((child_depth, _)) &&
      child_depth == depth {
      render_list(lines, index, depth)
    } else if ordered_item(lines[index]) is Some((child_depth, number, _)) &&
      child_depth == depth {
      render_ordered_list(lines, index, depth, number)
    } else {
      break
    }
    html += child
    index = next
  }
  (html, index)
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
fn quote_content(line : StringView) -> StringView {
  let after_marker = line[1:]
  match after_marker.strip_prefix(" ") {
    Some(rest) => rest
    None => after_marker
  }
}

///|
fn render_quote(text : StringView, depth : Int) -> String {
  let lines = text.split("\n").to_array()
  let mut index = 0
  let mut html = ""
  let mut previous_is_nested = false
  while index < lines.length() {
    let is_nested = depth < 2 && lines[index].has_prefix(">")
    if index > 0 && !previous_is_nested && !is_nested {
      html += "<br>"
    }
    let start = index
    let mut content = ""
    while index < lines.length() &&
          (depth < 2 && lines[index].has_prefix(">")) == is_nested {
      if index > start {
        content += "\n"
      }
      let line = if is_nested {
        quote_content(lines[index])
      } else {
        lines[index]
      }
      content += line.to_owned()
      index += 1
    }
    html += if is_nested {
      render_quote(content.to_string_view(), depth + 1)
    } else {
      render_inline(content.to_string_view()).replace_all(old="\n", new="<br>")
    }
    previous_is_nested = is_nested
  }
  "<blockquote data-stringify-type=\"quote\">" + html + "</blockquote>"
}

///|
fn render_blocks(text : StringView) -> String {
  let lines = text.split("\n").to_array()
  let mut index = 0
  let mut html = ""
  let mut previous_is_block = false
  while index < lines.length() {
    if index > 0 &&
      !previous_is_block &&
      !is_code_block_start(lines[index]) &&
      !(ordered_item(lines[index]) is Some((0, _, _))) {
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
    if ordered_item(lines[index]) is Some((0, number, _)) {
      let (list, next) = render_ordered_list(lines, index, 0, number)
      html += list
      index = next
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
          !(ordered_item(lines[index]) is Some((0, _, _))) &&
          !is_code_block_start(lines[index]) &&
          heading_content(lines[index]) is None {
      if index > start {
        content += "\n"
      }
      let line = if is_quote {
        quote_content(lines[index])
      } else {
        lines[index]
      }
      content += line.to_owned()
      index += 1
    }
    previous_is_block = is_quote
    html += if is_quote {
      render_quote(content.to_string_view(), 1)
    } else {
      render_inline(content.to_string_view()).replace_all(old="\n", new="<br>")
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
