# アーキテクチャ

## 目的

この文書は、Androidアプリから自宅PC上のCodexへ指示を送り、PC側で処理した最終結果をAndroidアプリへ返すためのMVPアーキテクチャを定義する。

MVPでは、WiFiと携帯回線の両方で利用できることを優先し、Androidアプリから自宅PCへ直接接続しない。AndroidアプリとPCブリッジは、どちらもFirebaseへアウトバウンド接続する。

## システム構成

MVPは次の3要素で構成する。

- Androidアプリ: セッション一覧、セッション作成、指示入力、進捗概要/最終結果表示、通知タップ時の遷移、端末言語に応じた表示切替を担当する。
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
- `favorite`: Androidアプリでお気に入りとして表示するための真偽値。未設定時は `false` と同等に扱う。
- `groupName`: Androidアプリでセッションを絞り込むための任意グループ名。未設定時は未分類として扱う。
- `createdAt`
- `updatedAt`
- `deletedAt`: Androidアプリの履歴から除外するためのソフト削除時刻。物理削除は初期実装では行わない。
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
- running中のコマンドでは、PCブリッジが保存した進捗概要を表示する。
- FCM tokenを登録・更新する。
- 通知タップ時に該当セッションへ遷移する。
- 端末の言語設定に応じて、日本語、英語、中国語、韓国語へ表示を切り替える。未対応言語は英語へフォールバックする。

Androidアプリは管理者権限やFirebase Admin credentialを持たない。

## Androidアプリ設計パターン

Androidアプリは、Flutterの画面構成に合わせた **MVVM + Repository** を採用する。

- Model: Firestoreに保存するセッション、コマンド、PCブリッジ状態、CLIオプションなどのデータ構造を表す。
- View: Flutterの画面、ダイアログ、再利用ウィジェットを表す。表示とユーザー操作の受付を担当する。
- ViewModel相当: 各 `StatefulWidget` の `State` が、入力コントローラ、選択中フィルタ、送信中フラグ、ダイアログ起動などの画面状態を持つ。現時点では外部パッケージを追加せず、画面単位の状態に閉じる。
- Repository: ViewからFirestoreの詳細を隠し、セッション、コマンド、CLI既定値、PCブリッジ状態の読み書きを担当する。
- Service: Firebase初期化、匿名サインイン、FCM登録、ローカル通知、通知タップ遷移など、アプリ横断の外部I/Oを担当する。

この構成により、#101 のようなFirebase接続先設定やペアリング画面を追加する場合も、Viewは設定入力に集中し、Firebase初期化・保存・検証はServiceまたはRepositoryへ分離できる。

### Androidファイル構成

`app/lib/main.dart` はアプリの公開入口と `part` 宣言だけを持つ。既存テストとprivate helperの互換性を保つため、初期分割では同一Dart library内の `part` ファイルとして責務別に分ける。将来、依存関係が安定した段階で通常の `import` / `export` へ移行してよい。

```text
app/lib/main.dart
app/lib/src/core/constants.dart
app/lib/src/l10n/app_strings.dart
app/lib/src/bootstrap/bootstrap.dart
app/lib/src/models/session_models.dart
app/lib/src/repositories/session_repository.dart
app/lib/src/app/remote_codex_app.dart
app/lib/src/views/session_list_view.dart
app/lib/src/views/session_detail_page.dart
app/lib/src/views/session_drawer.dart
app/lib/src/dialogs/session_options_dialog.dart
app/lib/src/dialogs/text_value_dialogs.dart
app/lib/src/widgets/connection_widgets.dart
app/lib/src/widgets/session_tile.dart
app/lib/src/widgets/command_widgets.dart
```

### Androidファイル責務

