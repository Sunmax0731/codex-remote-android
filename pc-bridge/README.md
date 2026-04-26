# PCブリッジ

このディレクトリは自宅PC上で動くPCブリッジの配置先。

MVPではNode.js/TypeScriptを第一候補にする。PCブリッジはFirebase上の `queued` コマンドを監視し、固定ワークスペース上のCodexワークフローへ指示を渡し、最終結果をFirestoreへ書き戻す。

## MVP責務

- Firebaseへアウトバウンド接続する。
- 自分宛の `queued` コマンドだけをclaimする。
- コマンドを `running`、`completed`、`failed` に遷移させる。
- Androidアプリから受け取った文字列をraw shell commandとして実行しない。
- 固定ワークスペースだけを対象にする。
- `lastSeenAt` heartbeatを更新する。

## 初期セットアップ

```powershell
npm.cmd install
npm.cmd run build
```

ローカル設定は `config.example.json` を参考に `config.local.json` を作成する。`config.local.json` はGitに含めない。

## 実行方法

1回だけ処理する場合:

```powershell
npm.cmd run start
```

常駐して自動pollingする場合:

```powershell
npm.cmd run start:watch
```

`start:watch` は `pollIntervalSeconds` 間隔でFirestoreを確認し、1回のtickで最大 `maxCommandsPerTick` 件の `queued` commandを処理する。heartbeatは `heartbeatIntervalSeconds` 間隔で別タイマーから更新する。停止する場合は `Ctrl+C` を押す。

## Windows常駐起動

手動ターミナル依存を避けるため、Windows用のバッチファイルを `scripts/` に用意している。

### 推奨手順

通常利用では、まずバックグラウンド起動で動作確認し、問題なければタスクスケジューラへ登録する。

1. バックグラウンド起動する。

```powershell
cd D:\Claude\FlutterApp\codex-remote-android\pc-bridge
.\scripts\start-watch-background.bat
```

2. watcherが動いていることを確認する。

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -match 'dist[\\/]+src[\\/]+watch.js|start:watch|run-watch.bat' } |
  Select-Object ProcessId,Name,CommandLine
```

3. スマホアプリからセッションへ送信し、`queued` から `running` / `completed` へ進むことを確認する。

4. ログを確認する。

```powershell
Get-ChildItem .\logs -Filter 'pc-bridge-watch-*.log' |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1 |
  ForEach-Object { Get-Content $_.FullName -Tail 40 }
```

5. 問題なければ、ログオン時に自動起動するタスクを登録する。

```powershell
.\scripts\register-watch-task.bat
schtasks /Run /TN "CodexRemotePcBridge"
```

タスク登録後は、PCにログオンするとPCブリッジwatcherが起動する。

### フォアグラウンドで起動

ログを残しながら現在のコマンドプロンプト内でwatcherを実行する。

```powershell
Set-Location D:\Claude\FlutterApp\codex-remote-android\pc-bridge
.\scripts\run-watch.bat
```

停止は `Ctrl+C`。ログは次に出力される。ログは起動ごとに別ファイルになる。

```text
pc-bridge\logs\pc-bridge-watch-<random>.log
```

### バックグラウンドで起動

最小化された別ウィンドウでwatcherを起動する。

```powershell
Set-Location D:\Claude\FlutterApp\codex-remote-android\pc-bridge
.\scripts\start-watch-background.bat
```

起動確認:

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -match 'dist[\\/]+src[\\/]+watch.js|start:watch|run-watch.bat' } |
  Select-Object ProcessId,Name,CommandLine
```

停止する場合は、起動した最小化ウィンドウで `Ctrl+C` を押す。ウィンドウが見つからない場合は、上記の `ProcessId` を確認して終了する。

```powershell
Stop-Process -Id <ProcessId>
```

### タスクスケジューラ登録

ログオン時に自動起動するタスクを登録する。

```powershell
Set-Location D:\Claude\FlutterApp\codex-remote-android\pc-bridge
.\scripts\register-watch-task.bat
```

登録後すぐに起動する場合:

```powershell
schtasks /Run /TN "CodexRemotePcBridge"
```

登録状態の確認:

```powershell
schtasks /Query /TN "CodexRemotePcBridge" /V /FO LIST
```

