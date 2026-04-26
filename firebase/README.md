# Firebase

このディレクトリはFirebaseリレー構成の配置先。

MVPで使うFirebase機能:

- Firebase Auth
- Cloud Firestore
- Firebase Cloud Messaging
- Cloud Functions
- Firebase Emulator Suite

Firebase CLIは導入済みで、Firebase project `remotecodex-c52ae` に紐づけ済み。
Firestore rules / indexes はデプロイ済み。
Cloud Functions の `notifyCommandCompletion` は `asia-northeast1` にデプロイ済み。
Blaze plan と初回デプロイ時に要求されるGoogle Cloud APIは有効化済み。

Firebase設定を更新した場合は、次を実行して対象projectを確認する。

```powershell
firebase use
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions
```

## ファイル

- `firebase.json`: EmulatorとFirestore/Functions設定。
- `firestore.rules`: MVP Security Rules。
- `firestore.indexes.json`: Firestore command query index。
- `functions/`: 通知Cloud Functionsの配置先。