- `main.dart`: Flutter、Firebase、Firestore、通知、localizationに必要なpackage importと `part` 宣言を集約する。
- `src/core/constants.dart`: 既定PCブリッジID、Codexモデル候補、sandbox候補、通知channel、Navigator key、CLIオプションヘルプの定義を保持する。
- `src/l10n/app_strings.dart`: アプリ内文字列、対応locale、localization delegate、`BuildContext` 拡張を保持する。
- `src/bootstrap/bootstrap.dart`: `main()`、Firebase初期化、匿名認証、FCM token登録、通知初期化、通知payload解析、`NotificationService` を保持する。
- `src/models/session_models.dart`: `AppBootstrap` 以外の画面・Repository間で共有する `SessionSummary`, `CommandSummary`, `PcBridgeStatus`, `SessionCreateOptions` を保持する。
- `src/repositories/session_repository.dart`: `SessionRepository` インターフェースと `FirestoreSessionRepository` 実装、Firestore変換helperを保持する。
- `src/app/remote_codex_app.dart`: `MaterialApp` と起動画面 `StartupView` を保持する。
- `src/views/session_list_view.dart`: セッション一覧画面、検索、グループ絞り込み、セッション作成、一覧上のセッション操作を保持する。
- `src/views/session_detail_page.dart`: セッション詳細画面、コマンド一覧購読、コマンド送信、詳細画面上の名前変更・お気に入り・グループ変更を保持する。
- `src/views/session_drawer.dart`: セッション詳細画面のドロワー内セッション切替を保持する。
- `src/dialogs/session_options_dialog.dart`: セッション作成/CLI既定値ダイアログ、CLIオプション要約、CLIヘルプ表示を保持する。
- `src/dialogs/text_value_dialogs.dart`: セッション名入力、グループ選択/新規入力、グループ候補計算を保持する。
- `src/widgets/connection_widgets.dart`: PC接続状態のコンパクト表示、接続設定モーダル、PC確認、CLI既定値導線、日時/期間表示helperを保持する。
- `src/widgets/session_tile.dart`: セッション一覧カードの表示を保持する。
- `src/widgets/command_widgets.dart`: コマンドカード、コマンド入力欄、空状態、起動/読み込みメッセージ、コマンド経過時間計算を保持する。

### 主要クラス関係

```text
RemoteCodexApp
  -> StartupView
    -> SessionListView
      -> SessionRepository
      -> SessionDetailPage
        -> SessionRepository
        -> SessionDrawer
        -> _CommandTile / _CommandComposer

SessionRepository
  <- FirestoreSessionRepository
  -> SessionSummary / CommandSummary / PcBridgeStatus / SessionCreateOptions

NotificationService
  -> appNavigatorKey
  -> SessionDetailPage
```

Viewは `SessionRepository` のstreamを購読し、Firestore document pathやtimestamp変換を直接扱わない。RepositoryはFirebase/Firestore SDKの型を受け持ち、Modelへ変換してViewへ渡す。

## Android Firebase接続先セットアップ

#101では、APK単体配布へ近づけるため、提案Bの「アプリ内セットアップ画面でFirebase接続先を登録する」方式を採用する。

初回起動時、端末内にFirebase接続情報が保存されていない場合は、Firebase初期化より前にセットアップ画面を表示する。利用者は自分のFirebase project ID、API key、app ID、messaging sender IDを入力し、アプリはそれを端末内の `SharedPreferences` に保存する。保存済み設定がある場合は、その値からruntime `FirebaseOptions` を組み立てて `Firebase.initializeApp(options: ...)` を実行する。

AndroidアプリにはFirebase Admin SDK credentialやservice account JSONを入力・保存しない。セットアップ画面でも、service account JSONやAdmin SDK credentialを貼り付けない注意書きを表示する。PCブリッジ側のservice account JSONと `ownerUserId` は、引き続きPC側ローカル設定だけで管理する。

開発者ビルドでは、既存の `google-services.json` を使うための「bundled Firebase config」起動も残す。この経路は開発・検証用であり、利用者ごとのAPK単体配布ではruntime設定入力を使う。

接続設定モーダルでは、現在のFirebase project IDを表示し、保存済みFirebase設定をクリアする導線を提供する。Firebase SDKは既定アプリ初期化後に接続先を安全に差し替えられないため、クリア後はアプリ再起動時にセットアップ画面へ戻る。

### Android表示言語

Flutterの `MaterialApp.supportedLocales` と localization delegate で端末言語を解決する。

MVP対応言語:

- 日本語: `ja`
- 英語: `en`
- 中国語: `zh`
- 韓国語: `ko`

対象範囲:

