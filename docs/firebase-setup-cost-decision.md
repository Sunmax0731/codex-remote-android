# Firebase設定コスト削減方針

対象Issue: #158

## 決定

Codex Remote Androidは、利用者自身のFirebaseプロジェクトを使う自前Firebase方式に絞る。ホスト済みサービス方式は採用しない。

初期実装の優先順は次の通り。

1. セットアップWeb UIのウィザード強化と設定チェックを先に実装する。
2. ローカル設定生成アシスタントを同じ流れに統合し、`config.local.json` 生成補助まで進める。
3. Firebase CLI補助スクリプトは、Web UIで検出しにくいdeploy手順を補う二段目として扱う。

## 比較

| 候補 | 実装コスト | 利用者負担 | セキュリティリスク | 判断 |
| --- | --- | --- | --- | --- |
| A. セットアップWeb UIのウィザード強化 | 中 | 低 | 低 | 最優先。既存UIに合流でき、秘密情報をQRへ入れない境界を維持しやすい。 |
| B. Firebase CLI補助スクリプト | 中-高 | 中 | 中 | 後続。`firebase login`、CLI導入、project選択が前提で、誤project deployの注意が必要。 |
| C. ローカル設定生成アシスタント | 中 | 低-中 | 中 | Aに続けて実装。service account JSONの扱いをUIとローカルAPIで強く制限する必要がある。 |

## 採用する初期スコープ

Issue #159 で扱う。

- `google-services.json` の必須項目とpackage name `com.sunmax.remotecodex` の一致を検証する。
- QR payloadに含める項目と含めない項目をUI上で明示する。
- service account JSONはAdmin SDK credentialらしい形だけを検証し、QR payloadには含めない。
- `config.local.json` の雛形を生成する。
- service account pathは、まず手入力とローカルAPIでの存在確認を優先する。
- ブラウザDrag and Dropだけで絶対パスを取得できる前提にはしない。

## 後続スコープ

Issue #160 で扱う。

- PCブリッジの起動状態確認。
- 常駐化導線。
- redaction済みログ確認。
- 起動失敗分類。

Issue #161 で扱う。

- Firestore read/write、Cloud Functions invocation、FCM、Cloud Loggingの費用注意。
- Blazeプランが必要になる理由。
- 予算アラート設定。
- README、利用者クイックスタート、セットアップWeb UIへの短い注意表示。

Firebase CLI補助は、#159 と #160 の結果を見て別Issueまたは #162 のRunbook自動化へ寄せる。初期段階では、Web UIからCLIを直接実行する設計にはしない。

## 非採用

ホスト済みサービス方式は採用しない。

理由:

- 利用者のコマンド、結果、通知metadataを第三者運用の共有クラウドへ集める設計になる。
- 課金、監査、障害対応、データ削除、利用規約、サポート責任が大きく変わる。
- 現在のMVP方針である「単一利用者、自分のFirebase、自分のPCブリッジ」と矛盾する。
- Public配布の短期改善としては、セットアップ補助の強化の方が安全で効果が高い。

## セキュリティ境界

- QR payloadにはservice account JSON、private key、Admin SDK credential、PCブリッジ設定、ローカルパスを含めない。
- `config.local.json` 生成補助では、秘密値を過剰表示しない。
- service account JSONはPCローカルに置き、GitHub Issue、ログ、スクリーンショットへ貼らない。
- セットアップWeb UIにローカルAPIを追加する場合、OS操作は必要最小限に限定する。
