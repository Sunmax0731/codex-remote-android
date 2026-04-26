# 配布準備

この文書は、Codex Remote Android を自分以外の利用者にも使ってもらうために準備するものをまとめる。

## 配布方針

配布APKの Android package 名とアプリ名は固定値として扱う。

- アプリ名: `RemoteCodex`
- Android package 名: `com.sunmax.remotecodex`

利用者がFirebase ConsoleでAndroidアプリを登録するときも、package名は必ず `com.sunmax.remotecodex` を使う。任意のpackage名を使うと、配布APKと `google-services.json` のAndroid clientが一致せず、QR生成やFirebase接続に失敗する。

## 配布物

利用者へ渡す、または利用者が入手できる状態にするものは次の通り。

- Android APK
- PCブリッジ一式
- PCセットアップWeb UI
- Firebase構成ファイル
  - `firebase/firestore.rules`
  - `firebase/firestore.indexes.json`
  - `firebase/functions/`
- セットアップ手順書
- トラブルシュート手順
- リリースノート

## 利用者が用意するもの

利用者ごとに必要なものは次の通り。

- Windows PC
- Android端末
- Node.js / npm
- Codex CLI
- Firebase CLI
- Firebaseプロジェクト
- Firebase Androidアプリ登録
  - package名: `com.sunmax.remotecodex`
- `google-services.json`
- PCブリッジ用 service account JSON
- PCブリッジの `config.local.json`

`service account JSON` はPCローカルだけで管理する。Androidアプリ、QRコード、GitHub Issue、ログ、スクリーンショットに含めない。

## 初回セットアップの流れ

1. Firebase Consoleで利用者自身のFirebaseプロジェクトを作成する。
2. AuthenticationでAnonymous sign-inを有効化する。
3. Firestore Databaseを作成する。
4. Androidアプリを登録する。
   - package名: `com.sunmax.remotecodex`
   - アプリのニックネームは任意
5. `google-services.json` をダウンロードする。
6. PCセットアップWeb UIを開き、`google-services.json` からAndroidセットアップQRを生成する。
7. AndroidアプリでセットアップQRを読み取る。
8. PCブリッジ用 service account JSON を作成し、PCローカルの安全な場所に保存する。
9. `pc-bridge/config.local.json` を作成し、Firebase project ID、service account JSONのパス、Codex CLI、ワークスペースを設定する。
10. Firestore Rules / Indexes / Functionsをデプロイする。
11. PCブリッジを起動する。
12. AndroidアプリからPC接続確認とテストセッションを実行する。

## PCセットアップWeb UI

PCセットアップWeb UIは、利用者がFirebase設定をスマホへ手入力しなくて済むようにするための補助画面である。

表示する固定値:

- アプリ名: `RemoteCodex`
- Android package名: `com.sunmax.remotecodex`

QR生成に使うもの:

- `google-services.json`
- 固定package名 `com.sunmax.remotecodex`

QRに含めてよいもの:

- `projectId`
- `apiKey`
- `appId`
- `messagingSenderId`
- `storageBucket`

QRに含めてはいけないもの:

- service account JSON
- private key
- Admin SDK credential
- PCブリッジのローカル設定
- Codex / GitHub / OpenAI など外部サービスの認証token

## PCブリッジ設定

利用者は `pc-bridge/config.example.json` をコピーして `config.local.json` を作る。

主な設定項目:

- `relayMode`: 本番利用では `firestore`
- `firebaseProjectId`: 利用者自身のFirebase project ID
- `serviceAccountPath`: service account JSONのローカルパス
- `pcBridgeId`: 通常は `home-main-pc`
- `workspacePath`: Codexを実行するPC上の作業ディレクトリ
- `codexMode`: Codex CLIを使う場合は `cli`
- `codexCommandPath`: 例 `codex.cmd`
- `codexModel`: 既定モデル
- `pollIntervalSeconds`: queue確認間隔
- `heartbeatIntervalSeconds`: heartbeat更新間隔

`config.local.json` と service account JSON はGitに含めない。

## 動作確認

配布前または利用者環境で、最低限次を確認する。

- AndroidアプリでFirebase setup QRを読み取れる。
- Androidアプリが匿名認証できる。
- Firestoreに `users/{uid}` が作成される。
- PCブリッジがheartbeatを書き込む。
- AndroidアプリでPC接続情報が表示される。
- Androidアプリからセッションを作成できる。
- PCブリッジが `queued` commandを取得し、Codex CLIへ渡せる。
- `running`、`completed`、`failed` の状態がAndroidアプリに反映される。
- 完了通知が届く。

## 配布前チェックリスト

- release APKまたは内部配布用APKを作成している。
- APKのバージョン番号とリリースノートを用意している。
- package名が `com.sunmax.remotecodex` のままである。
- PCブリッジの起動手順を利用者向けに説明している。
- Firebaseセットアップ手順を利用者向けに説明している。
- service account JSONをQRやドキュメントに含めないことを明記している。
- トラブルシュートを用意している。
- debug用途の説明と配布用途の説明を分けている。

## 既知の未整備項目

配布を広げる前に、次の作業をIssueとして管理する。

- #124 release APK作成手順と署名方針を整備する
- #125 利用者向けクイックスタートを整備する
- #126 PCブリッジ配布パッケージを整備する
- #127 Firebaseセットアップ手順にスクリーンショットを追加する
- #128 配布利用者向けトラブルシュート集を整備する
- #129 配布前セキュリティレビューを実施する

配布前セキュリティレビューの結果は [配布前セキュリティレビュー](security-review-distribution.md) に記録する。

release APK作成手順と署名方針は [release APK作成手順](release-apk.md) に記録する。