- 起動、認証、セッション一覧、セッション詳細。
- PCブリッジ状態、heartbeat、queue確認時刻、手動確認時刻。
- セッション作成、CLI既定値、詳細CLIオプション、項目別ヘルプ。
- 空状態、読み込み、失敗、送信、経過時間、進捗概要。

対象外または固定表記:

- CLIオプション名、model名、sandbox値、Firestore status、ファイルパス、API名などの技術識別子。
- 通知channel IDなどOS内部識別子。

現在のMVP実装は、ARB生成ではなく軽量なアプリ内文字列テーブルを使う。翻訳量が増える場合は、別IssueでARBベースへ移行する。

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

PCブリッジは、自宅PC上で動くローカル companion process とする。MVPではVS Codeが起動済みで、Codexを利用できる状態を前提にする。

- Windows上で動く常駐または手動起動の companion process とする。
- 自分に紐づくコマンドだけを処理する。
- 固定ワークスペースを1つ扱う。
- Codexへの指示投入と最終結果取得を担当する。
- Androidアプリから受け取った文字列を raw shell command として実行しない。

### 実装ランタイム方針

MVPのPCブリッジ実装ランタイムは、Phase 3でローカル環境を確認して最終決定する。候補は次の順で評価する。

1. Node.js/TypeScript
2. .NET
3. Dart

MVPではNode.js/TypeScriptを第一候補とする。

理由:

- Firebase Admin SDKまたはFirebaseクライアントSDKを扱いやすい。
- Windows常駐プロセスやCLI実装が軽い。
- 後でVS Code extensionとコード共有しやすい。

ただし、Phase 3でNode.js環境やFirebase接続が不都合な場合は.NETへ切り替えてよい。

### 固定ワークスペース

MVPではPCブリッジ設定に1つの固定ワークスペースを持たせる。

想定ローカル設定:

```json
{
  "pcBridgeId": "home-main-pc",
  "displayName": "Home PC",
  "workspaceName": "codex-remote-android",
  "workspacePath": "<local-path-to-repository>"
}
```

制約:

- `workspacePath` はローカル設定にのみ保存する。
- Firestoreには必要に応じて `workspaceName` と `workspacePathHash` だけを保存する。
- Androidアプリには、ユーザーが識別できる `displayName` と `workspaceName` を表示する。
- 複数ワークスペース選択はpost-MVPとする。

### Codex呼び出し境界

PCブリッジは、Androidアプリから受け取ったテキストを「Codexへの指示」として扱う。

禁止すること:

- Androidアプリから受け取った文字列をPowerShellやcmdへ直接渡す。
- 任意の実行ファイルパスやシェル引数をスマホ側から指定させる。
- Firestore上の値だけで作業ディレクトリを任意変更する。

許可すること:

- PCブリッジのローカル設定で固定したワークスペースに対してCodex指示を送る。
- Codex実行方法をPCブリッジ側の設定または実装で固定する。
- 実行結果、失敗理由、診断ログIDをFirestoreへ返す。

### Codex連携方式

MVPのCodex連携方式はPhase 4で実装時に確定するが、アーキテクチャ上は次の順で検討する。

1. 既存のCodex CLIまたはローカルCodex実行手段をPCブリッジから呼び出す。
2. VS Code上のCodex連携が必要な場合は、VS Code extensionまたはローカル補助APIを追加する。
3. CLI/拡張連携が不安定な場合は、PCブリッジの範囲を「コマンド受信と通知」までに分け、Codex投入方式を別Issueで扱う。

いずれの場合も、Codexへ渡す入力はテキスト指示であり、スマホから直接シェルを操作する設計にはしない。

Phase 4時点の実装:

- `CodexInvoker` interfaceでCodex呼び出し境界を分離する。
- デフォルトは `stub` modeで、raw shell実行を行わずに成功/失敗を検証する。
- `cli` modeではPCブリッジのローカル設定で固定したCodex CLIを起動する。Windowsの `.cmd` は `cmd.exe /d /s /c` 経由で起動し、スマホ入力はshell引数にしない。
- スマホ入力はCLI引数ではなくstdin promptとして渡す。
- 実行ファイル、作業ディレクトリ、sandbox、timeoutはFirestore値ではなくローカル設定で決める。
- GitHub CLIなどVS Code通常シェル相当のネットワークアクセスが必要な場合だけ、ローカル設定の明示的なopt-inで `--dangerously-bypass-approvals-and-sandbox` を使う。スマホ入力をshell commandとして扱わない境界は維持する。

