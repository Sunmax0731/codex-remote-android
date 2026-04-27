# QCDS強化計画

## 目的

Codex Remote Android v1.0.2以降を、QCDSの各観点でS評価に近づけるための要件、設計方針、仕様、Issue対応関係を定義する。

評価軸は次の5段階を使う。必要に応じて `+` / `-` を補助評価として付ける。

| 評価 | 意味 |
| --- | --- |
| S | 配布・運用・変更に対して高い再現性、自動検証、安全性がある |
| A | 主要導線は安定し、手順や証跡も揃っている |
| B | MVPとして動作するが、手動確認や属人作業が残る |
| C | 限定環境では動くが、配布や保守に大きな不確実性がある |
| D | 目的達成に必要な基礎機能や安全性が不足している |

## スコープ

- 対象はスマホアプリ、PCブリッジ、Firebase構成、セットアップWeb UI、Release/運用ドキュメントである。
- 利用者自身のFirebaseプロジェクトを使う自前Firebase方式に絞る。ホスト済みサービス方式は採用しない。
- 利用者が参照する画面は、PCブリッジに同梱するローカルセットアップWeb UIへ統一する。GitHub Pagesでの静的公開は採用しない。
- #104 のセッション途中の画像・ファイル添付は一旦保留し、QCDS強化後に再開判断する。

## 要件

### Quality

| ID | 要件 | Issue |
| --- | --- | --- |
| QFR-001 | Flutter側の主要画面にwidget test / golden testを追加し、UI退行を検出できるようにする | #152 |
| QFR-002 | QRセットアップ、通知、セッション削除、グループ、検索、お気に入りなどAndroid主要導線に回帰テストを置く | #156 |
| QFR-003 | PCブリッジのclaim、timeout、失敗時redactionを自動テスト化する | #153 |
| QFR-004 | Firebase Functions / Firestore Rulesの代表ケースをEmulatorでテストする | #154 |
| QFR-005 | 実機E2Eスモークを手順化し、可能な部分を半自動化する | #155 |
| QFR-006 | クラッシュログと診断ログ収集手順を整備し、秘密情報を含めずに報告できるようにする | #157 |

### Cost

| ID | 要件 | Issue |
| --- | --- | --- |
| CFR-001 | Firebase設定コスト削減案を比較し、自前Firebase方式の範囲で実装方針を決める | #158 |
| CFR-002 | セットアップWeb UIに設定チェックと `config.local.json` 生成補助を追加する | #159 |
| CFR-003 | PCブリッジの常駐化、起動確認、ログ確認をセットアップWeb UIへ統合する | #160 |
| CFR-004 | Firebase利用量、無料枠、課金注意点をREADME、利用者手順、セットアップWeb UIへ明記する | #161 |

### Delivery

| ID | 要件 | Issue |
| --- | --- | --- |
| DFR-001 | Release作業をRunbook化し、artifact生成と事前チェックを可能な範囲で自動化する | #162 |
| DFR-002 | CIでbuild、test、audit、Release前チェックを実行する | #163 |

### Security

| ID | 要件 | Issue |
| --- | --- | --- |
| SFR-001 | Publicリポジトリ向けの継続監査と依存関係監視を整備する | #164 |
| SFR-002 | 署名鍵、Firebase credential、秘密情報漏えい時の対応Runbookを整備する | #165 |
| SFR-003 | Firebase service accountの最小権限化方針を検討し、推奨運用を文書化する | #166 |

## 設計方針

### セットアップ体験

セットアップ導線はPCブリッジ同梱のローカルWeb UIへ集約する。利用者はローカルで画面を開き、Firebase Console / Google Cloud Consoleの手順確認、JSON確認、QR生成、PCブリッジ設定確認を同じ画面で行う。

GitHub Pagesのような静的公開は、画面が分散し、PCブリッジのローカルAPIと統合しにくいため採用しない。今後も利用者に案内する主要画面はローカルセットアップWeb UIとする。

ブラウザのDrag and Dropだけでは、利用者環境の絶対パスを安全かつ確実に取得できない場合がある。そのため `config.local.json` 生成補助は、次のいずれか、または組み合わせで設計する。

- パス手入力とローカルAPIによる存在確認。
- service account JSONを `.local` 配下へ安全にコピーし、そのコピー先を設定へ使う。
- PowerShell helperでファイル選択を行い、ローカルAPIへ渡す。

### QR payload境界

Androidセットアップ用QRにはFirebaseクライアント設定だけを含める。

含めてよい情報:

