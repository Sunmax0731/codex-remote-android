# 開発環境セットアップ

## 目的

この文書は、Androidアプリ、PCブリッジ、Firebaseリレーを開発するためのローカル環境を定義する。

Phase 3開始時点では、Flutter SDKとFirebase CLIがPATH上にないため、Androidアプリ生成とFirebase実行は未完了の前提として扱う。

## 確認済み環境

確認日: 2026-04-26

| 項目 | 状態 | 確認結果 |
| --- | --- | --- |
| Java | 利用可能 | `java version "22.0.2"` |
| Node.js | 利用可能 | `v24.14.0` |
| npm | 利用可能 | `11.9.0` |
| adb | 利用可能 | `Android Debug Bridge version 1.0.41`, `C:\platform-tools\adb.exe` |
| Xperia 1 III wireless debugging | 利用可能 | `192.168.0.4:36177 device` |
| Flutter SDK | 未検出 | `flutter` がPATH上にない |
| Firebase CLI | 未検出 | `firebase` がPATH上にない |
| `ANDROID_HOME` | 未設定 | 環境変数なし |
| `ANDROID_SDK_ROOT` | 未設定 | 環境変数なし |

## 必須ツール

### Flutter SDK

Androidアプリ実装前にFlutter SDKを導入し、`flutter` コマンドをPATHから実行できる状態にする。

確認コマンド:

```powershell
flutter --version
flutter doctor
```

Phase 5開始前の期待状態:

- `flutter --version` が成功する。
- `flutter doctor` でAndroid toolchainの致命的なエラーがない。
- Xperia 1 IIIまたはAndroidエミュレータに対して `flutter devices` が端末を検出できる。

### Android SDK

`adb` は利用可能だが、`ANDROID_HOME` と `ANDROID_SDK_ROOT` は未設定。

Phase 5またはPhase 8までに次を確認する。

```powershell
adb devices
```

必要に応じてAndroid Studioまたはcommand line toolsのSDKパスを環境変数へ設定する。

## 実機ワイヤレスデバッグ

今後のAndroid実機確認は、自宅WiFi上のXperia 1 IIIをワイヤレスデバッグでPCへ接続して行う。

Phase 3時点で確認済みの接続:

```powershell
adb devices
```

確認結果:

```text
192.168.0.4:36177 device
```

### 前提

- PCとXperia 1 IIIが同じ自宅WiFiルーター配下にいる。
- Xperia 1 IIIで開発者向けオプションが有効。
- Xperia 1 IIIでワイヤレスデバッグが有効。
- PC側で `adb` が利用できる。
- Flutter hot reloadを使う場合は、PC側でFlutter SDKが利用できる。

ルーターでAP isolation、プライバシーセパレーター、ゲストネットワーク分離が有効な場合、PCからスマホへ接続できないことがある。

### 初回ペアリング

Xperia 1 IIIで次を開く。

```text
設定 -> システム -> 開発者向けオプション -> ワイヤレス デバッグ -> ペア設定コードによるペア設定
```

画面に表示される `IPアドレスとポート` と `ペア設定コード` を使う。

例:

```text
IPアドレスとポート: 192.168.0.4:37145
ペア設定コード: 123456
```

PC側:

```powershell
adb pair 192.168.0.4:37145
```

表示された入力欄にペア設定コードを入力する。

### 接続

ペアリング完了後、Xperia 1 IIIのワイヤレスデバッグ画面に戻り、通常表示の `IPアドレスとポート` を確認する。

```powershell
adb connect 192.168.0.4:<debug-port>
adb devices
```

`adb devices` に `device` と表示されれば接続済み。

### pairing-port と debug-port の違い

- `pairing-port`: 「ペア設定コードによるペア設定」画面に表示される一時的なポート。`adb pair` で使う。
- `debug-port`: ワイヤレスデバッグ画面の通常表示に出る接続用ポート。`adb connect` で使う。

この2つは別のポートであり、同じ値とは限らない。

### Flutter hot reload

Flutter SDK導入後、実機を接続した状態で次を実行する。

```powershell
Set-Location app
flutter devices
flutter run -d <device-id>
```

実行中のhot reload:

- ターミナル: `r`
- hot restart: `R`
- VS Code: Flutter拡張のHot Reload操作または保存時hot reload

hot reloadはDebug実行中だけ有効。Release APKとしてインストールしたアプリはhot reload対象外。

### 再接続

ワイヤレスデバッグのポートは変わることがある。接続できない場合は、Xperia 1 IIIのワイヤレスデバッグ画面で現在の `IPアドレスとポート` を確認し直す。

```powershell
adb disconnect
adb connect 192.168.0.4:<current-debug-port>
adb devices
```

### トラブルシュート

- `adb devices` に表示されない: PCとスマホが同じWiFiか確認する。
- `offline` と表示される: Xperia側でワイヤレスデバッグをOFF/ONし、再接続する。
- `failed to connect` になる: debug-portが変わっていないか確認する。
- hot reloadできない: `flutter run` のDebugセッションが継続しているか確認する。
- 携帯回線に切り替わった: hot reload用のadb接続は自宅WiFiへ戻してから再接続する。

### Firebase CLI

Firebase scaffold、Emulator、Functions、Rules testのためにFirebase CLIが必要。

確認コマンド:

```powershell
firebase --version
firebase login
```

Phase 3以降で導入する場合の候補:

```powershell
npm.cmd install -g firebase-tools
```

### Node.js / npm

PCブリッジの第一候補ランタイムはNode.js/TypeScript。

確認済み:

```powershell
node --version
npm.cmd --version
```

