# PCブリッジ自動テスト

Issue #153 以降、PCブリッジにはNode.js標準の `node:test` による自動テストを含める。
ローカルでの確認は次を標準とする。

```powershell
Set-Location pc-bridge
npm.cmd run check
npm.cmd run test
npm.cmd run validate:local
```

`npm.cmd run test` は実Firebaseに接続せず、ローカルJSON relayまたはRepository test doubleで次を確認する。

- queued commandのclaimと、異なる `targetPcBridgeId` の除外。
- `claimExpiresAt` を過ぎたrunning commandの再claim。
- 期限内running commandを重複claimしないこと。
- Codex invoker成功時のcompleted遷移。
- Codex invoker失敗時のfailed遷移。
- progress/result/error textに含まれるprivate key、Firebase API key、GitHub tokenなどのredaction。

Firestore relay、実Codex CLI、通知連携は環境依存のため、Release前smokeまたは対象Issueの検証手順で別途確認する。
