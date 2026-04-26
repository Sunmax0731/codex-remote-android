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
firebase deploy --only functions
```

`firebase deploy --only functions` は Blaze plan が必要。Spark plan のままでは `artifactregistry.googleapis.com` / `cloudbuild.googleapis.com` を有効化できず停止する。