この環境ではPowerShellの実行ポリシーにより `npm` ではなく `npm.cmd` を使う方針にする。

## PowerShellと日本語ファイル

PowerShellの通常 `Get-Content` 表示では、UTF-8の日本語Markdownが文字化けする場合がある。

日本語文書を確認するときは、次のようにUTF-8を明示する。

```powershell
[System.IO.File]::ReadAllText("docs\architecture.md", [System.Text.Encoding]::UTF8)
```

GitHub Issue本文やコメントへ日本語長文を投稿した後は、`gh issue view` などで読み戻して文字化けがないことを確認する。

## Phase別の環境前提

### Phase 4: PCブリッジ

Phase 4はNode.js/TypeScriptで開始できる。Firebase CLIが未導入でも、ローカルの最小実装とユニットテストは進められる。

Firebaseへ接続する作業に入る前に、Firebase CLIまたはFirebaseプロジェクト設定を用意する。

Phase 3で作成済み:

- `pc-bridge/package.json`
- `pc-bridge/tsconfig.json`
- `pc-bridge/src/index.ts`
- `pc-bridge/config.example.json`

確認コマンド:

```powershell
Set-Location pc-bridge
npm.cmd install
npm.cmd run check
```

Phase 3時点の確認結果:

- `npm.cmd install` 成功。
- `npm.cmd run check` 成功。
- `npm audit` は 2 low / 8 moderate の脆弱性警告を報告。Phase 4で依存関係を実装に合わせて再評価する。

Phase 4で追加された確認コマンド:

```powershell
Set-Location pc-bridge
npm.cmd run validate:local
```

確認内容:

- ローカルJSON relay上の `queued` コマンドをclaimする。
- 成功コマンドを `completed` にする。
- 失敗コマンドを `failed` にする。
- `resultText` と `errorText` の保存を確認する。
- スマホ入力をraw shell commandとして実行しないstub境界で処理する。

Phase 4で確認済み:

- `codex.cmd` は `C:\Users\gkkjh\AppData\Roaming\npm\codex.cmd` に存在する。
- `codex exec --help` は利用可能。
- PCブリッジには `stub` modeと `cli` modeの `CodexInvoker` 境界を用意した。
- `cli` modeは `shell: false` で固定 `codex.cmd exec` を起動し、スマホ入力はstdin promptとして渡す。
- 実Codex実行は作業内容を伴うため、受入条件が明確なIssueでだけ検証する。

### Phase 5: Androidアプリ

Flutter SDKが必須。現時点では `flutter` が未検出のため、Flutter導入がPhase 5開始前のブロッカー。

Phase 3で作成済み:

- `app/README.md`

Flutter SDK導入後、Phase 5で `app/` 配下にFlutterプロジェクトを生成する。

### Phase 6: Push Notifications

Firebase CLI、Firebaseプロジェクト、FCM設定、AndroidアプリのFirebase設定ファイルが必要。

Phase 3で作成済み:

- `firebase/firebase.json`
- `firebase/firestore.rules`
- `firebase/firestore.indexes.json`
- `firebase/functions/package.json`
- `firebase/functions/tsconfig.json`
- `firebase/functions/src/index.ts`

確認コマンド:

```powershell
Set-Location firebase\functions
npm.cmd install
npm.cmd run check
```

Phase 3時点の確認結果:

- `npm.cmd install` 成功。
- `npm.cmd run check` 成功。
- `npm audit` は 2 low / 9 moderate の脆弱性警告を報告。Phase 6でFunctions実装に合わせて再評価する。
- `package.json` の Firebase Functions runtime は `node: 22`。ローカルNode.jsは `v24.14.0` のため、`npm` は `EBADENGINE` warningを表示するが、TypeScript checkは成功する。

### Phase 8: Release

APKビルドとXperia 1 IIIへのインストール確認が必要。Flutter SDK、Android SDK、adb、署名設定が必要。

## 秘密情報の扱い

次のファイルはGitに含めない。

- Firebase service account JSON。
- PCブリッジのローカル設定。
- pairing token。
- Android署名鍵。
- `.env`。

サンプル設定だけをリポジトリに含める。

## Phase 4への引き継ぎ

Phase 4では、`pc-bridge/` を起点にPCブリッジMVPを実装する。

最初に確認すること:

1. `pc-bridge/config.example.json` を元に `pc-bridge/config.local.json` を作成する。
2. `config.local.json` がGitに入らないことを確認する。
3. Firebaseプロジェクトを実接続するか、Firestoreアクセス層をモックして先にコマンドライフサイクルを実装するか決める。
4. `queued -> running -> completed/failed` の状態遷移を最小実装する。
5. Codex呼び出し方式は、raw shell実行にならない境界を守ってIssue内で確定する。

Phase 4開始時の既知ブロッカー:

- Firebase CLI未導入。
- Firebase実プロジェクト未設定。
- Codex呼び出し方式は未実装。

Phase 4開始時にブロッカーではないもの:

- Flutter SDK未導入。PCブリッジのローカル実装はNode.jsで開始できる。
- Android実機未接続。PCブリッジ単体実装には不要。

## Phase 3完了時レビュー

Phase 3では、環境確認、初期scaffold、セットアップ文書を追加した。

完了時点で実態に合わせて更新済みの文書:

- `README.md`
- `docs/development-setup.md`
- `app/README.md`
- `pc-bridge/README.md`
- `firebase/README.md`

Phase 4以降で実装が進んだ場合、`docs/architecture.md` と `docs/development-setup.md` を実装結果に合わせて更新する。

