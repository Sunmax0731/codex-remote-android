# Androidアプリ

このディレクトリはFlutter Androidアプリの配置先。

Phase 3時点では、このPCのPATH上に `flutter` がないため、Flutterプロジェクト生成は未実施。

Flutter SDK導入後、Phase 5で次のように生成する想定。

```powershell
flutter create --platforms android .
```

## MVP責務

- Firebase Authまたはペアリング状態を保持する。
- セッション一覧を表示する。
- セッションを作成する。
- 選択中セッションへテキスト指示を送信する。
- コマンドの最終結果または失敗状態を表示する。
- FCM tokenを登録・更新する。
- 完了通知タップ時に該当セッションへ遷移する。

