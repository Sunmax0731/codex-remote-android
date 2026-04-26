# Codex Remote Android

Androidスマホから自宅PC上のCodexへ指示を送り、PC側で処理した結果をスマホで確認するためのFlutter AndroidアプリとPCブリッジです。

## 概要

Codex Remote Androidは、外出先や別室からスマホでCodex作業を開始し、自宅PC側で処理を進めるためのリモート操作基盤です。スマホとPCはFirebaseを介して通信するため、自宅ルーターのポート開放なしでWiFiと携帯電話回線の両方から利用できます。

```text
Android app -> Firebase Auth / Firestore -> PC bridge -> Codex CLI
Android app <- Firestore result/progress <- PC bridge <- Codex CLI
Android app <- Firebase Cloud Messaging completion notification
```

## 目的

- AndroidスマホからCodexセッションを作成または選択できるようにする。
- スマホから送信した指示を、自宅PC上の固定ワークスペースでCodexに処理させる。
- 処理中の状態、進捗概要、完了結果、失敗理由をスマホで確認できるようにする。
- 完了時にスマホへプッシュ通知を送る。
- PCとスマホの直接接続に依存せず、WiFiと携帯電話回線の両方で使える構成にする。

## 主な機能

- Firebase Anonymous Authによるスマホ側ユーザー識別。
- セッション作成、セッション一覧、既存セッション選択。
- セッションごとのCodex CLIオプション指定。
- CLI既定値の保存。
- `gpt-5.5`、`gpt-5.4` などのモデル選択。
- `--config`、`--enable`、`--disable`、`--image`、`--add-dir` などの詳細CLIオプション入力。
- 画像ファイルブラウザによる `--image` ファイル選択。
- 設定項目ごとのヘルプ表示。
- PCブリッジのheartbeat、queue確認時刻、手動ヘルスチェック時刻の表示。
- スマホ操作によるPCブリッジ稼働確認リクエスト。
- queued / running / completed / failed の状態表示。
- running中の経過時間と1分ごとの進捗概要表示。
- 最終結果またはエラー表示。
- Firebase Cloud Messagingによる完了通知。
- 通知タップから対象セッションへの遷移。
- 日本語、英語、中国語、韓国語の端末言語追従。
- 未対応言語の英語フォールバック。
- Xperia 1 IIIでの実機確認を前提にしたAndroid debug APKインストール。
- Windows用PCブリッジ常駐起動バッチとタスクスケジューラ登録。

## 環境構築

### PC

対象PCはWindows環境を想定しています。

必要なもの:

- Windows PC
- VS Code
- Codex CLI
- Node.js / npm
- pnpm
- Flutter SDK
- Android SDK platform-tools
- Firebase CLI
- Git / GitHub CLI

確認コマンド例:

```powershell
node --version
npm.cmd --version
corepack --version
corepack pnpm --version
flutter doctor
firebase --version
gh --version
adb devices
```

PCブリッジの初期セットアップ:

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

pnpmは依存解決とlockfileをnpmとは別に管理できますが、脆弱性警告が必ず解消するわけではありません。`corepack pnpm audit` の結果を確認し、必要に応じて依存更新を別Issueで扱ってください。環境によって `pnpm.cmd` が使える場合は、`corepack pnpm` を `pnpm.cmd` に置き換えても構いません。

`pc-bridge/config.local.json` にFirebase service account JSONのパス、対象UID、固定ワークスペース、Codex CLI設定を記入します。`config.local.json` とservice account JSONはGitに含めません。

常駐起動:

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

詳細は [PCブリッジ手順](pc-bridge/README.md) を参照してください。

### Androidスマホ

主ターゲットはXperia 1 IIIです。Android 13のXperia 1 IIIでワイヤレスデバッグを使った実機確認を行っています。

必要なもの:

- Androidスマホ
- 開発者向けオプション
- ワイヤレスデバッグまたはUSBデバッグ
- Firebaseプロジェクトに登録したAndroidアプリ設定
- `app/android/app/google-services.json`

ワイヤレスデバッグ確認:

```powershell
flutter devices
```

debug APKのビルドとインストール:

```powershell
cd app
flutter build apk --debug
flutter install -d <device-id> --debug
```

`<device-id>` は `flutter devices` で表示された現在の値を使います。ワイヤレスデバッグのポートは変わるため、固定値として扱わないでください。

詳細は [開発環境セットアップ](docs/development-setup.md) を参照してください。

### クラウドサービス

Firebaseをクラウドリレーとして使います。

利用機能:

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Cloud Functions
- Firebase Emulator Suite

利用者自身のFirebaseプロジェクトを作成し、このリポジトリの `firebase/` 構成をデプロイして使います。Firestore Rules、Indexes、Cloud Functionsをデプロイする場合は次を実行します。

```powershell
cd firebase
firebase login
firebase use --add
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions
```

`firebase use --add` では、利用者自身が用意したFirebase project IDを選択します。Cloud Functionsの初回デプロイにはBlazeプランとGoogle Cloud APIの有効化が必要です。詳細は [Firebase手順](firebase/README.md) と [Cloud Functions手順](firebase/functions/README.md) を参照してください。

## 利用開始手順

このアプリを使い始めるための準備は、[利用開始手順](docs/getting-started.md) を参照してください。自分以外の利用者へ配布するための準備は、[配布準備](docs/distribution-prep.md) を参照してください。

関連する詳細手順:

- [PCブリッジ手順](pc-bridge/README.md)
- [Firebase手順](firebase/README.md)
- [Cloud Functions手順](firebase/functions/README.md)
- [Androidアプリ手順](app/README.md)
- [配布準備](docs/distribution-prep.md)
- [利用者向けクイックスタート](docs/user-quickstart.md)
- [配布利用者向けトラブルシュート](docs/troubleshooting-distribution.md)

## ライセンス

このプロジェクトはMIT Licenseで公開します。詳細は [LICENSE](LICENSE) を参照してください。

## プライバシーポリシー

このアプリは、Codexへの指示、処理状態、進捗概要、最終結果、通知に必要な端末情報をFirebaseに保存します。通知payloadには完了状態とセッション識別情報を含め、ロック画面に表示される可能性がある通知本文には結果またはエラーの短い要約が含まれる場合があります。

保存する主な情報:

- Firebase AuthenticationのUID
- FCM token
- セッション情報
- コマンド本文
- コマンド状態
- 進捗概要
- 最終結果またはエラー
- PCブリッジのheartbeatと稼働確認時刻

保存しない方針の情報:

- Firebase service account JSON
- Android署名鍵
- PCブリッジのローカル設定ファイル
- CodexやGitHubなど外部サービスの認証token

詳細は [プライバシーポリシー](PRIVACY.md) を参照してください。

## サポート体制

不具合報告、機能追加要望、その他質問はGitHub Issueで受け付けます。投稿時は目的に合うIssueテンプレートを選択してください。

- 不具合報告: アプリやPCブリッジが想定通り動かない場合。
- 機能追加要望: 新しい機能、改善、対応端末や対応サービスの追加を希望する場合。
- 質問: セットアップ、運用、仕様、使い方について確認したい場合。

Issue投稿時のテンプレート:

- [不具合報告テンプレート](.github/ISSUE_TEMPLATE/bug_report.md)
- [機能追加要望テンプレート](.github/ISSUE_TEMPLATE/feature_request.md)
- [質問テンプレート](.github/ISSUE_TEMPLATE/question.md)

Issueには、再現手順、期待する動作、実際の動作、実行環境、関連ログを可能な範囲で記載してください。秘密情報、token、service account JSON、個人情報、非公開コード全文は投稿しないでください。
