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

pnpmを使う場合:

```powershell
corepack enable
corepack pnpm --version
corepack pnpm install
corepack pnpm run build
corepack pnpm audit
```

pnpmはnpmとは別のlockfileと依存解決を使うため、npm auditの結果と差が出る場合がある。ただし、pnpmを使うだけで脆弱性が必ず解消するわけではない。`corepack pnpm audit` の結果を確認し、依存更新が必要な場合は別Issueで扱う。

### Advanced CLI options from Android

The Android app can store the following session-level Codex CLI options in Firestore. The PC bridge reads them from the session document when it claims a queued command and reflects them into `codex exec`.

- `codexConfigOverrides` -> repeated `--config key=value`
- `codexEnableFeatures` -> repeated `--enable`
- `codexDisableFeatures` -> repeated `--disable`
- `codexImages` -> repeated `--image`
- `codexOss` -> `--oss`
- `codexLocalProvider` -> `--local-provider`
- `codexFullAuto` -> `--full-auto`
- `codexAddDirs` -> repeated `--add-dir`
- `codexSkipGitRepoCheck` -> `--skip-git-repo-check`
- `codexEphemeral` -> `--ephemeral`
- `codexIgnoreUserConfig` -> `--ignore-user-config`
- `codexIgnoreRules` -> `--ignore-rules`
- `codexOutputSchema` -> `--output-schema`
- `codexJson` -> `--json`

`codexBypassSandbox` has precedence over `codexFullAuto`; when bypass is enabled, the bridge uses `--dangerously-bypass-approvals-and-sandbox` instead of `--full-auto` or `--sandbox`.

ローカル設定は `config.example.json` を参考に `config.local.json` を作成する。`config.local.json` はGitに含めない。

## 実行方法

1回だけ処理する場合:

```powershell
npm.cmd run start
```

pnpmの場合:

```powershell
corepack pnpm run start
```

常駐して自動pollingする場合:

```powershell
npm.cmd run start:watch
```

pnpmの場合:

```powershell
corepack pnpm run start:watch
```

`start:watch` は `pollIntervalSeconds` 間隔でFirestoreを確認し、1回のtickで最大 `maxCommandsPerTick` 件の `queued` commandを処理する。heartbeatは `heartbeatIntervalSeconds` 間隔で別タイマーから更新する。停止する場合は `Ctrl+C` を押す。

## Windows常駐起動

手動ターミナル依存を避けるため、Windows用のバッチファイルを `scripts/` に用意している。

### 推奨手順

通常利用では、まずバックグラウンド起動で動作確認し、問題なければタスクスケジューラへ登録する。

1. バックグラウンド起動する。

```powershell
cd pc-bridge
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
Set-Location pc-bridge
.\scripts\run-watch.bat
```

停止は `Ctrl+C`。ログは次に出力される。ログは起動ごとに別ファイルになる。

```text
pc-bridge\logs\pc-bridge-watch-<random>.log
```

### バックグラウンドで起動

最小化された別ウィンドウでwatcherを起動する。

```powershell
Set-Location pc-bridge
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
Set-Location pc-bridge
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

pnpmの場合:

```powershell
corepack pnpm run check
corepack pnpm run validate:local
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
  "codexModel": "gpt-5.4",
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
- `codexModel` を設定すると `codex exec -m <model>` として既定モデルを使う。セッションに `codexModel` がある場合はセッション設定を優先する。
- `codexBypassSandbox` を `true` にすると、`codex exec --dangerously-bypass-approvals-and-sandbox` で起動する。GitHub CLIなどVS Code通常シェル相当のネットワークアクセスが必要な場合だけ、ローカルPCで明示的に有効化する。
- セッションに `codexSandbox`, `codexBypassSandbox`, `codexProfile` がある場合は、それぞれ `--sandbox`, `--dangerously-bypass-approvals-and-sandbox`, `--profile` としてPCブリッジのローカル既定値より優先する。
- `codexProgressIntervalSeconds` ごとに `progressText` と `progressUpdatedAt` を更新する。標準は60秒で、stdout/stderrがまだ空でも実行中であることと経過時間を返す。進捗更新時には `claimExpiresAt` も延長する。
- Codex CLIが最終メッセージを出さなかった場合は `failed` として `errorText` にCLIログを保存する。

