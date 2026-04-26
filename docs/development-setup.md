# 開発環境セットアップ

## 目的

この文書は、Androidアプリ、PCブリッジ、Firebaseリレーを開発するためのローカル環境を定義する。

Phase 5着手前にFlutter SDKとAndroid SDK command-line toolsを導入済み。Firebase CLIは未導入のため、Firebase実行は未完了の前提として扱う。

## 確認済み環境

確認日: 2026-04-26

| 項目 | 状態 | 確認結果 |
| --- | --- | --- |
| Java | 利用可能 | `java version "22.0.2"` |
| Node.js | 利用可能 | `v24.14.0` |
| npm | 利用可能 | `11.9.0` |
| adb | 利用可能 | `Android Debug Bridge version 1.0.41`, `C:\Users\gkkjh\AppData\Local\Android\Sdk\platform-tools\adb.exe` |
| Xperia 1 III wireless debugging | 利用可能 | `SO 51B`, `192.168.0.4:44283`, Android 13 (API 33) |
| Flutter SDK | 利用可能 | Flutter `3.41.7`, Dart `3.11.5`, `D:\tools\flutter` |
| Firebase CLI | 未検出 | `firebase` がPATH上にない |
| `ANDROID_HOME` | 設定済み | `C:\Users\gkkjh\AppData\Local\Android\Sdk` |
| `ANDROID_SDK_ROOT` | 設定済み | `C:\Users\gkkjh\AppData\Local\Android\Sdk` |

## Flutter SDK導入状態

Flutter SDKは次の場所に導入済み。

```text
D:\tools\flutter
```

User PATHには次を追加済み。

```text
D:\tools\flutter\bin
C:\Users\gkkjh\AppData\Local\Android\Sdk\platform-tools
```

VS Code user settingsにはFlutter拡張向けに次を設定済み。

```json
"dart.flutterSdkPath": "D:\\tools\\flutter"
```

既に起動しているPowerShell、VS Code、CodexプロセスはUser PATHの変更を自動では読み込まない。`flutter` コマンドが見つからない場合は、VS Codeとターミナルを再起動する。

再起動前に確認する場合は、一時的にPATHを追加して実行する。

```powershell
$env:Path = "D:\tools\flutter\bin;C:\Users\gkkjh\AppData\Local\Android\Sdk\platform-tools;" + $env:Path
flutter doctor -v
flutter devices
```

確認済み:

- `flutter doctor -v` でFlutter、Android toolchain、Chrome、Connected device、Network resourcesが成功。
- Android SDKは `platforms;android-36` と `build-tools;36.0.0` を導入済み。
- Android SDK licensesは承諾済み。
- `flutter devices` でXperia 1 III (`SO 51B`) を検出済み。

`flutter doctor` のVisual Studio警告はWindowsデスクトップアプリ向けのC++ workload不足であり、Android実機開発のブロッカーではない。

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

上記は2026-04-26時点で確認済み。

### Android SDK

Android SDKは次の場所を利用する。

```text
C:\Users\gkkjh\AppData\Local\Android\Sdk
```

User環境変数には次を設定済み。

```text
ANDROID_HOME=C:\Users\gkkjh\AppData\Local\Android\Sdk
ANDROID_SDK_ROOT=C:\Users\gkkjh\AppData\Local\Android\Sdk
```

Phase 5またはPhase 8までに次を確認する。

```powershell
adb devices
```

command-line toolsは `cmdline-tools\latest` として導入済み。SDK Platform 36、Build Tools 36.0.0、Platform Toolsを利用する。

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

Phase 5開始前の再確認:

```text
SO 51B (mobile) • 192.168.0.4:44283 • android-arm64 • Android 13 (API 33)
```

Phase 5実機確認:

```text
SO 51B (mobile) • 192.168.0.4:39757 • android-arm64 • Android 13 (API 33)
```

確認済み:

