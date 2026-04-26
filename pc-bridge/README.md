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

現時点のCodex呼び出しは `SafeStubCodexInvoker` による安全なstub。

- スマホ入力をraw shell commandとして実行しない。
- 空の指示は失敗として扱う。
- `/fail` で始まる指示は検証用の失敗として扱う。
- それ以外は受領メッセージを `resultText` として返す。

実Codex連携は後続Issueで `CodexInvoker` interfaceの実装として追加する。

