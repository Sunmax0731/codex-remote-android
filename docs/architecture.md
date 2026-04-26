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

- Firebase Auth とペアリング方式の詳細。
- Firestore Security Rulesの具体要件。
- PCブリッジの実装ランタイムとCodex呼び出し方式。
- Cloud Functions通知トリガーの詳細。
- MVP脅威モデルとRelease前セキュリティ確認項目。
