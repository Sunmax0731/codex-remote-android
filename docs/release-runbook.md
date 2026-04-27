# Release runbook

このRunbookはCodex Remote AndroidのRelease作業チェックリストである。署名鍵、`key.properties`、service account JSON、`config.local.json`、ログ、Firebase debug fileはローカル管理のままとし、GitHub Releaseへ添付しない。

## 前提条件

- `app/pubspec.yaml` がRelease対象の `versionName+versionCode` になっている。
- `versionCode` が前回配布したAndroid buildより大きい。
- `app/android/key.properties` がローカルに存在し、Release署名鍵を指している。
- `app/android/app/google-services.json` がRelease対象Firebase projectのものになっている。
- `pc-bridge/config.local.json` はローカル検証専用で、Git管理外のままになっている。
- このPCからGitHub Releaseを作成する場合は `gh auth status` が成功する。

## パッケージ前検証

artifactを作成する前に主要チェックを実行する。

PRとRelease前の自動チェックは [CI](ci.md) に記録している。Release署名と実Firebase E2EはローカルRunbookの対象とし、CIには署名鍵やservice account JSONを渡さない。

Public repository向けの継続監査と秘密情報スキャンは [Public repository continuous security audit](security-continuous-audit.md) に記録している。

署名鍵、Firebase service account JSON、その他秘密情報の紛失・漏えい時対応は [Credential incident runbook](credential-incident-runbook.md) に従う。

```powershell
Set-Location app
flutter test
flutter analyze

Set-Location ..\pc-bridge
npm.cmd run check
npm.cmd test
```

## artifact作成

repository rootからRelease helperを実行する。

```powershell
.\scripts\prepare-release.ps1 -PreviousVersionCode <previousVersionCode>
```

既存のAPKとPCブリッジzipを使ってdry runする場合:

```powershell
.\scripts\prepare-release.ps1 -SkipApkBuild -SkipPcBridgePackage
```

helperは次の処理を行う。

- `app/pubspec.yaml` のversion解析。
- 任意指定した前回 `versionCode` との比較。
- skipしない場合のrelease APK build。
- `apksigner verify --verbose`。
- `aapt dump badging` によるpackage/version確認。
- skipしない場合のPCブリッジzip作成。
- PCブリッジzipにローカル専用ファイルや秘密情報らしいファイルが含まれていないことの検査。
- `SHA256SUMS.txt` 生成。
- Release note雛形生成。

出力先:

```text
.local/release/<versionName>/
```

期待されるartifact:

- `RemoteCodex-<versionName>.apk`
- `codex-remote-pc-bridge-<versionName>.zip`
- `SHA256SUMS.txt`
- `release-notes-<versionName>.md`

## E2E smoke

実機へAPKをインストールした後、Release E2E smokeを実行する。

```powershell
.\scripts\run-android-e2e-smoke.ps1 `
  -Install `
  -ApkPath .\.local\release\<versionName>\RemoteCodex-<versionName>.apk `
  -EvidencePath .\.local\release\<versionName>\e2e-smoke.json
```

続けて [Release E2E smoke runbook](release-e2e-smoke.md) に従い、次を記録する。

- device modelとAndroid version
- app `versionName/versionCode`
- PC bridge heartbeatとhealth check response
- session IDとcommand ID
- completed command status
- 画像添付commandと汎用ファイル添付commandのcompleted status
- 添付の制限値確認: 5 files以内、1 file 25 MiB以内、未許可type拒否
- notification success count

## GitHub Release前チェック

GitHub Releaseを作成する前にartifact directoryを確認する。

```powershell
Get-ChildItem .\.local\release\<versionName>
Get-Content .\.local\release\<versionName>\SHA256SUMS.txt
```

次はアップロードしない。

- `key.properties`
- `*.jks`, `*.keystore`, `*.p12`
- `serviceAccount*.json`
- `config.local.json`
- `google-services.json`
- `.env`
- logsまたはFirebase debug logs
- redactしていないdiagnostic output

## GitHub Release作成

生成されたRelease noteを本文のベースにし、E2E evidenceと既知の制限を追記する。

```powershell
gh release create v<versionName> `
  .\.local\release\<versionName>\RemoteCodex-<versionName>.apk `
  .\.local\release\<versionName>\codex-remote-pc-bridge-<versionName>.zip `
  .\.local\release\<versionName>\SHA256SUMS.txt `
  --title "Codex Remote Android <versionName>" `
  --notes-file .\.local\release\<versionName>\release-notes-<versionName>.md
```

公開後に次を確認する。

- GitHub Release pageを開ける。
- artifact名がRelease noteと一致する。
- SHA256値がローカルファイルと一致する。
- ローカル専用設定や秘密情報がアップロードされていない。

## 文書化

Release完了後、`docs/releases/<versionName>.md` にRelease evidenceを追加する。生成したRelease noteの要約、検証コマンド、E2E smoke結果、artifact hash、既知の制限、GitHub Releaseへのリンクを含める。
