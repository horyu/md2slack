///|
test "番号付きリストの子と孫を入れ子にし、開始番号を階層ごとに保持する" {
  let markdown =
    #|2. 親
    #|  3. **子**
    #|    5. `孫`
    #|  4. 次の子
    #|3. 次の親
  let expected =
    #|<ol data-stringify-type="ordered-list" data-list-tree="true" data-indent="0" data-border="0" start="2"><li data-stringify-indent="0" data-stringify-border="0">親<ol data-stringify-type="ordered-list" data-list-tree="true" data-indent="1" data-border="0" start="3"><li data-stringify-indent="1" data-stringify-border="0"><b data-stringify-type="bold">子</b><ol data-stringify-type="ordered-list" data-list-tree="true" data-indent="2" data-border="0" start="5"><li data-stringify-indent="2" data-stringify-border="0"><code data-stringify-type="code">孫</code></li></ol></li><li data-stringify-indent="1" data-stringify-border="0">次の子</li></ol></li><li data-stringify-indent="0" data-stringify-border="0">次の親</li></ol>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "入れ子の番号付きリストを閉じ、通常行と別のリストへ進む" {
  let markdown =
    #|1. 親
    #|  1. <子>&
    #|通常
    #|
    #|4. 別の親
  let first = markdown_to_slack_html("1. 親\n  1. <子>&")
  let last = markdown_to_slack_html("4. 別の親")
  assert_eq(markdown_to_slack_html(markdown), first + "<br>通常<br>" + last)
}

