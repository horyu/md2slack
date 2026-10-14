# md2slack

MoonBitを学びながら、MarkdownテキストをSlackへ貼り付けやすい形式に変換するWebサイトを作るプロジェクトです。

## 開発ツールの準備

MoonBitとmiseをインストールしたうえで、リポジトリのルートで次を実行します。

```powershell
mise trust
mise install
```

Node.jsとaubeのバージョンは`mise.toml`で指定しています。aubeはパッケージの管理と、`package.json`に定義したコマンドの実行に使用します。

## コマンドラインインターフェース（CLI）で実行

```powershell
moon run cmd/main
```

## チェックとテスト

```powershell
aube run check
aube run test
```

`check`は型と警告のチェック、`test`はテストを実行します。

## ブラウザで確認

WebAssemblyのJavaScript文字列連携に対応したブラウザが必要です。リポジトリのルートで次を実行します。

```powershell
aube run build
aube run dev
```

ブラウザで <http://127.0.0.1:8000/> を開きます。サーバーは`Ctrl+C`で停止します。

MoonBitの変換処理を変更した場合は、再度`aube run build`を実行してからブラウザを再読み込みします。

`web/wasm`はMoonBitをWebAssembly（WASM）へビルドするパッケージです。ビルド時の`wasm-gc`は、ガベージコレクション（Garbage Collection、GC）機能を備えたWASM向けのターゲット名です。`web/server`は確認用のMoonBit製ローカルサーバーです。