- `schema`
- `projectId`
- `apiKey`
- `appId`
- `messagingSenderId`
- `storageBucket`

含めない情報:

- service account JSON
- private key
- Firebase Admin SDK credential
- PCブリッジのローカルtoken
- `config.local.json` 全文

### PCブリッジ運用境界

PCブリッジの状態確認、起動補助、ログ表示は、ブラウザから直接OS操作させず、Node.js側のローカルAPIで必要最小限の操作だけを提供する。

ログ表示では、service account、private key、token、UID、API keyらしい値をredactする。UIには実行状態、設定検証結果、直近エラー分類を表示し、秘密情報の原文は表示しない。

### テストレイヤー

| レイヤー | 対象 | 目的 |
| --- | --- | --- |
| Flutter widget/golden | Android主要画面、状態表示、テーマ、言語 | UI退行検出 |
| Android回帰 | QR、通知遷移、削除、グループ、検索、お気に入り | 主要導線の退行検出 |
| PCブリッジ単体 | claim、timeout、redaction、failure | 中核処理の退行検出 |
| Firebase Emulator | Rules、Functions、通知payload | 権限境界とクラウド処理の退行検出 |
| 実機E2E | APK、Firebase、PCブリッジ、通知 | Release前の現実環境確認 |
| CI | build、test、audit、secret scan | 変更ごとの品質維持 |

## 仕様

### セットアップWeb UI設定チェック

セットアップWeb UIは、少なくとも次を確認する。

- `google-services.json` の必須フィールドが存在する。
- Android package name が `com.sunmax.remotecodex` と一致する。
- QRに含める値と含めない値を利用者が確認できる。
- service account JSONがAdmin SDK credentialらしい形であることを確認できる。ただしQRには含めない。
- `config.local.json` の不足項目を検出できる。
- 生成または表示する設定値は、秘密情報を過剰に表示しない。

### 診断ログ収集

利用者から収集してよい情報:

- アプリversion、build number、Android OS version。
- マスク済みFirebase project ID。
- 通知権限状態。
- PCブリッジversion、Node.js version。
- `config.local.json` の検証結果。
- Codex CLI検出状態。
- redaction済みのPCブリッジログ。
- Firebase Functions logsの該当時刻とredaction済み抜粋。

収集してはいけない情報:

- service account JSON全文。
- private key。
- Firebase Admin credential。
- 署名鍵、keystore、`key.properties`。
- FCM token全文。
- UID全文。
- access token、refresh token。
- 非公開コード全文。

### Release前チェック

Release前には次を確認する。

- Flutter analyze / test が成功する。
- PCブリッジのTypeScript check / test が成功する。
- Firebase Functionsのbuild / test が成功する。
- 依存関係auditでhigh/criticalを見落としていない。
- Release artifactに秘密情報が含まれていない。
- APKのversionName/versionCode、Git tag、Release noteが一致している。
- PCブリッジzipの内容とSHA256を確認している。
- 実機E2Eスモークの証跡が残っている。

## Issueトレーサビリティ

| Issue | 対応要件 | 主な更新先 |
| --- | --- | --- |
| #152 | QFR-001 | `app/test/`, `docs/development-setup.md` |
| #153 | QFR-003 | `pc-bridge/`, `pc-bridge/README.md` |
| #154 | QFR-004 | `firebase/`, `firebase/README.md` |
| #155 | QFR-005 | `docs/release-plan.md`, `docs/release-apk.md` |
| #156 | QFR-002 | `app/test/`, `docs/development-setup.md` |
| #157 | QFR-006 | `docs/troubleshooting-distribution.md`, Issue templates |
| #158 | CFR-001 | `docs/qcds-hardening-plan.md`, setup Web UI backlog |
| #159 | CFR-002 | `pc-bridge/setup-web/`, `docs/user-quickstart.md` |
| #160 | CFR-003 | `pc-bridge/setup-web/`, `pc-bridge/scripts/` |
| #161 | CFR-004 | `README.md`, `docs/user-quickstart.md`, setup Web UI |
| #162 | DFR-001 | `docs/release-plan.md`, release scripts |
| #163 | DFR-002 | `.github/workflows/`, `docs/development-setup.md` |
| #164 | SFR-001 | `.github/dependabot.yml`, CI, `docs/security-review-distribution.md` |
| #165 | SFR-002 | `docs/security-review-distribution.md`, `docs/release-apk.md` |
| #166 | SFR-003 | `docs/security-review-distribution.md`, `firebase/README.md` |
| #167 | 全体管理 | 本計画書 |
