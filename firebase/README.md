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
Cloud Functions のデプロイには Blaze plan と、初回デプロイ時に要求されるGoogle Cloud APIの有効化が必要。
`remotecodex-c52ae` はBlaze planへ更新済みだが、現時点ではCompute Engine APIが無効なためFunctions upload bucketの作成で停止している。

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

