# Firebase Functions / Firestore Rules 自動テスト

Issue #154 以降、Firebase層の退行検出はFunctions単体テストとFirestore Rules Emulatorテストに分ける。
どちらも利用者の実Firebase project、service account JSON、FCM実送信には依存しない。

## 実行コマンド

```powershell
Set-Location firebase\functions
npm.cmd run check
npm.cmd run build
npm.cmd run test:functions
npm.cmd run test:rules
npm.cmd run test
```

`npm.cmd run test:functions` は `node:test` で通知本文生成とredactionを確認する。
`npm.cmd run test:rules` は `firebase emulators:exec` でFirestore Emulatorを起動し、Rulesの代表的な許可/拒否ケースを確認する。

## Emulator設定

Rulesテストは `firebase/firebase.test.json` を使う。通常の開発用 `firebase.json` はFirestore Emulatorの既定portとして `8080` を使うが、ローカルで既に別Emulatorが動いていることがあるため、テスト用設定では `18080` を使う。

Firebase CLIが未導入の場合は次を先に実行する。

```powershell
npm.cmd install -g firebase-tools
firebase --version
```

## テスト対象

Functions:

- completed commandでは `resultText` から通知本文previewを作る。
- failed commandでは `errorText` から通知本文previewを作る。
- previewがない場合は `Session <sessionId>, command <commandId>` にfallbackする。
- private key、Firebase API key、Google access token、GitHub tokenなどを通知本文からredactする。
- previewは空白を1行に整形し、120文字へ切り詰める。

Firestore Rules:

- 自分の `users/{uid}/sessions/{sessionId}` と `commands/{commandId}` を読める。
- 自分のuser配下に `status: queued` のcommandを作成できる。
- clientから `completed` などのterminal commandを作成できない。
- clientから既存commandを更新できない。
- 他user配下のsession/commandを読めない、書けない。
- 未認証userはuser dataを読めない。

実Firestore、実Codex CLI、FCM通知成功件数の確認はRelease前smokeまたは対象Issueの検証手順で扱う。
