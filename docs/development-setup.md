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

### Phase 5: Androidアプリ

Flutter SDKが必須。現時点では `flutter` が未検出のため、Flutter導入がPhase 5開始前のブロッカー。

### Phase 6: Push Notifications

Firebase CLI、Firebaseプロジェクト、FCM設定、AndroidアプリのFirebase設定ファイルが必要。

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