### Relay adapter境界

Phase 4時点では、PCブリッジのrelayアクセスを `CommandRepository` interfaceで分離する。

- `local`: ローカルJSON relay。Firebase未設定でも状態遷移を検証するために使う。
- `firestore`: Firebase Admin SDKでFirestoreへ接続するMVP本番想定adapter。

Firestore実接続時は、`CommandRepository` のclaim/complete/fail/heartbeat操作をFirestore transactionとSecurity Rules前提に置き換える。

Firestore adapterコードは実装済み。実接続検証は、利用者自身のFirebaseプロジェクト、service account JSON、`ownerUserId` を設定した後に行う。

### 起動とheartbeat

PCブリッジは起動中、定期的に `pcBridges/{pcBridgeId}.lastSeenAt` を更新する。

Androidアプリは次を表示する。

- `lastSeenAt` が新しい: PCブリッジ接続中。
- `lastSeenAt` が古い: PCブリッジ待機中またはオフライン。
- `pcBridge` が存在しない: セットアップが必要。

heartbeat間隔とオフライン判定時間はPhase 4以降の実測で調整する。2026-04-26時点のMVP設定は次の通り。

- queued command確認: 5秒ごと。
- heartbeat: 5分ごと。
- offline判定: heartbeat間隔より十分長い時間を使う。MVPでは10分以上更新なしを目安にする。

### VS Code前提

MVPではVS Codeが起動済みであることを前提にする。

失敗時の扱い:

- VS CodeまたはCodex連携が利用できない場合、PCブリッジはコマンドを `failed` にする。
- `errorText` にはユーザーが次に確認できる内容を書く。
- 例: `VS CodeまたはCodex連携が利用できません。PC側でVS CodeとCodexの状態を確認してください。`

post-MVP:

- PCブリッジから `code.cmd` を起動する。
- Windowsサービスまたはスタートアップ登録でPCブリッジを自動起動する。
- VS Code extensionと連携してワークスペース状態を取得する。

### ローカルログ

PCブリッジはローカルに診断ログを出す。

ログに含めてよいもの:

- 起動/停止時刻。
- Firebase接続状態。
- コマンドID。
- 状態遷移。
- エラー種別。

ログに含めないもの:

- Firebase credential。
- pairing token。
- FCM token全文。
- コマンド本文や結果全文。必要な場合でもデバッグ設定時だけにする。

## 通知責務

MVPでは、コマンドが `completed` または `failed` になったタイミングでFCM通知を送る。

### 通知送信者

通知送信はFirebase Cloud Functionsが担当する。

理由:

- Androidアプリに通知送信用の管理者権限を持たせない。
- PCブリッジにFCM送信用の広い権限を持たせない。
- Firestoreの状態変更を起点に通知を一元化できる。

### 通知トリガー

Cloud Functionsは `commands/{commandId}` の更新を監視する。

通知対象:

- `status` が `completed` へ変わったとき。
- `status` が `failed` へ変わったとき。

通知しない対象:

- `queued` 作成時。
- `running` 遷移時。
- `notificationSentAt` が既に設定されている場合。
- `canceled`。MVPではキャンセルUIを持たないため、通知対象外とする。

### 通知payload

通知payloadには最小限の情報だけを含める。

含めてよいもの:

- `sessionId`
- `commandId`
- `status`
- 短い通知タイトル。
- 短い通知本文。

含めないもの:

- コマンド本文全文。
- 結果本文全文。
- ローカルPCの実パス。
- 認証情報、token、credential。

通知文面例:

- 成功: `Codexの処理が完了しました`
- 失敗: `Codexの処理が失敗しました`

アプリは通知タップ後、Firestoreから該当セッションとコマンドを読み、画面に最終結果またはエラーを表示する。

### 通知冪等性

二重通知を避けるため、Cloud Functionsは通知送信後に `notificationSentAt` を設定する。

MVPでは次の方針を採用する。

- `notificationSentAt` が未設定の `completed` / `failed` だけを送信対象にする。
- 通知送信に失敗した場合は、ログに残し、再試行方針をPhase 6で実装する。
- 通知送信成功後に `notificationSentAt` と必要なら `notificationError` を更新する。

