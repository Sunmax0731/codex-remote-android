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

起動時に `Firebase.initializeApp()` を実行し、初期化結果を表示する。匿名認証、セッション一覧、コマンド送信は後続Issueで実装する。

## MVP責務

- Firebase Authまたはペアリング状態を保持する。
- セッション一覧を表示する。
- セッションを作成する。
- 選択中セッションへテキスト指示を送信する。
- コマンドの最終結果または失敗状態を表示する。
- FCM tokenを登録・更新する。
- 完了通知タップ時に該当セッションへ遷移する。

