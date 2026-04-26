# Firebase

このディレクトリはFirebaseリレー構成の配置先。

MVPで使うFirebase機能:

- Firebase Auth
- Cloud Firestore
- Firebase Cloud Messaging
- Cloud Functions
- Firebase Emulator Suite

Phase 3時点ではFirebase CLIがPATH上にないため、実際の `firebase init` は未実施。

Firebase CLI導入後、Phase 3またはPhase 6で次を実施する。

```powershell
firebase login
firebase init firestore functions emulators
```

## ファイル

- `firebase.json`: EmulatorとFirestore/Functions設定の初期案。
- `firestore.rules`: MVP Security Rulesの初期雛形。
- `firestore.indexes.json`: Firestore indexesの初期雛形。
- `functions/`: 通知Cloud Functionsの配置先。