Androidアプリでは `CLI defaults` から `codexModel`, `codexSandbox`, `codexBypassSandbox`, `codexProfile` の既定値を保存し、New session時の初期値として使う。モデルとsandboxは選択肢から選び、profileは任意文字列、bypass sandboxはスイッチで指定する。セッション一覧では対象セッションをロングタップすると、そのセッションに保存されたCLIオプションを確認できる。

### 匿名UID変更への追従

Androidアプリを再インストールした場合など、Firebase Anonymous AuthのUIDが変わることがある。Firestore relayでは、PCブリッジが `ownerUserId` のユーザーだけでなく、`users/*` のうち `defaultPcBridgeId` が現在の `pcBridgeId` と一致するユーザーにも `pcBridges/{pcBridgeId}` の状態を書き込む。

これにより、スマホ側のUIDが変わっても、アプリが起動して `users/{uid}.defaultPcBridgeId` を保存した後は、watcherの次回 heartbeat / queue check で新しいUID側にも `lastSeenAt` / `lastQueueCheckedAt` が更新される。`ownerUserId` は明示的に追跡したいユーザーを追加するための任意設定として残す。

### スマホからの任意稼働確認

Androidアプリの `Check PC now` は `users/{uid}/pcBridges/{pcBridgeId}/healthChecks/{healthCheckId}` に `requested` 状態の確認要求を作成する。PCブリッジwatcherは通常の5秒polling中に未応答health checkを検出し、稼働中であれば `responded` と `respondedAt` を書き戻す。

アプリ側では `pcBridges/{pcBridgeId}` の `lastHealthCheckRequestedAt` / `lastHealthCheckRespondedAt` / `lastHealthCheckStatus` を表示する。watcherが停止している場合は応答時刻が更新されないため、直近heartbeatと合わせてPC側常駐プロセスの停止を判断できる。

実Codex実行は作業内容を伴うため、Issueの受入条件が明確な時だけ `cli` modeで検証する。

### #29 実Codex CLI受け入れ検証

2026-04-26時点の検証設定:

```json
{
  "codexMode": "cli",
  "codexCommandPath": "codex.cmd",
  "codexModel": "gpt-5.4",
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
- 既定モデルは `codexModel: "gpt-5.4"` とする。スマホのNew sessionで指定したモデルがある場合はセッション設定を優先する。
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

実接続検証は、利用者自身のFirebaseプロジェクト、service account JSON、`ownerUserId` を設定した後に行う。

## Firebase setup QR

For a guided local frontend, start the setup web UI:

```powershell
cd pc-bridge
npm run setup:web
```

Open `http://127.0.0.1:8787`. The UI includes cloud service links,
step-by-step Firebase setup guidance, JSON registration checks, fixed
distributed APK settings, and Android setup QR generation. The distributed APK
uses the fixed app name `RemoteCodex` and Android package name
`com.sunmax.remotecodex`. The service account JSON check runs in the browser
for setup progress only. It is not sent to the QR generator and is not included
in the QR payload.

The setup UI can switch between English, Japanese, and Chinese. The selected
language is saved in the browser with the other local setup inputs.

To avoid typing the Android Firebase client values on the phone, generate a QR
code from `google-services.json` on the PC:

```powershell
cd pc-bridge
npm run qr:firebase -- --google-services ..\app\android\app\google-services.json --package com.sunmax.remotecodex
```

The command prints a QR code in the terminal. The Android Firebase setup screen
can scan it with `Scan setup QR` and fill the form automatically.

For APK distribution, do not ask users to choose an arbitrary package name.
Firebase Android app registration and QR generation must use
`com.sunmax.remotecodex`, which matches the distributed APK.

The QR payload includes only Firebase client configuration:

- `projectId`
- `apiKey`
- `appId`
- `messagingSenderId`
- `storageBucket` when present

The QR payload must not include service account JSON, private keys, Admin SDK
credentials, PC bridge tokens, or local workspace settings.

If the terminal QR is hard to scan, also write a PNG:

```powershell
npm run qr:firebase -- --out .local\firebase-setup-qr.png
```
