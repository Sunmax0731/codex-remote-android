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

`start:watch` は `pollIntervalSeconds` 間隔でFirestoreを確認し、1回のtickで最大 `maxCommandsPerTick` 件の `queued` commandを処理する。停止する場合は `Ctrl+C` を押す。

## ローカルrelay検証

Firebase実接続前に、ローカルJSON relayでコマンドライフサイクルを検証できる。

```powershell
npm.cmd run check
npm.cmd run validate:local
```

`validate:local` は一時ディレクトリにrelay stateを作成し、次を確認する。

- `queued` コマンドをclaimして `running` にする。
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
  "codexSandbox": "workspace-write",
  "codexTimeoutSeconds": 900
}
```

安全境界:

- `spawn(..., { shell: false })` で起動する。
- スマホ入力はstdinでCodex promptとして渡す。
- 実行ファイル、作業ディレクトリ、sandbox、timeoutはPCブリッジのローカル設定で固定する。
- スマホ入力から実行ファイルやshell引数を指定できない。
- `--output-last-message` の出力を `resultText` として保存する。

実Codex実行は作業内容を伴うため、Issueの受入条件が明確な時だけ `cli` modeで検証する。

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
  "pollIntervalSeconds": 10,
  "maxCommandsPerTick": 5
}
```

`serviceAccountPath` はローカルPC上の安全な場所に置き、Gitには含めない。

実装済みの操作:

- `collectionGroup("commands")` から自分宛の `queued` コマンドを検索する。
- Firestore transactionで `running` にclaimする。
- `completed` / `failed` と結果をセッションへ書き戻す。
- `pcBridges/{pcBridgeId}` のheartbeatを更新する。

実Firebase資格情報がまだないため、Phase 4時点ではコンパイル確認のみ行う。実接続検証はFirebaseプロジェクト設定後に行う。

