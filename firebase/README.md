# Firebase

このディレクトリには、利用者自身のFirebaseプロジェクトへデプロイするクラウドリレー構成を配置しています。

## 利用するFirebase機能

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Cloud Functions
- Firebase Emulator Suite

## 1. Firebaseプロジェクトを作成する

Firebase Consoleで新しいプロジェクトを作成します。プロジェクト名とproject IDは利用者が自由に決めて構いません。

作成後、次を有効化します。

1. Authentication
2. Firestore Database
3. Cloud Messaging
4. Cloud Functions

Cloud Functionsを使うため、Blazeプランへの変更とGoogle Cloud APIの有効化が必要です。初回デプロイ時にFirebase CLIが不足APIを案内する場合があります。

## 2. Authenticationを設定する

Firebase Consoleで次を設定します。

1. Authenticationを開く。
2. Sign-in methodを開く。
3. Anonymousを有効化する。

このアプリはMVPではFirebase Anonymous AuthのUIDをユーザーIDとして使います。

## 3. Firestoreを設定する

Firebase ConsoleでFirestore Databaseを作成します。

- mode: 本番モードを推奨。
- location: 利用者の地域に合わせて選択。

Firestore Security RulesとIndexesは、このディレクトリのファイルをFirebase CLIからデプロイします。

```powershell
cd firebase
firebase login
firebase use --add
firebase deploy --only firestore:rules,firestore:indexes
cd ..
```

`firebase use --add` では、利用者自身が作成したFirebase project IDを選択してください。

## 4. Androidアプリを登録する

Firebase ConsoleでAndroidアプリを追加します。

- Android package name: `com.sunmax.remotecodex`
- App nickname: 任意。
- SHA-1: MVPのdebug installでは必須ではありません。Google Sign-In等を追加する場合に設定します。

登録後、`google-services.json` をダウンロードし、次の場所に配置します。

```text
app/android/app/google-services.json
```

このファイルはFirebase SDKがアプリ設定を読むために必要です。公開リポジトリに含める場合は、プロジェクト運用方針に合わせて扱ってください。service account JSONや秘密鍵とは別物ですが、公開したくない場合はGit管理外にしてください。

## 5. PCブリッジ用service account JSONを作成する

PCブリッジはFirebase Admin SDKでFirestoreへ接続します。利用者自身のFirebase/GCPプロジェクトでservice account keyを作成してください。

手順:

1. Google Cloud Consoleで対象Firebaseプロジェクトを開く。
2. IAMと管理 -> サービス アカウントを開く。
3. PCブリッジ用service accountを作成する、または既存のFirebase Admin SDK用service accountを使う。
4. JSON keyを作成してダウンロードする。
5. Git管理外の安全な場所に保存する。
6. `pc-bridge/config.local.json` の `serviceAccountPath` に保存場所を設定する。

注意:

- service account JSONは絶対にGitへコミットしないでください。
- 公開IssueやログにJSON全文を貼らないでください。
- 可能であれば、このアプリ専用のFirebaseプロジェクトを用意してください。

## 6. Cloud Functionsをデプロイする

完了通知を送信するため、Cloud Functionsをデプロイします。

```powershell
cd firebase
firebase use
firebase deploy --only functions
cd ..
```

初回デプロイ時には、Cloud Functions / Cloud Build / Artifact Registry / Cloud Run / Eventarc / Pub/Sub / Compute Engine APIなどの有効化が必要になる場合があります。Firebase CLIの案内に従って有効化してください。

Functionsの詳細は [Cloud Functions手順](functions/README.md) を参照してください。

## 7. デプロイ後に確認する

Firebase Consoleで次を確認します。

- Authenticationに匿名ユーザーが作成される。
- Firestoreに `users/{uid}` 配下のdocumentが作成される。
- `devices/android-app` にFCM tokenが保存される。
- `pcBridges/home-main-pc` にPCブリッジのheartbeatが保存される。
- セッション作成後、`sessions/{sessionId}` と `commands/{commandId}` が作成される。
- コマンド完了後、Cloud Functionsが通知送信を実行する。

## ファイル

- `firebase.json`: EmulatorとFirestore/Functions設定。
- `firestore.rules`: MVP Security Rules。
- `firestore.indexes.json`: Firestore command query index。
- `.firebaserc`: 利用者環境では `firebase use --add` により作成または更新されるローカルproject alias。
- `functions/`: 通知Cloud Functionsの配置先。