- `flutter run -d 192.168.0.4:39757 --debug --no-resident` でXperia 1 IIIへDebug APKをインストール、起動。
- アプリ起動時のFirebase初期化順序を修正し、`Firebase.initializeApp()` 後にFirestoreを参照する形へ変更。
- Firestore rulesを `firebase deploy --only firestore:rules` で実プロジェクト `remotecodex-c52ae` へデプロイ。
- Xperia 1 III画面で匿名認証後のセッション一覧初期画面を確認。
- 画面に表示されたUIDをPCブリッジのローカル `ownerUserId` に設定し、PCブリッジがFirestore接続で `No queued command found.` まで到達することを確認。
- resident `flutter run -d 192.168.0.4:39757 --debug` 中に手動hot reloadを実行し、変更反映を確認。

residentのhot reloadは次のように起動して、変更後に `r` を押して確認する。

```powershell
Set-Location app
flutter run -d 192.168.0.4:39757 --debug
```

終了は `q`。ワイヤレスデバッグのポートは変わるため、接続できない場合はXperia側の現在のdebug-portを確認し直す。

実行ログにGoogle Play services由来の `DEVELOPER_ERROR` やgraphics buffer警告が出る場合がある。匿名認証、Firestore画面表示、hot reloadが成立している限り、Phase 5のブロッカーとして扱わない。

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
- `cli` modeは固定したCodex CLIを起動し、スマホ入力はstdin promptとして渡す。
- 実Codex実行は作業内容を伴うため、受入条件が明確なIssueでだけ検証する。

Issue #29で追加確認済み:

- Codex CLI `0.114.0` では既定モデル `gpt-5.5` が未対応だったため、PCブリッジのローカル設定に `codexModel: "gpt-5.2"` を追加する。
- WindowsではNode.jsから `.cmd` を直接spawnできないため、PCブリッジはローカル設定の `.cmd` 起動だけ `cmd.exe /d /s /c` を使う。スマホ入力はstdin promptのままで、shell commandとして扱わない。
- `--output-last-message` が空の場合は成功扱いにせず、`failed` と `errorText` 保存にする。
- ローカルrelayで `cli` modeの成功、未対応モデル失敗、timeout失敗を確認済み。
- Firestore relayで `cli` modeの短いsmoke commandを処理し、`completed`、`resultText: CLI_FIRESTORE_OK`、`notificationSuccessCount: 1` を確認済み。

実Codex検証用のPCブリッジ設定例:

```json
{
  "codexMode": "cli",
  "codexCommandPath": "codex.cmd",
  "codexModel": "gpt-5.2",
  "codexSandbox": "workspace-write",
  "codexTimeoutSeconds": 900,
  "pollIntervalSeconds": 10,
  "maxCommandsPerTick": 5
}
```

PC側で常駐実行する。

```powershell
Set-Location D:\Claude\FlutterApp\codex-remote-android\pc-bridge
npm.cmd run start:watch
```

Issue #29のユーザー受け入れタスク:

```text
DドライブのClaudeディレクトリ以下にあるローカルリポジトリを列挙してください。またそれらの概要を要約して、リポジトリ名と併記して教えてください。
```

確認観点:

- スマホアプリから送信したcommandが `queued -> running -> completed` へ進む。
- `resultText` にCodex回答が保存される。
- アプリをバックグラウンドにしていても完了時にプッシュ通知が届く。
- 通知またはアプリ画面から対象セッションを開くと回答が表示される。
- 失敗時は `failed` と `errorText` が保存される。

### Phase 5: Androidアプリ

Flutter SDKが必須。2026-04-26時点でFlutter SDK、Android SDK 36、Xperia 1 IIIのFlutter実機認識まで確認済みのため、Flutter導入はPhase 5開始前ブロッカーから解消済み。

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

Phase 4実装後のrelay状態:

- `local` relayは実装済みで、`npm.cmd run validate:local` で検証できる。
- `firestore` relayはFirebase Admin SDKを使う実adapterコードを実装済み。
- Firestore実接続には `firebaseProjectId` とローカルの `serviceAccountPath` が必要。
- `serviceAccountPath` のJSONはGitに含めない。
- 実Firebase資格情報がまだないため、Firestore adapterは `npm.cmd run check` によるコンパイル確認まで実施済み。

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

