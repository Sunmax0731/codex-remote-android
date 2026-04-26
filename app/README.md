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

`google-services.json` はFirebase SDK設定時に `android/app/google-services.json` へ配置する。Phase 5 scaffold時点では、ユーザーが取得したファイルを `app/google-services.json` に一時配置しており、この一時配置パスは誤コミット防止のためGit管理外にしている。

## MVP責務

- Firebase Authまたはペアリング状態を保持する。
- セッション一覧を表示する。
- セッションを作成する。
- 選択中セッションへテキスト指示を送信する。
- コマンドの最終結果または失敗状態を表示する。
- FCM tokenを登録・更新する。
- 完了通知タップ時に該当セッションへ遷移する。

