# 診断ログ収集Runbook

このRunbookは、Firebase設定、PCブリッジ、Android端末、通知、Codex CLIのどこで失敗しているかを、秘密情報を共有せずに切り分けるための手順である。

## 共有してはいけない情報

GitHub Issue、チャット、スクリーンショット、ログ抜粋には次を貼らない。

- `config.local.json` の全文
- service account JSON、private key、client secret
- `google-services.json` の全文
- FCM token、access token、refresh token、GitHub token
- Firebase Anonymous AuthのUID原文
- Firebase API key原文
- ローカルPCの絶対パス、非公開ワークスペース内容

共有が必要な場合は、先頭数文字と末尾数文字だけを残すか、`remotecodex-***` のようにマスクする。

## PCブリッジ診断

PCブリッジの設定検証、Node.js version、Codex CLI検出、最新ログのredaction済み末尾は次で取得する。

```powershell
Set-Location pc-bridge
npm.cmd run diagnose
```

出力はJSONで、次の方針で安全化している。

- `config.local.json` の原文は出さない。
- `workspacePath` と `serviceAccountPath` の原文は出さない。
- `ownerUserId` と `firebaseProjectId` はマスクする。
- 最新PCブリッジログは `private_key`、token、Firebase API keyなどをredactしてから末尾だけ出す。

Issueへ貼る前に、出力全体を目視で確認する。

## Android側で確認する項目

スマホ実機操作ができる利用者が確認する。Codex作業だけでは実機状態を保証しない。

- アプリversionまたはGitHub Release tag。
- Android端末名、Android version。
- Firebase setup画面で表示されるproject IDのマスク値。
- 通知権限が許可されているか。
- 対象セッションのstatus、command status、表示されている直近エラー。
- 通知タップで対象セッションへ遷移するか。

スクリーンショットを貼る場合は、UID、token、API key、個人情報、非公開プロンプトを隠す。

## Firebase側で確認する項目

利用者自身のFirebase projectで確認する。

```powershell
Set-Location firebase
firebase functions:log --only notifyCommandCompletion --limit 20
```

Firestore Consoleでは、対象user配下の次を確認する。

- `users/{uid}/sessions/{sessionId}.status`
- `users/{uid}/sessions/{sessionId}/commands/{commandId}.status`
- `notificationSentAt`
- `notificationSuccessCount`
- `notificationFailureCount`
- `notificationLastError`

UID、token、result全文、error全文はIssueへ貼らない。必要なら時刻、status、count、マスク済みIDだけ共有する。

## Issue報告テンプレート

```markdown
## 概要

何が起きているかを1-3文で書く。

## 再現手順

1.
2.
3.

## 期待する動作


## 実際の動作


## 環境

- アプリversion / Release tag:
- Android端末 / OS version:
- PC OS:
- Node.js version:
- PCブリッジversion:
- Codex CLI version:
- Firebase project ID: `xxxx-***`
- PCブリッジ起動方法: foreground / background bat / Task Scheduler

## 診断情報

`pc-bridge` で `npm.cmd run diagnose` を実行し、秘密情報がないことを確認してから貼る。

```json
ここにredaction済み診断JSONを貼る
```

## Firebase確認結果

- Functions log時刻:
- command status:
- notificationSuccessCount:
- notificationFailureCount:
- notificationLastError:

## 補足

貼らないもの: service account JSON、private key、token、UID原文、API key原文、config.local.json全文、非公開コード全文。
```
