///|
test "通常の文字も太字内の文字もHTML用にエスケープする" {
  assert_eq(markdown_to_slack_html(""), "")
  assert_eq(
    markdown_to_slack_html("こんにちは🙂"),
    "こんにちは🙂",
  )
  assert_eq(
    markdown_to_slack_html("<script>\"&'</script>"),
    "&lt;script&gt;&quot;&amp;&#39;&lt;/script&gt;",
  )
  assert_eq(markdown_to_slack_html("&lt;"), "&amp;lt;")
  assert_eq(
    markdown_to_slack_html("**<b>&</b>**"),
    "<b data-stringify-type=\"bold\">&lt;b&gt;&amp;&lt;/b&gt;</b>",
  )
}

///|
test "太字を変換し、前後の文字を保持する" {
  assert_eq(
    markdown_to_slack_html("前 **太字** 後 **もう一つ**"),
    "前 <b data-stringify-type=\"bold\">太字</b> 後 <b data-stringify-type=\"bold\">もう一つ</b>",
  )
  assert_eq(
    markdown_to_slack_html("**太字**通常"),
    "<b data-stringify-type=\"bold\">太字</b>通常",
  )
}

///|
test "閉じられていない太字の記号は文字として残す" {
  assert_eq(markdown_to_slack_html("前 **未完<&"), "前 **未完&lt;&amp;")
  assert_eq(
    markdown_to_slack_html("**完了** **未完"),
    "<b data-stringify-type=\"bold\">完了</b> **未完",
  )
}