登録を削除する場合:

```powershell
schtasks /Delete /TN "CodexRemotePcBridge" /F
```

タスクスケジューラ起動では画面に常駐ログが出ないため、動作確認は `pc-bridge\logs\pc-bridge-watch-<random>.log` とFirestore上のcommand状態で行う。

### 停止方法

起動した最小化ウィンドウが見える場合は、そのウィンドウで `Ctrl+C` を押す。

ウィンドウが見つからない場合は、プロセスを確認して停止する。

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -match 'dist[\\/]+src[\\/]+watch.js|start:watch|run-watch.bat' } |
  Select-Object ProcessId,Name,CommandLine
```

対象の `ProcessId` を指定して停止する。

```powershell
Stop-Process -Id <ProcessId>
```

### 使い分け

- `run-watch.bat`: 現在のターミナルで動作を見ながら起動する。
- `start-watch-background.bat`: 手動でバックグラウンド起動する。
- `register-watch-task.bat`: Windowsログオン時に自動起動するタスクを登録する。
- `npm.cmd run start`: 常駐しない。queued commandを1回だけ処理して終了する。
- `npm.cmd run start:watch`: 常駐するが、手動ターミナルに依存する。

## ローカルrelay検証

Firebase実接続前に、ローカルJSON relayでコマンドライフサイクルを検証できる。

```powershell
npm.cmd run check
npm.cmd run validate:local
```

`validate:local` は一時ディレクトリにrelay stateを作成し、次を確認する。

- `queued` コマンドをclaimして `running` にする。
- `claimExpiresAt` を過ぎた `running` コマンドを再claimできる。
- 成功コマンドを `completed` にし、`resultText` を保存する。
- 検証用失敗コマンドを `failed` にし、`errorText` を保存する。
- 処理対象がなくなったら `none` として終了する。

## 実装境界

Codex呼び出しは `CodexInvoker` interfaceの実装として切り替える。

### `stub` mode

デフォルトは `SafeStubCodexInvoker`。

- スマホ入力をraw shell commandとして実行しない。
- 空の指示は失敗として扱う。
- `/fail` で始まる指示は検証用の失敗として扱う。
- それ以外は受領メッセージを `resultText` として返す。

`stub` modeは疎通確認用のため、スマホから送った質問に対する実際のCodex回答は返さない。実回答が必要な場合は、#29の受け入れ基準を満たしたうえで `cli` modeに切り替える。

### `cli` mode

`config.local.json` で `codexMode` を `cli` にすると、固定した `codexCommandPath` から `codex exec` を起動する。

```json
{
  "codexMode": "cli",
  "codexCommandPath": "codex.cmd",
  "codexModel": "gpt-5.2",
  "codexBypassSandbox": false,
  "codexSandbox": "workspace-write",
  "codexTimeoutSeconds": 900,
  "codexProgressIntervalSeconds": 60
}
```

安全境界:

- Node.jsの `spawn(..., { shell: false })` で起動する。Windowsの `.cmd` だけはローカル設定の固定コマンドを `cmd.exe /d /s /c` 経由で起動する。
- スマホ入力はstdinでCodex promptとして渡す。
- 実行ファイル、作業ディレクトリ、sandbox、timeoutはPCブリッジのローカル設定で固定する。
- スマホ入力から実行ファイルやshell引数を指定できない。
- `--output-last-message` の出力を `resultText` として保存する。
- `codexModel` を設定すると `codex exec -m <model>` として固定モデルを使う。
- `codexBypassSandbox` を `true` にすると、`codex exec --dangerously-bypass-approvals-and-sandbox` で起動する。GitHub CLIなどVS Code通常シェル相当のネットワークアクセスが必要な場合だけ、ローカルPCで明示的に有効化する。
- `codexProgressIntervalSeconds` ごとに `progressText` と `progressUpdatedAt` を更新する。標準は60秒で、stdout/stderrがまだ空でも実行中であることと経過時間を返す。進捗更新時には `claimExpiresAt` も延長する。
- Codex CLIが最終メッセージを出さなかった場合は `failed` として `errorText` にCLIログを保存する。

実Codex実行は作業内容を伴うため、Issueの受入条件が明確な時だけ `cli` modeで検証する。

### #29 実Codex CLI受け入れ検証

2026-04-26時点の検証設定:

```json
{
  "codexMode": "cli",
  "codexCommandPath": "codex.cmd",
  "codexModel": "gpt-5.2",
  "codexBypassSandbox": true,
  "codexSandbox": "workspace-write",
  "codexTimeoutSeconds": 900,
  "codexProgressIntervalSeconds": 60,
  "pollIntervalSeconds": 5,
  "heartbeatIntervalSeconds": 300,
  "maxCommandsPerTick": 5
}
```

確認済み:

- `codex.cmd exec --help` が利用可能。
- 既定モデル `gpt-5.5` はこのPCのCodex CLI `0.114.0` では未対応のため、`codexModel: "gpt-5.2"` を固定する。
- WindowsではNode.jsから `.cmd` を直接 `spawn(..., { shell: false })` すると `spawn EINVAL` になるため、PCブリッジはローカル設定の `.cmd` だけを `cmd.exe /d /s /c` 経由で起動する。
- スマホからの本文は引き続きstdin promptとして渡し、shell文字列やCLI引数としては扱わない。
- ローカルrelayで `cli` modeの成功結果が `completed` + `resultText` に保存されることを確認済み。
- 未対応モデルなどでCodex CLIが失敗した場合、`failed` + `errorText` に保存されることを確認済み。
- `codexTimeoutSeconds` 超過時は `failed` + `errorText` として扱うことを確認済み。
- Codex CLI実行中は1分ごとに `progressText` + `progressUpdatedAt` を更新し、スマホ側で途中処理ログを確認できる。進捗更新のたびに `claimExpiresAt` を延長する。
- Firestore relayで短いCLI smokeを処理し、`completed` + `resultText: CLI_FIRESTORE_OK` + `notificationSuccessCount: 1` を確認済み。
- `codexBypassSandbox: true` で `gh issue list --limit 2` が成功し、スマホ経由Codex CLIからGitHub Issue一覧を取得できることを確認済み。

ユーザー受け入れシナリオ:

1. PC側で `npm.cmd run start:watch` を起動して常駐させる。
2. スマホアプリでセッションを作成する。
3. セッションで次の文を送信する。

```text
DドライブのClaudeディレクトリ以下にあるローカルリポジトリを列挙してください。またそれらの概要を要約して、リポジトリ名と併記して教えてください。
```

4. 送信後、アプリをバックグラウンドへ移す。
5. PC側で処理が完了したらスマホにプッシュ通知が届くことを確認する。
6. 通知またはアプリ画面から対象セッションを開き、Codexの回答が表示されることを確認する。

このシナリオではコード変更を求めない。Codexがファイル変更を提案した場合でも、ユーザー確認なしに変更を前提とする検証には進めない。

## relay mode

### `local`

`local` は開発用のJSON relay。Firebase未設定でもPCブリッジの状態遷移を検証できる。

```json
{
  "relayMode": "local",
  "localRelayPath": ".local\\relay-state.json"
}
```

### `firestore`

`firestore` はMVP本番想定のrelay。Firebase Admin SDKでFirestoreへ接続する。

```json
{
  "relayMode": "firestore",
  "firebaseProjectId": "your-firebase-project-id",
  "serviceAccountPath": "D:\\secure\\codex-remote-service-account.json",
  "pollIntervalSeconds": 5,
  "heartbeatIntervalSeconds": 300,
  "maxCommandsPerTick": 5
}
```

`serviceAccountPath` はローカルPC上の安全な場所に置き、Gitには含めない。

実装済みの操作:

- `collectionGroup("commands")` から自分宛の `queued` コマンドを検索する。
- Firestore transactionで `running` にclaimする。
- `claimExpiresAt` を過ぎた `running` コマンドは、watcher再起動後に再claimして処理を再開できる。
- `completed` / `failed` と結果をセッションへ書き戻す。
- `pcBridges/{pcBridgeId}` のheartbeatを `heartbeatIntervalSeconds` 間隔で更新する。
- `pcBridges/{pcBridgeId}` の `lastQueueCheckedAt` をqueue確認ごとに更新する。

実Firebase資格情報がまだないため、Phase 4時点ではコンパイル確認のみ行う。実接続検証はFirebaseプロジェクト設定後に行う。

