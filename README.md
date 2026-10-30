# md2slack

MarkdownテキストをSlackへ貼り付けやすい形式に変換するWebサイトです。

- [Cloudflare Workersで使う](https://md2slack.tatarabako.workers.dev/)
- [GitHub Pagesで使う](https://horyu.github.io/md2slack/)

## 対応する書式

Markdownの一部をSlack向けHTMLへ変換します。Markdownの仕様全体に準拠した変換ではありません。

| 書式 | 入力例・変換内容 |
| --- | --- |
| 見出し | `# 見出し`〜`###### 見出し`を、階層にかかわらず太字へ変換 |
| 太字 | `**太字**`・`__太字__` |
| 斜体 | `*斜体*`・`_斜体_` |
| 取り消し線 | `~~取り消し線~~` |
| インラインコード | バッククォート1個で囲んだ部分。内部の書式は変換しない |
| コードブロック | 行頭のバッククォート3個で囲んだ部分。言語指定は無視し、改行・字下げを保持 |
| リンク | `[表示名](https://example.com/)`。URLは`http://`または`https://`で始まるもの |
| 引用 | 行頭の`>`。`> >`と`>>`で2階層まで対応し、3つ目以降の`>`は本文に残す |
| 箇条書き | 行頭の`- `・`* `・`+ ` |
| 番号付きリスト | 行頭の半角数字1〜9桁と`. `。最初の番号から順に表示 |
| 改行・空行 | 改行コードを統一し、HTMLの改行として保持 |

リストの入れ子はスペース2個で1階層とし、番号付き・番号なしを混在できます。親のない字下げや階層を飛び越す行は本文として扱います。番号付きリストの`1) 項目`形式は対象外です。

### 未対応の書式・組み合わせ

- 太字・斜体・取り消し線・リンクなどの入れ子や、重なり合う記号は正しく変換できません。
- バックスラッシュによる記号のエスケープ、参照形式のリンクは未対応です。
- リストや引用の中の見出し・コードブロックなど、異なるブロック書式の組み合わせは未対応です。
- 画像、表、チェックボックス付きリスト、水平線は未対応です。入力したHTMLは文字として表示します。

## 開発ツールの準備

MoonBitとmiseをインストールしたうえで、リポジトリのルートで次を実行します。

```powershell
mise trust
mise install
```

Node.js、aube、Agent Package Manager（APM：AIエージェント用のSkillや指示を管理するツール）のバージョンは`mise.toml`で指定しています。aubeはパッケージの管理と、`package.json`に定義したコマンドの実行に使用します。

AIエージェント用のSkillとエージェント定義はGitで管理せず、clone後に次のコマンドで`apm.lock.yaml`に固定した内容を復元します。

```powershell
apm install --frozen
```

## チェックとテスト

```powershell
aube run check
aube run test
```

`check`は型と警告のチェック、`test`はテストを実行します。

## ブラウザで確認

HTMLは`docs/index.html`を直接編集します。`aube run build`でWebAssemblyをビルドし、`docs/app.wasm`へ配置します。GitHub Pagesでも公開できるよう、`docs`はGitで管理します。開発サーバーもこの2ファイルを配信します。

WebAssemblyのJavaScript文字列連携に対応したブラウザが必要です。リポジトリのルートで次を実行します。

```powershell
aube run build
aube run dev
```

ブラウザで <http://127.0.0.1:8000/> を開きます。サーバーは`Ctrl+C`で停止します。

MoonBitの変換処理を変更した場合は、再度`aube run build`を実行してからブラウザを再読み込みします。

`web/wasm`はMoonBitをWebAssembly（WASM）へビルドするパッケージです。ビルド時の`wasm-gc`は、ガベージコレクション（Garbage Collection、GC）機能を備えたWASM向けのターゲット名です。`web/server`は確認用のMoonBit製ローカルサーバーです。

## Cloudflare Workersで確認・公開

WranglerはCloudflareのローカル確認・公開用コマンドツールです。

```powershell
aube run build
aube run dev:workers
```

表示されたローカルURLで確認し、`Ctrl+C`で停止します。

初回は`aube run login`でブラウザからCloudflareへのログインを行います。公開・更新時は次を実行します。

```powershell
aube run build
aube run deploy
```

`deploy`は`wrangler.jsonc`で指定した`docs`フォルダを公開します。

## コマンドラインインターフェース（CLI）で実行

```powershell
moon run cmd/main -- sample.md
```

標準入力にも対応しています。詳しい使い方は`moon run cmd/main -- -h`で確認できます。
