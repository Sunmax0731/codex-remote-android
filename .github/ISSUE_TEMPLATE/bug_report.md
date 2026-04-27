---
name: 不具合報告
about: Androidアプリ、PCブリッジ、Firebase連携の不具合を報告する
title: "[Bug] "
labels: bug
assignees: ""
---

## 概要

何が起きているかを1-3文で書いてください。

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

`pc-bridge` で次を実行し、秘密情報がないことを確認してから貼ってください。

```powershell
npm.cmd run diagnose
```

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

貼らないもの: service account JSON、private key、token、UID原文、API key原文、`config.local.json` 全文、非公開コード全文。
