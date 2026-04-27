# 配布利用者向けトラブルシュート

この文書は、配布APKとPCブリッジzipを使う利用者向けの切り分け手順である。

## 共有してはいけない情報

問い合わせやIssue投稿時に、次は貼らない。

- service account JSON
- private key
- `config.local.json`
- Firebase debug log全文
- PCブリッジログ全文
- FCM token
- Codex / GitHub / OpenAI など外部サービスのtoken
- 署名鍵
- `key.properties`

ログを共有する場合は、project ID、UID、メールアドレス、token、ローカルパスをマスクする。

## まず確認すること

1. Android package名が `com.sunmax.remotecodex` でFirebaseに登録されている。
2. AndroidアプリでFirebase setup QRを保存している。
3. Firebase AuthenticationのAnonymous sign-inが有効である。
4. Firestore Databaseが作成済みである。
5. Firestore Rules / Indexesがデプロイ済みである。
6. PCブリッジの `config.local.json` で `relayMode` が `firestore` である。
7. `serviceAccountPath` のJSONファイルがPC上に存在する。
8. PCブリッジが起動している。
9. Codex CLIがPC上で実行できる。

## QRが読み取れない

確認項目:

- PCセットアップWeb UIを開き直す。
- `google-services.json` を再度読み込む。
- QRを画面に大きく表示する。
- スマホのカメラ権限を許可する。
- Androidアプリの `Scan setup QR` から読み取っているか確認する。

それでも読めない場合:

- `google-services.json` が対象Firebaseプロジェクトのものか確認する。
- Firebase Androidアプリのpackage名が `com.sunmax.remotecodex` か確認する。
- ブラウザのズームやディスプレイ拡大率を変更して再生成する。

## QR保存後にFirebase接続できない

確認項目:

- `projectId` が利用者自身のFirebase project IDになっている。
- `apiKey`、`appId`、`messagingSenderId` が空ではない。
- Android端末がインターネットへ接続できる。
- Firebase AuthenticationでAnonymousが有効になっている。
- Firestore Databaseが作成済みである。

確認方法:

- Androidアプリの接続設定画面で保存済みproject IDを確認する。
- Firebase ConsoleのAuthenticationで匿名ユーザーが作成されているか確認する。
- Firestoreに `users/{uid}` が作成されているか確認する。

## PC接続情報が更新されない

症状:

- AndroidアプリのPC接続情報でheartbeatが古い。
- `Check PC now` に反応しない。

PC側確認:

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -match 'dist[\\/]+src[\\/]+watch.js|start:watch|run-watch.bat' } |
  Select-Object ProcessId,Name,CommandLine
```

ログ確認:

```powershell
Get-ChildItem .\logs -Filter 'pc-bridge-watch-*.log' |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1 |
  ForEach-Object { Get-Content $_.FullName -Tail 80 }
