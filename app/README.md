# Androidアプリ

このディレクトリはFlutter Androidアプリの配置先。

Phase 5でFlutter Androidプロジェクトを生成済み。

生成時の主要設定:

- Flutter project name: `remote_codex`
- Android package/applicationId: `com.sunmax.remotecodex`
- 対象platform: Android
- launcher icon: `app-icon.png` から生成した `android/app/src/main/res/mipmap-*/ic_launcher.png`

```powershell
flutter create --platforms android --org com.sunmax --project-name remote_codex app
```

Firebase SDK設定で、ユーザーが取得した `google-services.json` を `android/app/google-services.json` へ配置済み。Firebase公式手順では、このファイルはFirebase SDKがアプリ設定値を参照するためにmodule rootへ置く。

導入済みFlutterFire package:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_messaging`
- `flutter_local_notifications`

その他の主要package:

- `file_picker`: `--image` 用の画像ファイル選択。
- `flutter_localizations`: 端末言語に応じたMaterial/Cupertino標準文言とアプリ文言の切替。

起動時に次を実行する。

1. `Firebase.initializeApp()`
2. Firebase Anonymous Authの `signInAnonymously()`
3. `/users/{uid}` へMVP接続先 `home-main-pc` を保存
4. FCM通知権限を要求し、`/users/{uid}/devices/android-app` へFCM tokenを保存

初回実機起動後、画面に表示される `User uid` をPCブリッジの `config.local.json` の `ownerUserId` に設定すると、PCブリッジのheartbeatを `/users/{uid}/pcBridges/home-main-pc` に保存できる。

セッション一覧では `/users/{uid}/sessions` を `updatedAt` 降順で購読し、`New session` から新規セッションを作成する。作成時はMVP接続先として `targetPcBridgeId: home-main-pc` を保存する。

セッション詳細では `/users/{uid}/sessions/{sessionId}/commands` を `createdAt` 降順で購読し、入力したテキストを `queued` コマンドとして作成する。`running` 中はPCブリッジがFirestoreに保存した進捗概要と経過時間を表示し、完了後は `resultText` または `errorText` を最終結果として表示する。

表示言語:

- 端末の言語設定から `ja`, `en`, `zh`, `ko` を自動選択する。
- 未対応言語は英語へフォールバックする。
- CLIオプション名、model名、status、ファイルパスなどの技術識別子は翻訳せず固定表示する。
- 現在は `lib/main.dart` 内の軽量な文字列テーブルで管理する。翻訳量が増えた場合はARBベースへの移行を検討する。

通知設定:

- Android 13+向けに `POST_NOTIFICATIONS` 権限を宣言。
- FCM tokenを起動時とtoken refresh時に保存。
- Android notification channel `remote_codex_completion` を作成。
- foregroundでFCMを受けた場合はlocal notificationとして表示する。
- foreground local notificationまたはbackground/terminated状態のFCM通知をタップした場合、payloadの `sessionId` に対応するセッション詳細へ遷移する。

## MVP責務

- Firebase Authまたはペアリング状態を保持する。
- セッション一覧を表示する。
- セッションを作成する。
- 選択中セッションへテキスト指示を送信する。
- コマンドの進捗概要、最終結果、失敗状態を表示する。
- FCM tokenを登録・更新する。
- 完了通知タップ時に該当セッションへ遷移する。
- 端末言語に応じて主要UIを日本語、英語、中国語、韓国語で表示する。

