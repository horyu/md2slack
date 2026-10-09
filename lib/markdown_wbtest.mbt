///|
test "通常の文字も太字内の文字もHTML用にエスケープする" {
  assert_eq(markdown_to_slack_html(""), "")
  assert_eq(
    markdown_to_slack_html("こんにちは🙂"),
    "こんにちは🙂",
  )
  assert_eq(
    markdown_to_slack_html(
      (
        #|<script>"&'</script>
      ),
    ),
    "&lt;script&gt;&quot;&amp;&#39;&lt;/script&gt;",
  )
  assert_eq(markdown_to_slack_html("&lt;"), "&amp;lt;")
  assert_eq(
    markdown_to_slack_html("**<b>&</b>**"),
    (
      #|<b data-stringify-type="bold">&lt;b&gt;&amp;&lt;/b&gt;</b>
    ),
  )
}

///|
test "太字を変換し、前後の文字を保持する" {
  assert_eq(
    markdown_to_slack_html("前 **太字** 後 **もう一つ**"),
    (
      #|前 <b data-stringify-type="bold">太字</b> 後 <b data-stringify-type="bold">もう一つ</b>
    ),
  )
  assert_eq(
    markdown_to_slack_html("**太字**通常"),
    (
      #|<b data-stringify-type="bold">太字</b>通常
    ),
  )
}

///|
test "閉じられていない太字の記号は文字として残す" {
  assert_eq(markdown_to_slack_html("前 **未完<&"), "前 **未完&lt;&amp;")
  assert_eq(
    markdown_to_slack_html("**完了** **未完"),
    (
      #|<b data-stringify-type="bold">完了</b> **未完
    ),
  )
}

///|
test "改行コードの違いを同じHTMLの改行に変換する" {
  assert_eq(
    markdown_to_slack_html(
      (
        #|一行目
        #|二行目
      ),
    ),
    "一行目<br>二行目",
  )
  assert_eq(
    markdown_to_slack_html("一行目\r\n二行目"),
    "一行目<br>二行目",
  )
  assert_eq(
    markdown_to_slack_html("一行目\r二行目"),
    "一行目<br>二行目",
  )
}

///|
test "空行と先頭・末尾の改行を保持する" {
  assert_eq(
    markdown_to_slack_html(
      (
        #|
        #|一行目
        #|
        #|二行目
        #|
      ),
    ),
    "<br>一行目<br><br>二行目<br>",
  )
}

///|
test "太字の前後と内部の改行を変換する" {
  assert_eq(
    markdown_to_slack_html(
      (
        #|前
        #|**太
        #|字**
        #|後
      ),
    ),
    (
      #|前<br><b data-stringify-type="bold">太<br>字</b><br>後
    ),
  )
  assert_eq(
    markdown_to_slack_html(
      (
        #|<br>
        #|&
      ),
    ),
    "&lt;br&gt;<br>&amp;",
  )
}

///|
test "インラインコードを変換し、前後の太字と通常の文字を保持する" {
  assert_eq(
    markdown_to_slack_html("**太字**`code`通常`もう一つ`**後**"),
    (
      #|<b data-stringify-type="bold">太字</b><code data-stringify-type="code">code</code>通常<code data-stringify-type="code">もう一つ</code><b data-stringify-type="bold">後</b>
    ),
  )
}

///|
test "コード内の太字記号は変換せずHTML用にエスケープする" {
  assert_eq(
    markdown_to_slack_html(
      (
        #|`**太字ではない** <b>&"'🙂`
      ),
    ),
    (
      #|<code data-stringify-type="code">**太字ではない** &lt;b&gt;&amp;&quot;&#39;🙂</code>
    ),
  )
}

///|
test "閉じられていないバッククォートは文字として残す" {
  assert_eq(markdown_to_slack_html("前 `未完<&"), "前 `未完&lt;&amp;")
  assert_eq(
    markdown_to_slack_html("`完了` `未完"),
    (
      #|<code data-stringify-type="code">完了</code> `未完
    ),
  )
}

///|
test "リンクを変換し、前後の書式と複数のリンクを保持する" {
  assert_eq(
    markdown_to_slack_html(
      "**前**[リンク](https://example.com/)[次](http://example.com/)後",
    ),
    (
      #|<b data-stringify-type="bold">前</b><a href="https://example.com/">リンク</a><a href="http://example.com/">次</a>後
    ),
  )
}

///|
test "リンクの表示名とURLをHTML用にエスケープする" {
  assert_eq(
    markdown_to_slack_html(
      (
        #|[<名前>&](https://example.com/?a=1&b="x")
      ),
    ),
    (
      #|<a href="https://example.com/?a=1&amp;b=&quot;x&quot;">&lt;名前&gt;&amp;</a>
    ),
  )
}

///|
test "未完成のリンクと未対応のURLは文字として残す" {
  assert_eq(
    markdown_to_slack_html("[名前](https://example.com/"),
    "[名前](https://example.com/",
  )
  assert_eq(markdown_to_slack_html("[名前]"), "[名前]")
  assert_eq(
    markdown_to_slack_html("[名前](javascript:alert)"),
    "[名前](javascript:alert)",
  )
  assert_eq(
    markdown_to_slack_html("[名前](/relative)"),
    "[名前](/relative)",
  )
}

///|
test "インラインコード内のリンク記法は変換しない" {
  assert_eq(
    markdown_to_slack_html("`[名前](https://example.com/)`"),
    (
      #|<code data-stringify-type="code">[名前](https://example.com/)</code>
    ),
  )
}

///|
test "連続する引用行を一つにまとめ、内部の書式を変換する" {
  assert_eq(
    markdown_to_slack_html(
      (
        #|> **太字**
        #|> `code`
        #|> [リンク](https://example.com/)
      ),
    ),
    (
      #|<blockquote data-stringify-type="quote"><b data-stringify-type="bold">太字</b><br><code data-stringify-type="code">code</code><br><a href="https://example.com/">リンク</a></blockquote>
    ),
  )
}

///|
test "引用と通常行の切り替え、引用内の空行を保持する" {
  assert_eq(
    markdown_to_slack_html(
      (
        #|前
        #|> 引用
        #|>
        #|> 続き
        #|後
      ),
    ),
    (
      #|前<br><blockquote data-stringify-type="quote">引用<br><br>続き</blockquote><br>後
    ),
  )
  assert_eq(
    markdown_to_slack_html(
      (
        #|> 一つ目
        #|
        #|> 二つ目
      ),
    ),
    (
      #|<blockquote data-stringify-type="quote">一つ目</blockquote><br><br><blockquote data-stringify-type="quote">二つ目</blockquote>
    ),
  )
}

///|
test "引用は行頭で認識し、文字をエスケープして改行コードを統一する" {
  assert_eq(
    markdown_to_slack_html("><script>&\r\n> 次"),
    (
      #|<blockquote data-stringify-type="quote">&lt;script&gt;&amp;<br>次</blockquote>
    ),
  )
  assert_eq(markdown_to_slack_html("途中 > 記号"), "途中 &gt; 記号")
  assert_eq(
    markdown_to_slack_html("`> code`"),
    (
      #|<code data-stringify-type="code">&gt; code</code>
    ),
  )
}
