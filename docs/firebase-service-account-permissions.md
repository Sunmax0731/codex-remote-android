# Firebase service account permissions

この文書は、PCブリッジとFirebase Functionsで使うcredentialを分け、service account keyの権限を広げすぎないための方針をまとめる。

## 結論

MVPでは、PCブリッジ用に専用service accountを作成し、Firestore read/writeに必要な `roles/datastore.user` を付与する運用を推奨する。

Firebase Consoleの `Firebase Admin SDK` 画面から生成する既定service account keyは手順が簡単だが、Firebase project全体へ強い権限を持つ場合がある。継続運用では、PCブリッジ専用service accountを作り、Owner / Editor / Firebase Admin相当の広いロールを避ける。

## 権限の棚卸し

### Androidアプリ

AndroidアプリはFirebase client SDKだけを使う。service account JSON、Admin SDK credential、private keyは保存しない。

### PCブリッジ

PCブリッジは `pc-bridge/config.local.json` の `serviceAccountPath` で指定したservice account JSONを使い、Firebase Admin SDKでFirestoreへ接続する。

実装上必要な操作:

- `users/{uid}/sessions/{sessionId}` のread/update
- `users/{uid}/sessions/{sessionId}/commands/{commandId}` のread/update
- `collectionGroup("commands")` query
- `users/{uid}/pcBridges/{pcBridgeId}` のset/update
- `users/{uid}/pcBridges/{pcBridgeId}/healthChecks/{healthCheckId}` のread/update
- Firestore transaction

PCブリッジはFCM送信、Firebase Auth管理、Cloud Functions deploy、IAM変更を行わない。

推奨:

- 専用service accountを作る。
- project levelで `roles/datastore.user` を付与する。
- Owner、Editor、Firebase Admin、Service Account Admin、Service Account Token Creatorを付与しない。
- 同じservice account keyをFunctions deployや別アプリに使い回さない。

Firestore IAMはcollection単位の細かい制御には向かない。Admin SDKはFirestore Security Rulesを迂回するため、PCブリッジ用keyが漏えいすると、少なくともそのproject内FirestoreへIAM権限の範囲でアクセスできる。必要なら利用者自身の専用Firebase projectを分ける。

### Firebase Functions

Functions側はFirebase/Google Cloud上の実行環境でAdmin SDKを初期化する。PCブリッジ用service account JSONをFunctionsへ渡さない。

Functionsの役割:

- Firestore triggerでcommand完了を検知する。
- 対象userのdevice tokenをFirestoreから読む。
- FCMで完了通知を送る。
- command documentへnotification結果を書き戻す。

MVPではFirebase CLIの標準deployと既定runtime service accountを使う。Functions runtime service accountを手動で最小化する場合は、Firestore read/writeとFCM送信に必要なpermissionを満たす必要があり、初期設定が複雑になるため上級運用として扱う。

## 推奨作成手順

Google Cloud CLIを使う場合の例:

```powershell
$projectId = "<firebase-project-id>"
$serviceAccountName = "codex-remote-pc-bridge"
$serviceAccountEmail = "$serviceAccountName@$projectId.iam.gserviceaccount.com"

gcloud iam service-accounts create $serviceAccountName `
  --project $projectId `
  --display-name "Codex Remote PC Bridge"

gcloud projects add-iam-policy-binding $projectId `
  --member "serviceAccount:$serviceAccountEmail" `
  --role "roles/datastore.user"

gcloud iam service-accounts keys create "D:\secure\codex-remote-pc-bridge.json" `
  --iam-account $serviceAccountEmail `
  --project $projectId
```

作成したJSON pathを `pc-bridge/config.local.json` に設定する。

```json
{
  "firebaseProjectId": "<firebase-project-id>",
  "serviceAccountPath": "D:\\secure\\codex-remote-pc-bridge.json"
}
```

## 既定Firebase Admin SDK keyを使う場合

初期セットアップを優先し、Firebase Consoleの `Generate new private key` を使う場合は、次を必ず守る。

- service account JSONをGitへ含めない。
- `config.local.json` へはpathだけを書く。
- keyを共有しない。
- Release後に専用service account + `roles/datastore.user` へ移行する。
- 不要なkeyは削除する。

この選択は、初期設定を簡単にする代わりにkey漏えい時の影響範囲が広くなる。Public repository運用では長期利用しない。

## 定期運用

- 月1回、Google Cloud IAMでPCブリッジ用service accountに不要なロールが付いていないか確認する。
- 使っていないservice account keyを削除する。
- keyを再発行した場合は、古いkeyを削除し、`config.local.json` のpathを更新する。
- `npm.cmd run diagnose` でPCブリッジのFirestore接続を確認する。
- 誤公開や漏えいが疑われる場合は [Credential incident runbook](credential-incident-runbook.md) に従う。

## 参照

- Google Cloud: [Firestore roles and permissions](https://docs.cloud.google.com/iam/docs/roles-permissions/firestore)
- Google Cloud: [Identity and Access Management for Firestore in Datastore mode](https://cloud.google.com/datastore/docs/access/iam)
- Firebase: [Overview of Firebase-related service accounts](https://firebase.google.com/support/guides/service-accounts)
- Firebase: [Add the Firebase Admin SDK to your server](https://firebase.google.com/docs/admin/setup)
- Firebase: [Firebase IAM permissions](https://firebase.google.com/docs/projects/iam/permissions)
