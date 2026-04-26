# アーキテクチャ

## 目的

この文書は、Androidアプリから自宅PC上のCodexへ指示を送り、PC側で処理した最終結果をAndroidアプリへ返すためのMVPアーキテクチャを定義する。

MVPでは、WiFiと携帯回線の両方で利用できることを優先し、Androidアプリから自宅PCへ直接接続しない。AndroidアプリとPCブリッジは、どちらもFirebaseへアウトバウンド接続する。

## システム構成

MVPは次の3要素で構成する。

- Androidアプリ: セッション一覧、セッション作成、指示入力、最終結果表示、通知タップ時の遷移を担当する。
- Firebaseリレー: 認証、セッション/コマンド保存、PCブリッジ登録、通知トリガーを担当する。
- PCブリッジ: Firebase上の待機中コマンドを監視し、自宅PC上のCodexワークフローへ渡し、最終結果をFirebaseへ書き戻す。

```text
Android app
  -> Firebase Auth
  -> Cloud Firestore
  -> Firebase Cloud Messaging

PC bridge
  -> Cloud Firestore
  -> local VS Code / Codex workflow
```

## MVP通信フロー

1. AndroidアプリがFirebase上でユーザーまたはデバイスとして認証される。
2. Androidアプリがセッションを作成または選択する。
3. Androidアプリが選択中セッションへコマンドを作成する。
4. コマンド状態は `queued` になる。
5. PCブリッジが自分に紐づく `queued` コマンドを検出する。
6. PCブリッジがコマンドをclaimし、状態を `running` にする。
7. PCブリッジが固定ワークスペース上のCodexワークフローへ指示テキストを渡す。
8. PCブリッジが最終結果またはエラーをFirestoreへ書き戻す。
9. コマンド状態が `completed` または `failed` になる。
10. Firebase Cloud Functionsが完了通知をFCMでAndroid端末へ送信する。
11. Androidアプリは通知タップまたは画面更新で最終結果を表示する。

## Firebaseリレー方針

MVPではFirebaseをクラウドリレーとして使う。

- AndroidアプリとPCブリッジはどちらもFirebaseへアウトバウンド接続する。
- 自宅ルーターのポート開放は不要にする。
- 携帯回線からも同じ経路で利用できる。
- セッション、コマンド、結果はFirestoreに保存する。
- 完了通知はFirebase Cloud Messagingで送信する。

## Firestoreデータモデル

MVPのFirestore構成は、単一ユーザー・単一主PCを前提にしつつ、後から複数PCへ拡張できる形にする。

```text
users/{userId}
users/{userId}/devices/{deviceId}
users/{userId}/pcBridges/{pcBridgeId}
users/{userId}/sessions/{sessionId}
users/{userId}/sessions/{sessionId}/commands/{commandId}
```

### `users/{userId}`

ユーザー単位のルートドキュメント。

想定フィールド:

- `createdAt`
- `updatedAt`
- `displayName`
- `primaryPcBridgeId`

### `devices/{deviceId}`

Android端末を表す。

想定フィールド:

- `displayName`
- `platform`: `android`
- `fcmToken`
- `fcmTokenUpdatedAt`
- `createdAt`
- `lastSeenAt`
- `notificationEnabled`

### `pcBridges/{pcBridgeId}`

自宅PC上のPCブリッジを表す。

想定フィールド:

- `displayName`
- `status`: `active`, `inactive`, `disabled`
- `workspaceName`
- `workspacePathHash`
- `createdAt`
- `lastSeenAt`
- `leaseOwner`
- `version`

`workspacePathHash` は、スマホ側にローカルパスを直接出さずに、設定変更検知や診断に使うための値とする。

### `sessions/{sessionId}`

Codexへ送る作業単位を表す。

想定フィールド:

- `title`
- `status`: `idle`, `queued`, `running`, `completed`, `failed`
- `targetPcBridgeId`
- `createdAt`
- `updatedAt`
- `lastCommandId`
- `lastResultPreview`
- `lastErrorPreview`