```

設定確認:

- `relayMode` が `firestore`
- `firebaseProjectId` が正しい
- `serviceAccountPath` が存在する
- service account JSONが対象Firebaseプロジェクトのもの
- `pcBridgeId` がAndroidアプリ側の対象PCと一致する

## セッションがqueuedのまま進まない

原因候補:

- PCブリッジが起動していない。
- PCブリッジが別Firebaseプロジェクトを見ている。
- `pcBridgeId` が一致していない。
- Firestore Rules / Indexesが未デプロイ。
- service account JSONが無効。

確認項目:

1. PCブリッジログに `No queued command found` または `Processed command` が出ているか確認する。
2. Firestoreで `users/{uid}/sessions/{sessionId}/commands/{commandId}` の `status` を確認する。
3. commandの `targetPcBridgeId` と `config.local.json` の `pcBridgeId` を比較する。
4. `firebaseProjectId` とAndroidアプリのproject IDが一致しているか確認する。

## runningのまま終わらない

原因候補:

- Codex CLIが処理中。
- Codex CLIが入力待ちになっている。
- `codexTimeoutSeconds` が長い。
- PCブリッジプロセスが途中で落ちた。

確認項目:

- PCブリッジログを確認する。
- Codex CLIをPC上で直接実行できるか確認する。
- `codexCommandPath` が正しいか確認する。
- `workspacePath` が存在するか確認する。
- `codexTimeoutSeconds` を確認する。

## Codex CLIが見つからない

PC上で確認する。

```powershell
codex.cmd --version
codex.cmd exec --help
```

失敗する場合:

- Codex CLIをインストールする。
- `codexCommandPath` に絶対パスまたは `codex.cmd` を設定する。
- タスクスケジューラ起動時にPATHが足りない場合は絶対パスを使う。

## failedになる

確認項目:

- Androidアプリのエラー表示を確認する。
- Firestoreのcommand documentの `errorText` を確認する。
- PCブリッジログを確認する。
- `workspacePath` が存在し、Codex CLIがアクセスできるか確認する。
- モデル名がCodex CLIで利用可能か確認する。
- `codexBypassSandbox` を有効にする必要がある操作か確認する。

注意:

`errorText` にはredactionが入るが、ログやFirestoreを共有する前には必ず秘密情報が含まれていないか確認する。

## 添付uploadが失敗する

確認項目:

- AndroidのFirebase setup QRに `storageBucket` が含まれている。
- Firebase Storageが作成済みで、Storage Rulesが反映されている。
- 添付は5件以内、1 fileあたり25 MiB以内。
- 許可MIME typeは `image/png`, `image/jpeg`, `image/webp`, `image/gif`, `text/plain`, `text/markdown`, `application/json`, `application/pdf`, `application/x-yaml`。
- executable、script、archiveは初期実装では送信しない。
- Firestoreのcommand metadataに `attachments` が保存されていない場合、Android側の選択・upload・Rules拒否を確認する。

## 添付downloadまたはCodex CLI連携が失敗する

確認項目:

- `pc-bridge/config.local.json` に `firebaseStorageBucket` が設定されている。
- PCブリッジ用service accountに `roles/datastore.user` と `roles/storage.objectViewer` が付与されている。
- `attachmentCachePath` がPC上で作成可能な場所になっている。
- PCブリッジlogに `Attachment size is invalid`, `Attachment downloaded hash mismatch`, `Attachment storage path is invalid` などが出ていないか確認する。
- `type=image` はCodex CLIへ `--image` として渡される。Codex CLIが画像入力を受け付けるversionか確認する。
- `type=file` はdownload先directoryを `--add-dir` に渡し、promptへlocal pathを追記する。対象fileがcommand完了前に削除されていないか確認する。
- command完了後は `.local/attachments/{userId}/{sessionId}/{commandId}/` がcleanupされる。調査時はwatcher logとcommand IDで追跡する。

## 通知が届かない

確認項目:

- Androidで通知権限を許可している。
- Android端末がインターネットへ接続できる。
- Firebase Cloud Messagingが利用可能。
- `firebase deploy --only functions` が成功している。
- Firestoreの `users/{uid}/devices/android-app` にFCM tokenが保存されている。
- command documentに `notificationSentAt`、`notificationSuccessCount`、`notificationFailureCount` が記録されている。

Functionsログを確認する。

```powershell
cd firebase
firebase functions:log
```

## PCブリッジが起動しない

確認項目:

- Node.js 22以上が入っている。
- `npm.cmd install` が完了している。
- `npm.cmd run build` が成功する。
- `config.local.json` が存在する。
- JSON構文が正しい。

チェック:

```powershell
node --version
npm.cmd --version
npm.cmd run check
npm.cmd run build
```

## service account JSONのエラー

service account JSONを誤って共有した、または漏えいした可能性がある場合は、先に [Credential incident runbook](credential-incident-runbook.md) に従ってkeyを無効化・再発行する。

確認項目:

- `serviceAccountPath` のパスが正しい。
- JSONファイルが削除または移動されていない。
- 対象Firebase/GCPプロジェクトのservice accountである。
- private keyを含むJSON keyである。
- JSON全文をIssueやチャットに貼っていない。

## Firestore Rules / Indexesのエラー

再デプロイする。

```powershell
cd firebase
firebase use
firebase deploy --only firestore:rules,firestore:indexes
```

Firestoreのindex作成直後は反映に時間がかかることがある。

## 問い合わせ時に共有してよい情報

共有してよいもの:

- アプリversion
- Android機種とAndroid version
- PCのOS
- Node.js version
- Codex CLI version
- Firebase project IDの一部をマスクしたもの
- 画面のエラーメッセージ
- マスク済みログの該当部分
- `pcBridgeId`
- command status

共有前にマスクするもの:

- UID
- ローカルパス
- project ID
- メールアドレス
- token
- service account情報
