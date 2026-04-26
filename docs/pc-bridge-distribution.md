# PCブリッジ配布パッケージ

この文書は、Codex Remote AndroidのPCブリッジを利用者へ配布するための手順をまとめる。

## 暫定方針

現時点では、PCブリッジはzipパッケージとして配布する。

- exe化はまだ行わない。
- 利用者PCで `npm.cmd install` を実行する。
- Node.js 22以上を前提にする。
- `config.local.json` と service account JSON は利用者PCだけで作成する。
- `node_modules`、ログ、ローカル設定、service account JSONはzipに含めない。

exe化は、配布経路、署名、アップデート方式、Windows SmartScreen対策を決めてから別Issueで扱う。

## 配布パッケージを作成する

リポジトリルートで次を実行する。

```powershell
cd pc-bridge
npm.cmd install
npm.cmd run package:dist
```

出力先:

```text
pc-bridge\.local\distribution\codex-remote-pc-bridge.zip
```

zipには次を含める。

- `README.md`
- `config.example.json`
- `package.json`
- `package-lock.json`
- `tsconfig.json`
- `src/`
- `scripts/`
- `setup-web/`
- `dist/`
- `docs/pc-bridge-distribution.md`
- `docs/distribution-prep.md`

zipには次を含めない。

- `config.local.json`
- `node_modules/`
- `.local/`
- `logs/`
- service account JSON
- Firebase debug log
- Codex / GitHub / OpenAI など外部サービスのtoken

## 利用者PCで展開する

例:

```powershell
New-Item -ItemType Directory -Force -Path D:\Tools\CodexRemote
Expand-Archive .\codex-remote-pc-bridge.zip -DestinationPath D:\Tools\CodexRemote -Force
Set-Location D:\Tools\CodexRemote\codex-remote-pc-bridge
```

依存関係をインストールする。

```powershell
npm.cmd install
npm.cmd run build
```

## config.local.jsonを作成する

```powershell
Copy-Item config.example.json config.local.json
```

主な設定:

- `relayMode`: 本番利用では `firestore`
- `firebaseProjectId`: 利用者自身のFirebase project ID
- `serviceAccountPath`: PCローカルのservice account JSONパス
- `pcBridgeId`: 通常は `home-main-pc`
- `displayName`: Androidアプリに表示するPC名
- `workspaceName`: 作業場所の表示名
- `workspacePath`: Codex CLIを実行する作業ディレクトリ
- `codexMode`: Codex CLIを使う場合は `cli`
- `codexCommandPath`: 例 `codex.cmd`
- `codexModel`: 既定モデル
- `codexBypassSandbox`: 既定は `false`

`config.local.json` はGit、Issue、チャット、スクリーンショットに含めない。

## セットアップWeb UIを起動する

AndroidアプリへFirebase client configを入力するため、PCセットアップWeb UIを使う。

```powershell
npm.cmd run setup:web
```

ブラウザで開く。

```text
http://127.0.0.1:8787
```

UIで `google-services.json` を読み込み、QRを生成する。service account JSONはQRへ含めない。

## PCブリッジを起動する

手動起動:

```powershell
npm.cmd run start:watch
```

バックグラウンド起動:

```powershell
.\scripts\start-watch-background.bat
```

Windowsログオン時に自動起動するタスク登録:

```powershell
.\scripts\register-watch-task.bat
schtasks /Run /TN "CodexRemotePcBridge"
```

## 起動確認

プロセス確認:

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -match 'dist[\\/]+src[\\/]+watch.js|start:watch|run-watch.bat' } |
  Select-Object ProcessId,Name,CommandLine
```

ログ確認:

```powershell
Get-ChildItem .\logs -Filter 'pc-bridge-watch-*.log' |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1 |
  ForEach-Object { Get-Content $_.FullName -Tail 40 }
```

Androidアプリ側では、PC接続情報の最終heartbeat時刻が更新されることを確認する。

## 停止する

手動起動中は `Ctrl+C` で停止する。

バックグラウンド起動の場合:

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -match 'dist[\\/]+src[\\/]+watch.js|start:watch|run-watch.bat' } |
  Select-Object ProcessId,Name,CommandLine
Stop-Process -Id <ProcessId>
```

タスクスケジューラ登録を削除する場合:

```powershell
schtasks /Delete /TN "CodexRemotePcBridge" /F
```

## 配布者向けチェックリスト

- [ ] zip作成前に `npm.cmd run check` が通っている。
- [ ] `npm.cmd run package:dist` が成功している。
- [ ] zipに `config.local.json` が含まれていない。
- [ ] zipに `node_modules/` が含まれていない。
- [ ] zipに `logs/` が含まれていない。
- [ ] zipにservice account JSONが含まれていない。
- [ ] 利用者向けにNode.js 22以上が必要であることを案内している。
- [ ] 利用者向けにCodex CLIが必要であることを案内している。

## 判断が必要な項目

次は配布者の判断が必要。

- zipをどこで配布するか
  - GitHub Release
  - 個別共有
  - 限定公開ストレージ
- 将来的にexe化するか
- PCブリッジの自動アップデートを用意するか
- 利用者ごとに既定 `pcBridgeId` を変えるか