### `commands/{commandId}`

セッション内の1つの指示を表す。

想定フィールド:

- `text`
- `status`: `queued`, `running`, `completed`, `failed`, `canceled`
- `targetPcBridgeId`
- `createdByDeviceId`
- `createdAt`
- `claimedAt`
- `claimedByPcBridgeId`
- `claimExpiresAt`
- `startedAt`
- `completedAt`
- `resultText`
- `errorText`
- `notificationSentAt`

## 状態遷移

### セッション状態

```text
idle -> queued -> running -> completed
                  running -> failed
completed -> queued
failed -> queued
```

- `idle`: まだ未処理コマンドがない。
- `queued`: セッション内に待機中コマンドがある。
- `running`: PCブリッジがコマンドを処理中。
- `completed`: 直近コマンドが成功した。
- `failed`: 直近コマンドが失敗した。

### コマンド状態

```text
queued -> running -> completed
queued -> canceled
running -> failed
```

- `queued`: Androidアプリが作成し、PCブリッジの取得待ち。
- `running`: PCブリッジがclaimし、処理中。
- `completed`: 最終結果が保存された。
- `failed`: エラー内容が保存された。
- `canceled`: 予約済み状態。MVPではUIからのキャンセル操作はpost-MVPでもよい。

## 二重処理防止

PCブリッジは、`queued` コマンドを処理する前にclaimする。

MVPでは次の方針を採用する。

- `queued` のコマンドだけを処理対象にする。
- claim時に `claimedByPcBridgeId`, `claimedAt`, `claimExpiresAt` を設定する。
- claim成功後に `running` へ遷移する。
- `claimExpiresAt` を過ぎた `running` コマンドは、Phase 4以降で復旧方針を実装する。
- 同じコマンドを複数PCブリッジが同時処理しないよう、Firestore transactionを使う。

## Androidアプリ責務

- 認証またはペアリング状態を保持する。
- セッション一覧を表示する。
- セッションを作成する。
- コマンドを作成する。
- コマンド状態と最終結果を表示する。
- FCM tokenを登録・更新する。
- 通知タップ時に該当セッションへ遷移する。

Androidアプリは管理者権限やFirebase Admin credentialを持たない。

## 認証・ペアリング方針

MVPでは、単一ユーザー・単一主PCを前提にした簡易ペアリングを採用する。

### Androidアプリ認証

MVPの推奨方針は Firebase Auth の anonymous auth を使い、後からemail sign-in等へ移行できる構成にすること。

- 初回起動時にAndroidアプリがFirebase Authで匿名ユーザーを作成する。
- 作成された `uid` を `userId` としてFirestoreパスに使う。
- 端末ごとに `devices/{deviceId}` を作成する。
- FCM tokenは `devices/{deviceId}` に保存する。
- email sign-inやGoogle sign-inはpost-MVPで追加可能にする。

この方針は、MVPの個人利用ではセットアップを軽くしつつ、Firestore Security Rulesでユーザー境界を作りやすい。

### PCブリッジ登録

PCブリッジはAndroidアプリ側で作成したユーザーに紐づく。

MVPでは次のどちらかをPhase 3で選べるようにする。

- Androidアプリが短時間有効なpairing codeを表示し、PCブリッジの初回設定で入力する。
- 開発者がFirebase consoleまたはローカル設定で `userId` と `pcBridgeId` を登録する。

Releaseに近いMVPでは、pairing code方式を優先する。手動登録は開発初期の暫定手段として扱う。

PCブリッジ登録後は、`pcBridges/{pcBridgeId}` に次を保存する。

- 読みやすいPC名。
- 固定ワークスペース名。
- 最終接続時刻。
- ブリッジの有効/無効状態。

### PCブリッジ資格情報

PCブリッジはローカル設定ファイルに資格情報を保存する。

制約:

- 資格情報はGitにコミットしない。
- AndroidアプリにFirebase Admin credentialを持たせない。
- PCブリッジに広範な管理者権限を持たせる場合でも、Phase 3でローカル限定の設定手順と `.gitignore` を整える。
- 可能であれば、PCブリッジもユーザー単位の制約付き認証でFirestoreへアクセスする。

## Firestore Security Rules要件

Phase 3以降でSecurity Rulesを実装する際は、少なくとも次を満たす。

### ユーザー境界

- `users/{userId}` 配下は、認証済みユーザーの `request.auth.uid == userId` の場合だけ読める。
- 他ユーザーのセッション、コマンド、デバイス、PCブリッジは読めない。
- Androidアプリは自分の `devices/{deviceId}` と `sessions/{sessionId}` と `commands/{commandId}` だけを作成/参照できる。

### Androidアプリの書き込み制限

Androidアプリから許可する書き込み:

- 自端末の `devices/{deviceId}` 作成/更新。
- セッション作成。
- `queued` コマンド作成。
- 通知token更新。

Androidアプリから禁止する書き込み:

- `running`, `completed`, `failed` への直接遷移。
- `resultText`, `errorText`, `claimedByPcBridgeId`, `claimExpiresAt` の直接更新。
- 他端末やPCブリッジの資格情報更新。

### PCブリッジの書き込み制限

PCブリッジから許可する書き込み:

- 自分の `pcBridges/{pcBridgeId}` の `lastSeenAt`, `status`, `version` 更新。
- 自分を `targetPcBridgeId` に持つ `queued` コマンドのclaim。
- claim済みコマンドの `running`, `completed`, `failed` 更新。
- `resultText`, `errorText`, `startedAt`, `completedAt` 更新。

PCブリッジから禁止する書き込み:

- 他PCブリッジ宛コマンドのclaim。
- Android端末のFCM token変更。
- 他ユーザー配下へのアクセス。

### Rulesテスト要件

Phase 3またはPhase 6までに、Firebase Emulatorで次を確認する。

- 他ユーザーのセッションを読めない。
- Androidアプリが結果フィールドを書けない。
- PCブリッジが他PC宛コマンドをclaimできない。
- `queued` 以外のコマンドをclaimできない。
- 通知tokenは対象端末だけ更新できる。

## 秘密情報とローカル設定

リポジトリに含めないもの:

- Firebase Admin SDK service account JSON。
- PCブリッジのpairing tokenやrefresh token。
- Android署名鍵。
- `.env` やローカルFirebase設定の秘密値。

リポジトリに含めてよいもの:

- サンプル設定ファイル。
- 必須環境変数名の一覧。
- セットアップ手順。
- Security Rulesとテスト。

## 認可境界

Androidアプリ、PCブリッジ、Cloud Functionsの権限は分離する。

- Androidアプリ: セッション作成、コマンド作成、結果読み取り、通知token登録。
- PCブリッジ: 自分宛コマンドのclaim、処理結果更新、heartbeat更新。
- Cloud Functions: 通知送信、必要に応じたpairing code検証。

この分離により、Androidアプリが侵害されても、任意の結果書き込みや他ユーザーアクセスを防ぐ。

## PCブリッジ責務

PCブリッジの詳細はPhase 2の別サブIssueで確定する。MVPでは次を前提にする。

- Windows上で動く常駐または手動起動の companion process とする。
- 自分に紐づくコマンドだけを処理する。
- 固定ワークスペースを1つ扱う。
- Codexへの指示投入と最終結果取得を担当する。
- Androidアプリから受け取った文字列を raw shell command として実行しない。

## 通知責務

通知責務の詳細はPhase 2の別サブIssueで確定する。MVPでは、コマンドが `completed` または `failed` になったタイミングでFCM通知を送る。

## 未確定事項

次の項目は、Phase 2の残りサブIssueで確定する。

- PCブリッジの実装ランタイムとCodex呼び出し方式。
- Cloud Functions通知トリガーの詳細。
- MVP脅威モデルとRelease前セキュリティ確認項目。