///|
test "番号付きリストの階層を飛び越す行は通常の文字として残す" {
  let markdown =
    #|1. 親
    #|    1. 孫へ飛び越し
  let expected = markdown_to_slack_html("1. 親") +
    "<br>    1. 孫へ飛び越し"
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "番号付きリストをまとめ、項目内の書式を変換する" {
  let markdown =
    #|前
    #|1. **太字**
    #|2. `code`
    #|3. [リンク](https://example.com/)
    #|後
  let expected =
    #|前<ol data-stringify-type="ordered-list" data-list-tree="true" data-indent="0" data-border="0" start="1"><li data-stringify-indent="0" data-stringify-border="0"><b data-stringify-type="bold">太字</b></li><li data-stringify-indent="0" data-stringify-border="0"><code data-stringify-type="code">code</code></li><li data-stringify-indent="0" data-stringify-border="0"><a href="https://example.com/">リンク</a></li></ol><br>後
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "番号付きリスト前の空行だけを保持し、余分な改行タグを追加しない" {
  let markdown =
    #|前
    #|
    #|1. 項目
  let expected =
    #|前<br><ol data-stringify-type="ordered-list" data-list-tree="true" data-indent="0" data-border="0" start="1"><li data-stringify-indent="0" data-stringify-border="0">項目</li></ol>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "番号付きリストは最初の番号から順に数え、文字をエスケープする" {
  let markdown =
    #|3. <一つ目>&
    #|1. 二つ目
  let expected =
    #|<ol data-stringify-type="ordered-list" data-list-tree="true" data-indent="0" data-border="0" start="3"><li data-stringify-indent="0" data-stringify-border="0">&lt;一つ目&gt;&amp;</li><li data-stringify-indent="0" data-stringify-border="0">二つ目</li></ol>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "番号付きリストは行頭の九桁までの半角数字とピリオドとスペースで認識する" {
  let markdown =
    #|1.空白なし
    #|a. 文字
    #|１. 全角
    #|1234567890. 桁数超過
    #|  1. 字下げ
    #|途中 1. 記号
  let expected =
    #|1.空白なし<br>a. 文字<br>１. 全角<br>1234567890. 桁数超過<br>  1. 字下げ<br>途中 1. 記号
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "コードブロック内の番号付きリストは変換しない" {
  let markdown =
    #|```
    #|1. そのまま
    #|```
  let expected =
    #|<pre data-stringify-type="pre">1. そのまま</pre>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "三種類の箇条書き記号を同じ形式へ変換する" {
  let expected =
    #|<ul data-stringify-type="unordered-list" data-list-tree="true" data-indent="0" data-border="0"><li data-stringify-indent="0" data-stringify-border="0">項目</li></ul>
  for marker in ["- ", "* ", "+ "] {
    assert_eq(markdown_to_slack_html(marker + "項目"), expected)
  }
}

///|
test "箇条書き記号が混在しても兄弟と入れ子を変換する" {
  let mixed =
    #|前
    #|* 親
    #|  + 子
    #|    * 孫
    #|  - 次の子
    #|+ 次の親
    #|後
  let hyphens =
    #|前
    #|- 親
    #|  - 子
    #|    - 孫
    #|  - 次の子
    #|- 次の親
    #|後
  assert_eq(markdown_to_slack_html(mixed), markdown_to_slack_html(hyphens))
}

///|
test "箇条書き記号直後にスペースがなければ通常の文字や斜体として扱う" {
  let markdown =
    #|+空白なし
    #|*斜体*
    #|途中 + 記号
  let expected =
    #|+空白なし<br><i data-stringify-type="italic">斜体</i><br>途中 + 記号
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "行頭の見出しを階層にかかわらず太字に変換する" {
  let markdown =
    #|# 一
    #|## 二
    #|### 三
    #|#### 四
    #|##### 五
    #|###### 六
  let expected =
    #|<b data-stringify-type="bold">一</b><br><b data-stringify-type="bold">二</b><br><b data-stringify-type="bold">三</b><br><b data-stringify-type="bold">四</b><br><b data-stringify-type="bold">五</b><br><b data-stringify-type="bold">六</b>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "見出しを通常行と区切り、本文のコードやリンクを変換する" {
  let markdown =
    #|前
    #|## <見出し>& `code` [リンク](https://example.com/)
    #|後
  let expected =
    #|前<br><b data-stringify-type="bold">&lt;見出し&gt;&amp; <code data-stringify-type="code">code</code> <a href="https://example.com/">リンク</a></b><br>後
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "見出しの記号は行頭とスペースと六段階までを条件に認識する" {
  let markdown =
    #|途中 # 記号
    #|#空白なし
    #|####### 七
    #| # 字下げ
  let expected =
    #|途中 # 記号<br>#空白なし<br>####### 七<br> # 字下げ
  assert_eq(markdown_to_slack_html(markdown), expected)
  assert_eq(
    markdown_to_slack_html("# "),
    (
      #|<b data-stringify-type="bold"></b>
    ),
  )
}

///|
test "コードブロック内の見出し記号は変換しない" {
  let markdown =
    #|```
    #|# そのまま
    #|```
  let expected =
    #|<pre data-stringify-type="pre"># そのまま</pre>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "言語指定付きコードブロックは言語名を除いて本文だけを出力する" {
  let markdown =
    #|前
    #|```moonbit
    #|let text = "<hello>"
    #|println(text)
    #|```
    #|後
  let expected =
    #|前<pre data-stringify-type="pre">let text = &quot;&lt;hello&gt;&quot;
    #|println(text)</pre>後
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "言語指定付きでも閉じる区切りがなければ末尾までコードとして扱う" {
  let markdown =
    #|```unknown
    #|**そのまま**
    #|```moonbit
  let expected =
    #|<pre data-stringify-type="pre">**そのまま**
    #|```moonbit</pre>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "コードブロックの改行と字下げを保持し、内部の書式を変換しない" {
  let markdown =
    #|```
    #|  **太字** *斜体* ~~取り消し~~ `code`
    #|
    #|- 項目
    #|> 引用
    #|```
  let expected =
    #|<pre data-stringify-type="pre">  **太字** *斜体* ~~取り消し~~ `code`
    #|
    #|- 項目
    #|&gt; 引用</pre>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "コードブロック内の文字をエスケープし、前後の通常行を変換する" {
  let markdown =
    #|**前**
    #|```
    #|<script>"&'</script>
    #|```
    #|*後*
  let expected =
    #|<b data-stringify-type="bold">前</b><pre data-stringify-type="pre">&lt;script&gt;&quot;&amp;&#39;&lt;/script&gt;</pre><i data-stringify-type="italic">後</i>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "コードブロック前の空行だけを保持し、余分な改行タグを追加しない" {
  let markdown =
    #|前
    #|
    #|```
    #|code
    #|```
  let expected =
    #|前<br><pre data-stringify-type="pre">code</pre>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "空のコードブロックと閉じていないコードブロックを扱う" {
  assert_eq(
    markdown_to_slack_html("```\n```"),
    (
      #|<pre data-stringify-type="pre"></pre>
    ),
  )
  let expected =
    #|<pre data-stringify-type="pre">一行目
    #|二行目</pre>
  assert_eq(markdown_to_slack_html("```\r\n一行目\r二行目"), expected)
}

///|
test "斜体を変換し、太字と取り消し線を隣に並べられる" {
  let expected =
    #|前 <i data-stringify-type="italic">斜体</i> <b data-stringify-type="bold">太字</b> <s data-stringify-type="strike">取り消し</s> <i data-stringify-type="italic">次</i> 後
  assert_eq(
    markdown_to_slack_html("前 *斜体* **太字** ~~取り消し~~ *次* 後"),
    expected,
  )
}

///|
test "斜体内の文字をエスケープし、閉じていない記号を残す" {
  let expected =
    #|<i data-stringify-type="italic">&lt;b&gt;&amp;</i> *未完&lt;&amp;
  assert_eq(markdown_to_slack_html("*<b>&* *未完<&"), expected)
  assert_eq(markdown_to_slack_html("**未完"), "**未完")
  assert_eq(markdown_to_slack_html("**"), "**")
}

///|
test "コード内の斜体記号は変換しない" {
  let expected =
    #|<code data-stringify-type="code">*そのまま*</code>
  assert_eq(markdown_to_slack_html("`*そのまま*`"), expected)
}

///|
test "取り消し線を変換し、前後の太字と通常の文字を保持する" {
  let expected =
    #|前 <s data-stringify-type="strike">一つ目</s> <b data-stringify-type="bold">太字</b> <s data-stringify-type="strike">二つ目</s> 後
  assert_eq(
    markdown_to_slack_html("前 ~~一つ目~~ **太字** ~~二つ目~~ 後"),
    expected,
  )
}

///|
test "取り消し線内の文字をエスケープし、未完の記号を残す" {
  let expected =
    #|<s data-stringify-type="strike">&lt;b&gt;&amp;</s> ~~未完&lt;&amp;
  assert_eq(markdown_to_slack_html("~~<b>&~~ ~~未完<&"), expected)
  assert_eq(markdown_to_slack_html("~一つ~"), "~一つ~")
}

///|
test "コード内の取り消し線記号は変換しない" {
  let expected =
    #|<code data-stringify-type="code">~~そのまま~~</code>
  assert_eq(markdown_to_slack_html("`~~そのまま~~`"), expected)
}

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
      #|前<br><blockquote data-stringify-type="quote">引用<br><br>続き</blockquote>後
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
      #|<blockquote data-stringify-type="quote">一つ目</blockquote><br><blockquote data-stringify-type="quote">二つ目</blockquote>
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

///|
test "連続する箇条書きをまとめ、項目内の書式を変換する" {
  let markdown =
    #|- **太字**
    #|- `code`
    #|- [リンク](https://example.com/)
  let expected =
    #|<ul data-stringify-type="unordered-list" data-list-tree="true" data-indent="0" data-border="0"><li data-stringify-indent="0" data-stringify-border="0"><b data-stringify-type="bold">太字</b></li><li data-stringify-indent="0" data-stringify-border="0"><code data-stringify-type="code">code</code></li><li data-stringify-indent="0" data-stringify-border="0"><a href="https://example.com/">リンク</a></li></ul>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "箇条書きと通常行・空行・引用を切り替える" {
  let markdown =
    #|前
    #|- 一つ目
    #|- 二つ目
    #|
    #|- 別のリスト
    #|> 引用
    #|後
  let expected =
    #|前<br><ul data-stringify-type="unordered-list" data-list-tree="true" data-indent="0" data-border="0"><li data-stringify-indent="0" data-stringify-border="0">一つ目</li><li data-stringify-indent="0" data-stringify-border="0">二つ目</li></ul><br><br><ul data-stringify-type="unordered-list" data-list-tree="true" data-indent="0" data-border="0"><li data-stringify-indent="0" data-stringify-border="0">別のリスト</li></ul><br><blockquote data-stringify-type="quote">引用</blockquote>後
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "箇条書きの文字をエスケープし、行頭のハイフンと空白で認識する" {
  let expected =
    #|<ul data-stringify-type="unordered-list" data-list-tree="true" data-indent="0" data-border="0"><li data-stringify-indent="0" data-stringify-border="0">&lt;b&gt;&amp;</li><li data-stringify-indent="0" data-stringify-border="0"></li></ul>
  assert_eq(markdown_to_slack_html("- <b>&\r\n- "), expected)
  assert_eq(
    markdown_to_slack_html("途中 - 記号\n-空白なし"),
    "途中 - 記号<br>-空白なし",
  )
}

///|
test "箇条書きの子と孫を入れ子にし、兄弟と親に戻る" {
  let markdown =
    #|- 親
    #|  - **子1**
    #|    - `孫`
    #|  - [子2](https://example.com/)
    #|- 次の親
  let expected =
    #|<ul data-stringify-type="unordered-list" data-list-tree="true" data-indent="0" data-border="0"><li data-stringify-indent="0" data-stringify-border="0">親<ul data-stringify-type="unordered-list" data-list-tree="true" data-indent="1" data-border="0"><li data-stringify-indent="1" data-stringify-border="0"><b data-stringify-type="bold">子1</b><ul data-stringify-type="unordered-list" data-list-tree="true" data-indent="2" data-border="0"><li data-stringify-indent="2" data-stringify-border="0"><code data-stringify-type="code">孫</code></li></ul></li><li data-stringify-indent="1" data-stringify-border="0"><a href="https://example.com/">子2</a></li></ul></li><li data-stringify-indent="0" data-stringify-border="0">次の親</li></ul>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "入れ子のリストを閉じて通常の行や別のリストへ進む" {
  let markdown =
    #|- 親
    #|  - <子>&
    #|通常
    #|
    #|- 別の親
  let expected =
    #|<ul data-stringify-type="unordered-list" data-list-tree="true" data-indent="0" data-border="0"><li data-stringify-indent="0" data-stringify-border="0">親<ul data-stringify-type="unordered-list" data-list-tree="true" data-indent="1" data-border="0"><li data-stringify-indent="1" data-stringify-border="0">&lt;子&gt;&amp;</li></ul></li></ul><br>通常<br><br><ul data-stringify-type="unordered-list" data-list-tree="true" data-indent="0" data-border="0"><li data-stringify-indent="0" data-stringify-border="0">別の親</li></ul>
  assert_eq(markdown_to_slack_html(markdown), expected)
}

///|
test "親のない字下げや階層の飛び越しは通常の文字として残す" {
  assert_eq(markdown_to_slack_html("  - 親なし"), "  - 親なし")
  let markdown =
    #|- 親
    #|    - 孫へ飛び越し
  let expected =
    #|<ul data-stringify-type="unordered-list" data-list-tree="true" data-indent="0" data-border="0"><li data-stringify-indent="0" data-stringify-border="0">親</li></ul><br>    - 孫へ飛び越し
  assert_eq(markdown_to_slack_html(markdown), expected)
}