## 脅威モデル

MVPで想定する主要脅威と緩和策を定義する。

### T-001 他ユーザーのセッション閲覧

脅威:

- 認証境界が弱い場合、別ユーザーのセッションや結果を読めてしまう。

緩和策:

- `users/{userId}` 配下を `request.auth.uid == userId` に制限する。
- Firestore Security RulesをEmulatorでテストする。
- Androidアプリから任意の `userId` を指定して読ませない。

### T-002 Androidアプリから結果や状態を偽装

脅威:

- Androidアプリが `completed` や `resultText` を直接書き換え、PC処理を偽装する。

緩和策:

- Androidアプリは `queued` コマンド作成だけを許可する。
- `running`, `completed`, `failed`, `resultText`, `errorText` はPCブリッジまたはCloud Functionsだけが更新できるようにする。

### T-003 PCブリッジの過剰権限

脅威:

- PCブリッジ資格情報が漏れた場合、他ユーザーや全データへアクセスできる。

緩和策:

- PCブリッジは自分のユーザーと自分宛コマンドだけを扱う。
- service accountを使う場合はローカルPCに限定し、リポジトリに含めない。
- 将来的にはカスタムトークンや制約付き認証へ移行できる設計にする。

### T-004 スマホからの任意コマンド実行

脅威:

- スマホ入力がそのままPowerShellやcmdに渡され、任意コマンド実行になる。

緩和策:

- スマホ入力はCodexへのテキスト指示として扱う。
- 実行コマンド、作業ディレクトリ、Codex起動方式はPCブリッジのローカル設定で固定する。
- Firestore上の値で実行ファイルやシェル引数を指定しない。

### T-005 通知payloadからの情報漏えい

脅威:

- ロック画面通知にコマンド本文や結果が表示される。

緩和策:

- FCM通知payloadには本文全文を含めない。
- 通知は完了/失敗だけを知らせる。
- 詳細はアプリ起動後に認証済みFirestore読み取りで取得する。

### T-006 コマンド二重処理

脅威:

- 複数PCブリッジや再試行により、同じコマンドが複数回処理される。

緩和策:

- Firestore transactionでclaimする。
- `claimedByPcBridgeId`, `claimExpiresAt`, `status` を確認する。
- `queued` 以外はclaimできない。

### T-007 PCブリッジ停止中の誤認

脅威:

- PCブリッジが停止しているのに、Androidアプリが処理中と誤表示する。

緩和策:

- `lastSeenAt` による接続状態表示を行う。
- PCブリッジ未登録、オフライン、処理中を分けて表示する。
- `running` のまま期限切れになったコマンドの復旧方針をPhase 4で実装する。

## Release前セキュリティ確認

Phase 7またはPhase 8で、少なくとも次を確認する。

- AndroidアプリにFirebase Admin credentialやservice account JSONが含まれていない。
- リポジトリにPCブリッジcredential、pairing token、署名鍵が含まれていない。
- Firestore Security Rulesの拒否テストが通る。
- Androidアプリから `resultText` や `status=completed` を直接書けない。
- 他ユーザーの `sessions` や `commands` を読めない。
- 通知payloadにコマンド本文や結果全文が含まれていない。
- PCブリッジは固定ワークスペース以外をFirestore値だけで実行対象にしない。
- 失敗時の `errorText` にcredentialやローカル秘密情報が含まれない。

## Phase 3への引き継ぎ

リポジトリ・環境セットアップ工程では、このアーキテクチャを元に次を作成する。

- Flutter app scaffold。
- PC bridge scaffold。
- Firebase scaffold。
- `.gitignore` とサンプル設定。
- Firebase Auth / Firestore / Functions / FCM の開発用設定手順。
- Firestore Security RulesとEmulatorテストの最小構成。
- PCブリッジのローカル設定ファイルサンプル。

## 未確定事項

次の項目は、Phase 3以降の実装時に確定する。

- PCブリッジの最終実装ランタイム。
- Codex呼び出し方式の実装詳細。
- heartbeat間隔とoffline判定時間の実測調整。
- pairing codeの具体UIと有効期限。
- 通知再試行の実装方式。
