# Firebase

このディレクトリはFirebaseリレー構成の配置先。

MVPで使うFirebase機能:

- Firebase Auth
- Cloud Firestore
- Firebase Cloud Messaging
- Cloud Functions
- Firebase Emulator Suite

Firebase CLIは導入済みで、Firebase project `remotecodex-c52ae` に紐づけ済み。
Firestore rules / indexes はデプロイ済みで、Phase 6ではFunctionsの実装とデプロイを進める。
Cloud Functions のデプロイには Blaze plan が必要なため、`remotecodex-c52ae` のプラン更新後にデプロイする。

Firebase設定を更新した場合は、次を実行して対象projectを確認する。

```powershell
firebase use
firebase deploy --only firestore:rules,firestore:indexes
```

## ファイル

- `firebase.json`: EmulatorとFirestore/Functions設定。
- `firestore.rules`: MVP Security Rules。
- `firestore.indexes.json`: Firestore command query index。
- `functions/`: 通知Cloud Functionsの配置先。

