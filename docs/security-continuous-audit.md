# Public repository continuous security audit

この文書は、Public repositoryとして継続的に確認するSecurity運用をまとめる。

## GitHub security settings

2026-04-27にGitHub APIで次の状態を確認し、利用できる範囲を有効化した。

| Item | Status |
| --- | --- |
| Repository visibility | `public` |
| Dependabot alerts | enabled |
| Dependabot security updates | enabled |
| Secret scanning | enabled |
| Secret scanning push protection | enabled |
| Secret scanning non-provider patterns | disabled |
| Secret scanning validity checks | disabled |

non-provider patternsとvalidity checksはこのrepositoryで有効化できる状態ではなかったため、GitHub標準のsecret scanning/push protectionとローカルスキャンを併用する。

## Dependabot

`.github/dependabot.yml` で次を週次更新対象にする。

- `pc-bridge` npm dependencies
- `firebase/functions` npm dependencies
- `app` Flutter/Dart dependencies
- GitHub Actions

Dependabot PRはCIの `npm audit --audit-level=high`、Flutter test/analyze、Functions/Rules testを通して確認する。major updateやFirebase SDK updateは、Release前に実Firebase deployや実機E2Eへの影響を別途確認する。

## CI audit

`.github/workflows/ci.yml` では次を継続実行する。

- `pc-bridge`: `npm.cmd audit --audit-level=high`
- `firebase/functions`: `npm.cmd audit --audit-level=high`
- tracked files secret scan: `scripts/scan-secrets.ps1`

high/criticalが検出された場合はRelease blockerとして扱う。low/moderateは [npm audit Release前評価](qa-npm-audit-review.md) の判断に従い、既知制限として継続監視する。

## Local secret scan

Release前、または秘密情報を含む作業の後に次を実行する。

```powershell
.\scripts\scan-secrets.ps1
```

検出対象:

- PEM private key
- JSON `private_key`
- JSON `client_secret`
- JSON `refresh_token`
- JSON `access_token`
- GitHub token
- Google OAuth token
- Slack token
- Firebase API key shaped value

このスキャンは誤検知を避けるための補助であり、GitHub secret scanning/push protectionの代替ではない。検出された場合はpushせず、該当ファイルをGit管理外へ移動し、必要に応じてcredential rotateを行う。

## Release前確認

Release前には次を確認する。

- GitHub Actionsが成功している。
- Dependabot alertsにhigh/criticalが残っていない。
- `npm audit --audit-level=high` が `pc-bridge` と `firebase/functions` で成功する。
- `.\scripts\scan-secrets.ps1` が成功する。
- `docs/release-runbook.md` のGitHub Release前チェックに従い、署名鍵、service account JSON、`config.local.json`、logsをartifactへ含めない。
