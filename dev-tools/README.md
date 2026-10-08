# クリップボードの調査

Windows上のPowerShell 7で、クリップボードに保存されている形式と内容を確認するための開発用ツールです。

## セットアップ

リポジトリのルートで、Single-Threaded Apartment（STA：Windowsのスレッド実行方式）を指定してPowerShellを起動します。

```powershell
pwsh -STA
```

起動したPowerShellでスクリプトを読み込みます。

```powershell
. ./dev-tools/clipboard-debug.ps1
```

先頭の `. ` は、現在のセッションに関数を読み込む「ドットソーシング」です。スクリプト内の `Add-Type -AssemblyName System.Windows.Forms` が、Windowsのクリップボードを扱うためのライブラリを読み込みます。追加のパッケージは不要です。

## 調査

セットアップ後にSlackなどで調べたい内容をコピーし、次のコマンドを手入力します。コマンド自体をコピーすると、調べたいクリップボードの内容が上書きされます。

```powershell
Show-ClipboardData
```

この関数はクリップボードを読み取るだけです。形式一覧と各データを表示し、バイナリは16進数とUTF-8・UTF-16LE（リトルエンディアンのUTF-16）で解釈した文字列を表示します。文字コードの解釈は推測なので、文字化けは取得失敗を意味しません。

`GetFormats($false)` と `GetData($format, $false)` は、別形式への自動変換を使わず保存されている形式を取得します。Slackの入力欄と送信済みメッセージなど、コピー元ごとに結果を比較してください。

## ブラウザからのコピーを比較

ChromeまたはEdgeで [clipboard-debug.html](clipboard-debug.html) を直接開きます。Webサーバーの起動は不要です。

ページには、投稿済みメッセージから取得した `slack/html` のサンプルがあります。引用・コードブロック・入れ子の箇条書き・番号付きリストを含み、箇条書きと引用内で太字→太字とコード→コード→書式なしが連続して切り替わります。`text/plain` も設定し、`copy` イベントでコピーします。

2026/10/08時点の調査では入力欄からのコピーで `slack/texty`、投稿済みメッセージからのコピーで `slack/html` が観測され、両方ともSlackに貼り付けられました。このツールでは `slack/html` に絞っています。

コピー後に `Show-ClipboardData` を実行し、Slackへの貼り付け結果と合わせて比較してください。ページにコピー失敗と表示された場合は、前のクリップボード内容が残るため、その結果を比較に使わないでください。
