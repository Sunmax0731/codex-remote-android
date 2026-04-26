# Cloud Functions

このディレクトリは、完了通知を送信するCloud Functionsの配置先。

Phase 6で実装する主な処理:

- `commands/{commandId}` の `completed` / `failed` 遷移を検出する。
- 対象ユーザーの `devices/{deviceId}.fcmToken` を取得する。
- FCM通知を送信する。
- `notificationSentAt` を更新して二重通知を防ぐ。

