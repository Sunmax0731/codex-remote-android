# Androidアプリ

このディレクトリはFlutter Androidアプリの配置先。

Phase 5でFlutter Androidプロジェクトを生成済み。

生成時の主要設定:

- Flutter project name: `remote_codex`
- Android package/applicationId: `com.sunmax.remotecodex`
- 対象platform: Android

```powershell
flutter create --platforms android --org com.sunmax --project-name remote_codex app
```

Firebase SDK設定で、ユーザーが取得した `google-services.json` を `android/app/google-services.json` へ配置済み。Firebase公式手順では、このファイルはFirebase SDKがアプリ設定値を参照するためにmodule rootへ置く。

導入済みFlutterFire package:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`

起動時に次を実行する。

1. `Firebase.initializeApp()`
2. Firebase Anonymous Authの `signInAnonymously()`
3. `/users/{uid}` へMVP接続先 `home-main-pc` を保存

初回実機起動後、画面に表示される `User uid` をPCブリッジの `config.local.json` の `ownerUserId` に設定すると、PCブリッジのheartbeatを `/users/{uid}/pcBridges/home-main-pc` に保存できる。

セッション一覧では `/users/{uid}/sessions` を `updatedAt` 降順で購読し、`New session` から新規セッションを作成する。作成時はMVP接続先として `targetPcBridgeId: home-main-pc` を保存する。

セッション詳細では `/users/{uid}/sessions/{sessionId}/commands` を `createdAt` 降順で購読し、入力したテキストを `queued` コマンドとして作成する。処理中の逐次ログは表示せず、Firestoreに保存された `resultText` または `errorText` を最終結果として表示する。

## MVP責務

- Firebase Authまたはペアリング状態を保持する。
- セッション一覧を表示する。
- セッションを作成する。
- 選択中セッションへテキスト指示を送信する。
- コマンドの最終結果または失敗状態を表示する。
- FCM tokenを登録・更新する。
- 完了通知タップ時に該当セッションへ遷移する。

