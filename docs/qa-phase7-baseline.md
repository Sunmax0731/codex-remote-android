# Phase 7 QAベースライン

実施日: 2026-04-27

対象ブランチ: `qa/95-baseline`

## 目的

Phase 7 End-to-end QAの開始時点で、Release前に必要な自動検証、debug APKビルド、実機インストール可否を確認し、手動確認が必要な項目をIssueへ切り出す。

## 自動検証結果

| 項目 | コマンド | 結果 |
| --- | --- | --- |
| Android analyze | `flutter analyze` (`app/`) | 成功 |
| Android widget test | `flutter test` (`app/`) | 成功、13 tests passed |
| PC bridge type check | `npm.cmd run check` (`pc-bridge/`) | 成功 |
| PC bridge local relay | `npm.cmd run validate:local` (`pc-bridge/`) | 成功 |
| Cloud Functions type check | `npm.cmd run check` (`firebase/functions/`) | 成功 |
| Cloud Functions build | `npm.cmd run build` (`firebase/functions/`) | 成功 |
| Android debug APK build | `flutter build apk --debug` (`app/`) | 成功 |

## 実機確認結果

`flutter devices` でXperia 1 III相当の実機を検出した。

```text
SO 51B (mobile) • 192.168.0.3:37329 • android-arm64 • Android 13 (API 33)
```

debug APKの実機インストールに成功した。

```powershell
flutter install -d 192.168.0.3:37329 --debug
```

## 監査結果

`npm audit --audit-level=high` は、PCブリッジとFirebase Functionsの両方で終了コード0だった。high以上は検出されていない。

ただし、low/moderateの警告は残っている。

- `pc-bridge`: 2 low / 8 moderate
- `firebase/functions`: 2 low / 9 moderate

`npm audit fix --force` は `firebase-admin@10.1.0` へのbreaking changeを示すため、即時force修正は行わない。Release前評価は #97 で扱う。

#97 の評価結果は [npm audit Release前評価](qa-npm-audit-review.md) に記録する。

## 切り出したIssue

- #96 Phase 7 手動E2E・通知・携帯回線確認を実施する
- #97 npm auditのlow/moderate脆弱性警告をRelease前に評価する

## 残るQA項目

次の項目は、この自動QAベースラインでは未実施。

- スマホ操作による実E2E確認。
- WiFiと携帯電話回線の両方での確認。
- 完了通知の受信と通知タップ遷移。
- 実機での日本語/英語/中国語/韓国語表示確認。
- Firebase実プロジェクトへのRules/Indexes/Functions再デプロイ確認。

これらは #96 で実施する。
