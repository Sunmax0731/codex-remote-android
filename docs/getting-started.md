# 利用開始手順

この手順は、Codex Remote Androidを自宅PCとAndroidスマホで使い始めるための準備をまとめたものです。コマンドは、リポジトリルートから実行する前提で相対パスを使います。

## 1. 前提を確認する

PC側:

- Windows PC
- VS Code
- Codex CLI
- Node.js / npm
- Firebase CLI
- Flutter SDK
- Android SDK platform-tools
- Git / GitHub CLI

Android側:

- Androidスマホ
- 開発者向けオプション
- ワイヤレスデバッグまたはUSBデバッグ
- Firebase Androidアプリ設定ファイル `app/android/app/google-services.json`

クラウド側:

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Cloud Functions
- Blazeプラン

## 2. 自分のFirebaseプロジェクトを準備する

利用者自身のFirebase/GCPプロジェクトを用意します。既存プロジェクトを使っても構いませんが、コマンド本文や結果がFirestoreに保存されるため、このアプリ専用のプロジェクトを推奨します。

Firebase Consoleでプロジェクトを作成し、次を設定します。

1. AuthenticationでAnonymous Authを有効化する。
2. Firestore Databaseを作成する。
3. Cloud Messagingを利用できる状態にする。
4. Cloud Functionsを使うため、Blazeプランと必要なGoogle Cloud APIを有効化する。
5. Androidアプリを登録し、package nameを `com.sunmax.remotecodex` にする。
6. `google-services.json` をダウンロードし、`app/android/app/google-services.json` に配置する。
7. PCブリッジ用のservice account JSONを取得し、Git管理外の安全な場所に保存する。

Firebase CLIで利用者自身の対象プロジェクトを選択し、Firestore Rules / Indexes / Functionsをデプロイします。

```powershell
cd firebase
firebase login
firebase use --add
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions
cd ..
```

`firebase use --add` では、自分で作成したFirebase project IDを選択してください。既存開発者のproject IDを使う前提にはしません。

## 3. Androidアプリを起動してUIDを確認する

スマホをPCへ接続します。ワイヤレスデバッグの場合は、接続ポートが変わることがあるため毎回確認します。

```powershell
cd app
flutter devices
flutter build apk --debug
flutter install -d <device-id> --debug
cd ..
```

アプリ初回起動後、画面に表示されるUIDを確認します。このUIDをPCブリッジ設定の `ownerUserId` に使います。

## 4. PCブリッジを設定する

PCブリッジの依存関係を導入します。

```powershell
cd pc-bridge
npm.cmd install
npm.cmd run build
Copy-Item config.example.json config.local.json
```

pnpmを使う場合:

```powershell
cd pc-bridge
corepack enable
corepack pnpm --version
corepack pnpm install
corepack pnpm run build
corepack pnpm audit
Copy-Item config.example.json config.local.json
```

`config.local.json` に次を設定します。

- `ownerUserId`: Androidアプリで確認したUID。
- `pcBridgeId`: 通常は `home-main-pc`。
- `workspacePath`: Codexを実行するローカルワークスペース。
- `serviceAccountPath`: Firebase service account JSONの保存場所。
- `codexMode`: 実Codexを使う場合は `cli`。
- `codexCommandPath`: Codex CLIの起動コマンド。
- `codexModel`: 既定モデル。
- `pollIntervalSeconds`: queue確認間隔。
- `heartbeatIntervalSeconds`: heartbeat更新間隔。

設定後、リポジトリルートへ戻ります。

```powershell
cd ..
```

## 5. PCブリッジを常駐起動する

手動で動作確認する場合:

```powershell
cd pc-bridge
npm.cmd run start:watch
```

pnpmを使う場合:

```powershell
cd pc-bridge
corepack pnpm run start:watch
```

バックグラウンドで起動する場合:

```powershell
cd pc-bridge
.\scripts\start-watch-background.bat
```

ログオン時に自動起動する場合:

```powershell
cd pc-bridge
.\scripts\register-watch-task.bat
schtasks /Run /TN "CodexRemotePcBridge"
```

## 6. スマホから動作確認する

1. Androidアプリを起動する。
2. PCブリッジのheartbeatまたは手動ヘルスチェックが反応することを確認する。
3. New sessionを作成する。
4. モデルやCLIオプションを必要に応じて設定する。
5. セッションへ短い指示を送信する。
6. 状態が `queued -> running -> completed` へ進むことを確認する。
7. 結果またはエラーが表示されることを確認する。
8. 完了通知がスマホに届くことを確認する。

## 7. 困ったとき

- queueのまま進まない場合: PCブリッジが起動しているか、`ownerUserId` がアプリのUIDと一致しているか確認する。
- heartbeatが更新されない場合: `config.local.json` とFirebase service account JSONのパスを確認する。
- スマホが実機認識されない場合: `flutter devices` とAndroid側のワイヤレスデバッグ画面を確認する。
- 通知が届かない場合: Androidの通知権限、FCM token保存、Cloud Functionsのdeploy状態を確認する。
- npm auditやpnpm auditで脆弱性が出る場合: 監査結果を確認し、依存更新を別Issueで扱う。

詳細:

- [PCブリッジ手順](../pc-bridge/README.md)
- [Firebase手順](../firebase/README.md)
- [Cloud Functions手順](../firebase/functions/README.md)
- [Androidアプリ手順](../app/README.md)
- [開発環境セットアップ](development-setup.md)
