# Release E2E smoke runbook

Release前の実機E2E smokeは、Android実機、Firebase、PCブリッジを同じ検証用Firebaseプロジェクトに接続して実施する。ホスト済みFirebaseや共有サービスアカウントは使わない。

## 前提

- Android実機がUSBデバッグまたはワイヤレスデバッグでPCから見える。
- `flutter devices` にAndroid実機が表示される。
- `adb`、`flutter`、Node.js 22以上、npmが利用できる。
- `pc-bridge/config.local.json` が検証用Firebase、検証用service account、対象workspaceを指している。
- APKをインストールする場合は、release APKを事前に作成するか、debug APKで確認する。

## 半自動チェック

端末検出、APK情報、インストール済みアプリのversion、直近logcatをJSONで取得する。

```powershell
.\scripts\run-android-e2e-smoke.ps1 `
  -EvidencePath .\docs\releases\e2e-smoke-<version>.json
```

debug APKをビルドして実機へ入れる場合:

```powershell
.\scripts\run-android-e2e-smoke.ps1 `
  -BuildDebug `
  -Install `
  -EvidencePath .\docs\releases\e2e-smoke-debug.json
```

release APKを明示して入れる場合:

```powershell
.\scripts\run-android-e2e-smoke.ps1 `
  -Install `
  -ApkPath .\app\build\app\outputs\flutter-apk\app-release.apk `
  -EvidencePath .\docs\releases\e2e-smoke-<version>.json
```

複数端末がある場合は `-DeviceId` を指定する。

## 手動操作ポイント

1. アプリを起動する。
2. Firebase setup QRを読み込む、または保存済みFirebase設定で起動できることを確認する。
3. 通知許可ダイアログが出る場合は許可する。
4. PCブリッジ表示で対象ブリッジがactiveまたは直近heartbeatありになることを確認する。
5. `Check PC now` を実行し、応答時刻が更新されることを確認する。
6. 新規セッションを作成する。
7. セッション詳細から短いコマンドを送信する。
8. PCブリッジが処理し、アプリ上でcommandが `completed` になることを確認する。
9. 完了通知が端末に届くことを確認する。

## PCブリッジ実行

手元のターミナルでログを見ながら実行する。

```powershell
Set-Location pc-bridge
npm.cmd run start:watch
```

別ターミナルで診断情報を取得する。

```powershell
Set-Location pc-bridge
npm.cmd run diagnose
```

## Firestore証跡

最新セッションと最新command、PCブリッジheartbeat、通知送信カウントをJSONで取得する。

```powershell
Set-Location pc-bridge
npm.cmd run e2e:evidence
```

特定のセッションまたはcommandを指定する場合:

```powershell
npm.cmd run e2e:evidence -- --session-id <sessionId> --command-id <commandId>
```

確認する主な項目:

- `pcBridge.status`: `active`
- `pcBridge.lastSeenAt`: release smoke実施中の時刻
- `pcBridge.lastHealthCheckStatus`: `responded`
- `session.status`: `completed`
- `command.status`: `completed`
- `command.notificationSuccessCount`: `1` 以上
- `command.notificationFailureCount`: `0`

## 失敗時の切り分け

- 端末が見えない: `flutter devices --machine` と `adb devices -l` を確認する。ワイヤレスデバッグはペアリング後に接続が切れていないか確認する。
- APK install失敗: 既存アプリの署名違い、端末空き容量、Androidの提供元不明アプリ設定を確認する。
- Firebase setup失敗: QRのproject ID、API key、app ID、sender IDを確認する。秘密情報をIssueへ貼らない。
- PCブリッジがactiveにならない: `pc-bridge/config.local.json`、service account path、`npm.cmd run diagnose`、watcherログを確認する。
- commandがqueuedのまま: `targetPcBridgeId` がPCブリッジの `pcBridgeId` と一致しているか確認する。
- commandがfailedになる: watcherログとCodex CLIのexit codeを確認する。
- 通知が届かない: Android通知許可、FCM token登録、Functionsログ、`notificationFailureCount` と `notificationLastError` を確認する。

## Release evidenceテンプレート

```markdown
## E2E smoke evidence

- Date:
- App versionName/versionCode:
- Device:
- Android version:
- Install method: release APK / debug APK / existing install
- Firebase project: masked project ID only
- PC bridge: active, lastSeenAt=
- Health check: responded, requestedAt=, respondedAt=
- Session ID:
- Command ID:
- Command status: completed
- notificationSuccessCount:
- notificationFailureCount:
- Manual checks:
  - Firebase setup:
  - Notification permission:
  - Session creation:
  - Command completion on device:
  - Completion notification:
- Evidence files:
  - scripts/run-android-e2e-smoke.ps1 output:
  - npm.cmd run e2e:evidence output:
```
