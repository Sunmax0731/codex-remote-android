# npm audit Release前評価

実施日: 2026-04-27

対象Issue: #97

## 目的

Release前QAで検出された `npm audit` のlow/moderate警告について、Release blockerにするべきか、安全に依存更新できるかを確認する。

## 結論

現時点ではRelease blockerにしない。

理由:

- `pc-bridge` と `firebase/functions` の両方でhigh/criticalは検出されていない。
- 警告は主に `firebase-admin` / `firebase-functions` から入るFirebase SDKの間接依存に由来する。
- `firebase-admin` は確認時点の最新安定版 `13.8.0` を使用している。
- `npm audit fix` では解消できない。
- `npm audit fix --force` は `firebase-admin@10.1.0` や `firebase-functions@4.9.0` への破壊的なダウングレードを提示するため採用しない。

MVP Releaseでは既知制限として受け入れ、Firebase SDK側で安全な更新経路が出た時点、またはhigh/criticalが検出された時点で再評価する。

## 実行結果

### high以上の監査

Phase 7 QAベースラインで、次の結果を確認済み。

| 対象 | コマンド | 結果 |
| --- | --- | --- |
| `pc-bridge` | `npm.cmd audit --audit-level=high` | 成功。high以上なし |
| `firebase/functions` | `npm.cmd audit --audit-level=high` | 成功。high以上なし |

### 全体監査

`npm.cmd audit --json` ではlow/moderateの警告が残る。

| 対象 | low | moderate | high | critical |
| --- | ---: | ---: | ---: | ---: |
| `pc-bridge` | 2 | 8 | 0 | 0 |
| `firebase/functions` | 2 | 9 | 0 | 0 |

主な経路:

- `firebase-admin@13.8.0`
- `firebase-functions@6.6.0`
- `@google-cloud/firestore@7.11.6`
- `@google-cloud/storage@7.19.0`
- `google-gax@4.6.1`
- `gaxios@6.7.1`
- `uuid`
- `@tootallnate/once`

## 依存更新の確認

確認時点の主な最新バージョン:

| パッケージ | 現在 | 最新 | 判断 |
| --- | --- | --- | --- |
| `firebase-admin` | `13.8.0` | `13.8.0` | 直接依存として更新余地なし |
| `firebase-functions` | `6.6.0` | `7.2.5` | major更新。Release前QAでは即時採用しない |
| `@google-cloud/firestore` | `7.11.6` | `8.5.0` | `firebase-admin` の間接依存 |
| `@google-cloud/storage` | `7.19.0` | `7.19.0` | 直接更新余地なし |
| `google-gax` | `4.6.1` | `5.0.6` | 間接依存。major更新 |
| `uuid` | 複数 | `14.0.0` | 間接依存。major更新 |

`firebase-functions` v7への移行は、Cloud Functionsの実行環境、Firebase SDK API差分、デプロイ確認を伴うため、Release直前の監査対応としては扱わない。必要な場合は別Issueで移行計画、実装修正、デプロイ検証を行う。

## `npm audit fix` の結果

`pc-bridge` と `firebase/functions` の両方で `npm.cmd audit fix` を実行したが、依存関係は更新されず警告は残った。

`npm audit fix --force` は次のような破壊的変更を提示する。

- `firebase-admin@10.1.0` へのダウングレード
- `firebase-functions@4.9.0` へのダウングレード

これは現在の実装、Node.js実行環境、Firebase SDK利用箇所に対する後方互換性リスクが高いため採用しない。

## pnpm audit

`corepack pnpm audit --audit-level high` は `pnpm-lock.yaml` が存在しないため実行できなかった。

```text
ERR_PNPM_AUDIT_NO_LOCKFILE Cannot audit a project without a lockfile
```

pnpmを正式な依存管理手段として採用する場合は、`pnpm-lock.yaml` を導入し、npm lockfileとの併用方針を決めたうえで別Issueとして扱う。

## Release判断

今回のReleaseでは次の条件で進める。

- high/criticalが0件であることをRelease前に再確認する。
- low/moderateは既知制限として扱う。
- `npm audit fix --force` による破壊的ダウングレードは行わない。
- Firebase SDKの安全な更新経路が出た場合、またはhigh/criticalが検出された場合はRelease blockerとして再評価する。

## 次回見直し条件

次のいずれかに該当した場合、この判断を見直す。

- `firebase-admin` の新しい安定版で該当advisoryが解消された。
- `firebase-functions` v7以降へ移行する。
- `npm audit --audit-level=high` が失敗する。
- 公開範囲、利用者数、扱うデータの重要度が増える。
- Firebase SDKのセキュリティアドバイザリで実害条件がこのアプリに該当すると判断された。

