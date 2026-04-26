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

