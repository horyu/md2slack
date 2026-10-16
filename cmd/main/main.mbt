///|
// Cの標準ライブラリのexitを呼び、終了コードを指定する。
extern "c" fn exit(code : Int) = "exit"

///|
async fn main {
  let args = @env.args()
  if args.length() == 2 && (args[1] == "--help" || args[1] == "-h") {
    let help =
      #|MarkdownをSlack向けHTMLに変換して標準出力へ表示します。
      #|
      #|使い方: moon run cmd/main -- [ファイルパス | -]
      #|ファイルパスを省略するか「-」を指定すると、標準入力を読みます。
      #|入力の文字コードはUTF-8です。
      #|
      #|オプション:
      #|  -h, --help  この使い方を表示します。
      #|
      #|使用例:
      #|  moon run cmd/main -- sample.md
      #|  cat sample.md | moon run cmd/main
    @stdio.stdout.write(help + "\n")
    return
  }
  if args.length() > 2 {
    @stdio.stderr.write(
      "ファイルパスは1つだけ指定してください。使い方: --help\n",
    )
    exit(1)
    return
  }
  let path = if args.length() == 2 { args[1] } else { "-" }
  if path != "-" && path.has_prefix("-") {
    @stdio.stderr.write(
      "不明なオプション: \{path}。使い方: --help\n",
    )
    exit(1)
    return
  }
  let markdown = try {
    let data = if path == "-" {
      @stdio.stdin.read_all()
    } else {
      @fs.read_file(path)
    }
    data.text()
  } catch {
    error => {
      @stdio.stderr.write(
        "入力の読み取りに失敗しました (\{path}): \{error}\n",
      )
      exit(1)
      return
    }
  }
  @stdio.stdout.write(@lib.markdown_to_slack_html(markdown) + "\n")
}
