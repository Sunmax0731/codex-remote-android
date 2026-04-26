# Cloud Functions

このディレクトリは、完了通知を送信するCloud Functionsの配置先。

Phase 6で実装する主な処理:

- `commands/{commandId}` の `completed` / `failed` 遷移を検出する。
- 対象ユーザーの `devices/{deviceId}.fcmToken` を取得する。
- FCM通知を送信する。
- `notificationSentAt` を更新して二重通知を防ぐ。

## 実装メモ

- トリガー: `users/{userId}/sessions/{sessionId}/commands/{commandId}` の更新。
- 対象ステータス: `completed` / `failed` への遷移のみ。
- 通知channel: Android側の `remote_codex_completion` と合わせる。
- payload: `type`, `userId`, `sessionId`, `commandId`, `status` の最小構成。
- 通知本文: `resultText` または `errorText` の先頭120文字を1行に整形する。

## 検証

```powershell
npm.cmd run build
npm.cmd run check
firebase deploy --only functions
```

`firebase deploy --only functions` は事前に `npm --prefix "$RESOURCE_DIR" run build` を実行し、`lib/index.js` を生成する。

初回デプロイ時の注意:

- Blaze plan が必要。
- Cloud Functions / Cloud Build / Artifact Registry / Cloud Run / Eventarc / Pub/Sub / Compute Engine API が必要。
- 初回の2nd gen FunctionsデプロイではEventarc権限反映に数分かかる場合がある。その場合は数分待って `firebase deploy --only functions` を再実行する。
- Artifact RegistryのCloud Functions imageには7日保持のcleanup policyを設定済み。

## デプロイ済み関数

- `notifyCommandCompletion`
- version: v2
- region: `asia-northeast1`
- runtime: `nodejs22`
- trigger: `google.cloud.firestore.document.v1.updated`
