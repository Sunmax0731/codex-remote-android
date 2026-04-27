# CI

GitHub Actionsでは、秘密情報を必要としない範囲のPR/Release前チェックを自動実行する。

## workflow

`.github/workflows/ci.yml` は次の契機で実行する。

- `main` 宛てのPull Request
- `main` へのpush
- `v*` tagへのpush
- 手動実行

## 実行内容

- Flutter app
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`
- PC bridge
  - `npm.cmd ci`
  - `npm.cmd run check`
  - `npm.cmd test`
  - `npm.cmd audit --audit-level=high`
- Firebase Functions / Firestore Rules
  - `npm.cmd ci`
  - `npm.cmd run check`
  - `npm.cmd run build`
  - `npm.cmd run test:functions`
  - `npm.cmd audit --audit-level=high`
  - `npm.cmd run test:rules`
- Release readiness
  - `app/pubspec.yaml` の `versionName+versionCode` を検査する。
  - `docs/release-runbook.md` が存在することを検査する。
  - `v*` tagまたは手動指定tagでは、tagが `v<versionName>` と一致することを検査する。
  - tag検査時は `docs/releases/<versionName>.md` が存在し、versionName/versionCodeを含むことも検査する。
- Tracked files secret scan
  - `scripts/scan-secrets.ps1` でtracked filesに秘密情報らしい文字列が含まれていないことを検査する。

## 秘密情報の扱い

CIではRelease署名、実Firebase projectへのdeploy、実Firebase E2E、FCM実送信を行わない。次のファイルや値はGitHub Actionsへ渡さない。

- `app/android/key.properties`
- keystore / JKS / p12
- Firebase service account JSON
- `pc-bridge/config.local.json`
- `.env`

Release署名と実機E2Eは [Release runbook](release-runbook.md) と [Release E2E smoke runbook](release-e2e-smoke.md) に従ってローカルで実施する。
