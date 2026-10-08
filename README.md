# md2slack

MoonBitを学びながら、MarkdownテキストをSlackへ貼り付けやすい形式に変換するWebサイトを作るプロジェクトです。

## コマンドラインインターフェース（CLI）で実行

```powershell
moon run cmd/main
```

テストは`moon test`で実行できます。

## ブラウザで確認

MoonBitと、WebAssemblyのJavaScript文字列連携に対応したブラウザが必要です。リポジトリのルートで次を実行します。

```powershell
moon build --target wasm-gc web/wasm
moon run web/server
```

ブラウザで <http://127.0.0.1:8000/> を開きます。サーバーは`Ctrl+C`で停止します。

`web/wasm`はMoonBitをWebAssembly（WASM）へビルドするパッケージです。ビルド時の`wasm-gc`は、ガベージコレクション（Garbage Collection、GC）機能を備えたWASM向けのターゲット名です。`web/server`は確認用のMoonBit製ローカルサーバーです。
