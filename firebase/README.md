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

画面例:

![Firebase Console home](../docs/assets/firebase-setup-screenshots/masked/01-console-home.png)

1. Firebase Consoleで `Create a Firebase project` を選択する。
2. プロジェクト名を入力する。

![Firebase project name](../docs/assets/firebase-setup-screenshots/masked/02-project-name.png)

3. Gemini in Firebaseを使う場合は有効化し、不要な場合は無効のまま進める。

![Firebase AI assistance](../docs/assets/firebase-setup-screenshots/masked/03-ai-assistance.png)

4. Google Analyticsを使う場合は有効化し、Analytics accountを選択してプロジェクトを作成する。

![Firebase Google Analytics](../docs/assets/firebase-setup-screenshots/masked/04-google-analytics.png)

![Firebase Analytics account](../docs/assets/firebase-setup-screenshots/masked/05-analytics-account.png)

5. 作成完了画面が表示されたら `Continue` を選択する。

![Firebase project ready](../docs/assets/firebase-setup-screenshots/masked/06-project-ready.png)

6. Firebase Consoleのプロジェクト画面が表示されることを確認する。

![Firebase project dashboard](../docs/assets/firebase-setup-screenshots/masked/07-project-dashboard.png)

作成後、次を有効化します。

1. Authentication
2. Firestore Database
3. Cloud Messaging
4. Cloud Functions

Cloud Functionsを使うため、Blazeプランへの変更とGoogle Cloud APIの有効化が必要です。初回デプロイ時にFirebase CLIが不足APIを案内する場合があります。

## 2. Authenticationを設定する

Firebase Consoleで次を設定します。

1. Authenticationを開く。

![Firebase Authentication get started](../docs/assets/firebase-setup-screenshots/masked/09-auth-get-started.png)

2. Sign-in methodを開く。

![Firebase sign-in method providers](../docs/assets/firebase-setup-screenshots/masked/10-auth-sign-in-method.png)

3. Anonymousを有効化する。

![Firebase enable anonymous auth](../docs/assets/firebase-setup-screenshots/masked/11-auth-enable-anonymous.png)

4. Sign-in providersの一覧でAnonymousがEnabledになっていることを確認する。

![Firebase anonymous auth enabled](../docs/assets/firebase-setup-screenshots/masked/12-auth-anonymous-enabled.png)

このアプリはMVPではFirebase Anonymous AuthのUIDをユーザーIDとして使います。

## 3. Firestoreを設定する

Firebase ConsoleでFirestore Databaseを作成します。

- mode: 本番モードを推奨。
- location: 利用者の地域に合わせて選択。

画面例:

1. Cloud Firestoreを開き、`Create database` を選択する。

![Firestore get started](../docs/assets/firebase-setup-screenshots/masked/14-firestore-get-started.png)

2. editionを選択する。通常は `Standard edition` を選択する。

![Firestore select edition](../docs/assets/firebase-setup-screenshots/masked/15-firestore-select-edition.png)

3. Database IDは既定の `(default)` のままにし、利用地域に近いlocationを選択する。

![Firestore location](../docs/assets/firebase-setup-screenshots/masked/16-firestore-location.png)

4. Security Rulesは `Start in production mode` を選択して作成する。

![Firestore security rules](../docs/assets/firebase-setup-screenshots/masked/17-firestore-security-rules.png)

5. 作成後、Database画面が表示されることを確認する。

![Firestore created](../docs/assets/firebase-setup-screenshots/masked/18-firestore-created.png)

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
- App nickname: `RemoteCodex`
- SHA-1: MVPのdebug installでは必須ではありません。Google Sign-In等を追加する場合に設定します。

画面例:

1. Project Overviewで `Add app` を選択する。

![Android app entry point](../docs/assets/firebase-setup-screenshots/masked/19-android-add-app-entry.png)

2. Androidアイコンを選択する。

![Android platform selection](../docs/assets/firebase-setup-screenshots/masked/20-android-platform-selection.png)

3. Android package nameとApp nicknameを入力し、`Register app` を選択する。

![Android register form](../docs/assets/firebase-setup-screenshots/masked/21-android-register-form.png)

4. `Download google-services.json` を選択して保存する。

![Download google-services.json](../docs/assets/firebase-setup-screenshots/masked/22-android-download-config.png)

5. 配布APK利用者は、この画面のSDK追加作業は実施しなくて構いません。確認後、次へ進みます。

![Android SDK instructions](../docs/assets/firebase-setup-screenshots/masked/23-android-sdk-instructions.png)

6. `Continue to console` を選択する。

![Android next steps](../docs/assets/firebase-setup-screenshots/masked/24-android-next-steps.png)

7. Project OverviewでAndroidアプリが登録済みになっていることを確認する。

![Android app registered](../docs/assets/firebase-setup-screenshots/masked/25-android-registration-complete.png)

登録後、`google-services.json` をダウンロードし、次の場所に配置します。

```text
app/android/app/google-services.json
```

このファイルはFirebase SDKがアプリ設定を読むために必要です。公開リポジトリに含める場合は、プロジェクト運用方針に合わせて扱ってください。service account JSONや秘密鍵とは別物ですが、公開したくない場合はGit管理外にしてください。

## 5. PCブリッジ用service account JSONを作成する

PCブリッジはFirebase Admin SDKでFirestoreとFirebase Storageへ接続します。利用者自身のFirebase/GCPプロジェクトでservice account keyを作成してください。

継続運用では、PCブリッジ専用service accountを作成し、Firestore read/write用の `roles/datastore.user` とStorage object read/write権限を付与する方針を推奨します。詳細は [Firebase service account permissions](../docs/firebase-service-account-permissions.md) を参照してください。

手順:

1. Google Cloud Consoleで対象Firebaseプロジェクトを開く。
2. IAMと管理 -> サービス アカウントを開く。
3. PCブリッジ用service accountを作成する、または既存のFirebase Admin SDK用service accountを使う。
4. JSON keyを作成してダウンロードする。
5. Git管理外の安全な場所に保存する。
6. `pc-bridge/config.local.json` の `serviceAccountPath` に保存場所を設定する。

Firebase ConsoleからFirebase Admin SDK用のprivate keyを作成する場合は、次の画面で操作します。

1. Project Overviewの歯車メニューから `Project settings` を開く。

![Service account project settings](../docs/assets/firebase-setup-screenshots/masked/26-service-account-project-settings.png)

2. `Service accounts` タブを開き、`Firebase Admin SDK` の `Generate new private key` を選択する。

![Firebase Admin SDK service account](../docs/assets/firebase-setup-screenshots/masked/27-service-account-admin-sdk.png)

3. 確認ダイアログで注意事項を確認し、`Generate key` を選択する。

![Generate private key dialog](../docs/assets/firebase-setup-screenshots/masked/28-service-account-generate-key-dialog.png)

4. JSONファイルをPCローカルの安全な場所に保存する。

![Save service account JSON](../docs/assets/firebase-setup-screenshots/masked/29-service-account-save-json.png)

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
