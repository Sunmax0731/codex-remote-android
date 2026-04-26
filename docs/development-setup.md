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

