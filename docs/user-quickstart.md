# 利用者向けクイックスタート

この手順は、配布APKとPCブリッジzipを受け取った利用者が、初回セッション成功まで進めるための最短手順である。

## 重要な固定値

配布APKでは次の値を変更しない。

- アプリ名: `RemoteCodex`
- Android package名: `com.sunmax.remotecodex`
- 既定PCブリッジID: `home-main-pc`

Firebase ConsoleでAndroidアプリを登録するときは、package名に必ず `com.sunmax.remotecodex` を入力する。

## 用意するもの

- Android端末
- Windows PC
- 配布APK
- PCブリッジzip
- Node.js 22以上
- Codex CLI
- Firebase CLI
- Firebaseプロジェクト
- `google-services.json`
- PCブリッジ用 service account JSON

## 1. Firebaseプロジェクトを作成する

Firebase Consoleで新しいプロジェクトを作成する。

画面例は [Firebase手順](../firebase/README.md#1-firebaseプロジェクトを作成する) に掲載している。プロジェクトID、アカウント名、プロフィール画像などはマスク済みのサンプル画像である。

推奨:

- 既存の個人/業務プロジェクトと混ぜない。
- Codex Remote専用プロジェクトにする。

## 2. Authenticationを有効化する

Firebase Consoleで次を設定する。

1. Authenticationを開く。
2. Sign-in methodを開く。
3. Anonymousを有効化する。

## 3. Firestore Databaseを作成する

Firebase ConsoleでFirestore Databaseを作成する。

RulesとIndexesは、このリポジトリのFirebase構成をデプロイして使う。

```powershell
cd firebase
firebase login
firebase use --add
firebase deploy --only firestore:rules,firestore:indexes
```

## 4. AndroidアプリをFirebaseに登録する

Firebase ConsoleでAndroidアプリを追加する。

- Android package name: `com.sunmax.remotecodex`
- App nickname: 任意
- SHA-1: 初回のAPK配布では空でよい

登録後、`google-services.json` をダウンロードする。

## 5. PCブリッジを展開する

PCブリッジzipを任意の場所へ展開する。

例:

```powershell
New-Item -ItemType Directory -Force -Path D:\Tools\CodexRemote
Expand-Archive .\codex-remote-pc-bridge.zip -DestinationPath D:\Tools\CodexRemote -Force
Set-Location D:\Tools\CodexRemote\codex-remote-pc-bridge
```

依存関係をインストールする。

```powershell
npm.cmd install
npm.cmd run build
```

## 6. セットアップQRを生成する

PCセットアップWeb UIを起動する。

```powershell
npm.cmd run setup:web
```

ブラウザで開く。

```text
http://127.0.0.1:8787
```

画面で `google-services.json` を読み込み、QRを生成する。

QRに含まれるもの:

- Firebase project ID
- API key
- App ID
- Messaging sender ID
- Storage bucket

QRに含めてはいけないもの:

- service account JSON
- private key
- Admin SDK credential
- PCブリッジ設定
- Codex / GitHub / OpenAI などのtoken

## 7. AndroidアプリをインストールしてQRを読み取る

配布APKをAndroid端末へインストールする。

初回起動時にFirebase setup画面が表示されたら、`Scan setup QR` からPCで生成したQRを読み取る。

保存後、アプリがFirebaseへ接続し、匿名認証を行う。

## 8. service account JSONを作成する

継続運用では、PCブリッジ専用service accountにFirestore read/write用の `roles/datastore.user` を付与する方針を推奨します。初回セットアップを簡単にするためFirebase Admin SDKの既定keyを使う場合も、長期運用では [Firebase service account permissions](firebase-service-account-permissions.md) を確認してください。

Google Cloud ConsoleでPCブリッジ用のservice account JSONを作成する。

保存先の例:

```text
D:\secure\codex-remote-service-account.json
```

このJSONはPCローカルだけに保存する。Androidアプリ、QR、Issue、チャット、スクリーンショットへ含めない。

## 9. PCブリッジ設定を作成する

PCブリッジのフォルダで `config.local.json` を作成する。

```powershell
Copy-Item config.example.json config.local.json
```

主な設定:

```json
{
  "pcBridgeId": "home-main-pc",
  "displayName": "Home PC",
  "workspaceName": "my-workspace",
  "workspacePath": "D:\\work\\my-project",
  "firebaseProjectId": "your-firebase-project-id",
  "serviceAccountPath": "D:\\secure\\codex-remote-service-account.json",
  "relayMode": "firestore",
  "codexMode": "cli",
  "codexCommandPath": "codex.cmd",
  "codexModel": "gpt-5.4",
  "codexBypassSandbox": false
}
```

`workspacePath` はCodex CLIを実行する作業ディレクトリにする。

## 10. Cloud Functionsをデプロイする

完了通知を使うため、Cloud Functionsをデプロイする。

```powershell
cd firebase
firebase use
firebase deploy --only functions
```

初回デプロイではBlazeプランやGoogle Cloud APIの有効化が必要になる場合がある。

## 10.1 Firebase費用と予算アラートを確認する

このアプリは自分のFirebase/GCPプロジェクトを使う。ホスト済みサービス方式ではないため、課金と予算アラートは自分のプロジェクトで管理する。

主に増える利用量は、Firestoreのread/write、PCブリッジのpollingとheartbeat、command完了時のCloud Functions invocation、Functions/Cloud Loggingのログである。FCM自体はFirebaseのno-cost productとして扱われるが、通知を送るFunctionsや周辺Google CloudサービスにはBlazeプランと従量課金が関係する。

Google Cloud ConsoleのBillingでBudgets & alertsを作り、対象プロジェクトに小さな月額予算と複数しきい値の通知を設定する。詳細は [Firebase費用ガイド](firebase-cost-guide.md) を参照する。

## 11. PCブリッジを起動する

PCブリッジのフォルダで起動する。

```powershell
npm.cmd run start:watch
```

バックグラウンド起動する場合:

```powershell
.\scripts\start-watch-background.bat
```

ログオン時に自動起動する場合:

```powershell
.\scripts\register-watch-task.bat
schtasks /Run /TN "CodexRemotePcBridge"
```

## 12. Androidアプリから動作確認する

1. Androidアプリを開く。
2. 画面上部の接続情報でPCブリッジのheartbeatを確認する。
3. New sessionを作成する。
4. 短い指示を送信する。
5. 状態が `queued -> running -> completed` へ進むことを確認する。
6. 結果が表示されることを確認する。
7. 完了通知が届くことを確認する。

## 秘密情報の扱い

紛失・漏えい時の対応は [Credential incident runbook](credential-incident-runbook.md) を参照してください。

次は共有しない。

- service account JSON
- private key
- `config.local.json`
- Firebase debug log
- PCブリッジログ
- Codex / GitHub / OpenAI などのtoken
- 署名鍵
- `key.properties`

GitHub Issueや問い合わせ時も、上記を貼らない。

## 次に読む資料

- [配布準備](distribution-prep.md)
- [PCブリッジ配布パッケージ](pc-bridge-distribution.md)
- [release APK作成手順](release-apk.md)
- [Firebase手順](../firebase/README.md)
