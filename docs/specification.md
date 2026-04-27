# 仕様書

## 対象

この仕様書は、Codex Remote Android v1.0.2時点の主要仕様と、QCDS強化Issueで追加する予定仕様をまとめる。

詳細な要件は [要件定義](requirements.md)、構成と責務は [アーキテクチャ](architecture.md)、QCDS改善の追跡は [QCDS強化計画](qcds-hardening-plan.md) を正とする。

## 現行仕様

### スマホアプリ

- AndroidアプリはFirebase runtime設定を端末内に保存し、保存済み設定からFirebaseを初期化する。
- 初回セットアップでは、PC側セットアップWeb UIで生成したQRコードを読み取り、Firebaseクライアント設定フォームへ反映する。
- AndroidアプリはFirebase Admin credential、service account JSON、private keyを保存しない。
- セッション一覧、詳細、drawer、PC接続表示、設定モーダルを提供する。
- セッション名変更、お気に入り、検索、グループ、未分類フィルタ、履歴削除を提供する。
- セッション表示中にセッション名やお気に入りを変更した場合、表示中の画面へ即時反映する。
- Androidのシステムテーマがダークテーマの場合、アプリもダークテーマへ追従する。

### PCブリッジ

- PCブリッジはFirestore上の `queued` commandを監視し、claim後にCodex CLIへ渡す。
- コマンド状態は `queued`、`running`、`completed`、`failed` を中心に管理する。
- PCブリッジは `config.local.json` とservice account JSONをローカルに保持し、Gitへ含めない。
- 常駐起動は既存の起動スクリプトまたはタスクスケジューラ登録を使う。

### Firebase

- Firebase AuthenticationはAnonymous Authを使う。
- Firestoreはユーザー単位のsessions、commands、devices、pcBridgesを保存する。
- Cloud Functionsは完了通知をFCMへ送信する。
- Firestore Rulesは他ユーザーのデータへアクセスできないことを前提に設計する。

### セットアップWeb UI

- セットアップWeb UIはPCブリッジに同梱し、利用者がローカルで起動する。
- Firebase Console / Google Cloud Consoleへのリンク、作業手順、固定アプリ名 `RemoteCodex`、固定package name `com.sunmax.remotecodex` を表示する。
- `google-services.json` からAndroid向けFirebaseクライアント設定を抽出し、QRコードを生成する。
- service account JSONはPCブリッジ用のローカル設定でのみ使い、QRには含めない。
- GitHub Pagesなどの静的公開は採用しない。利用者向けの主要セットアップ画面はローカルセットアップWeb UIに統一する。

## 追加予定仕様

### Quality仕様

- Flutter widget testでセッション一覧、詳細、drawer、PC接続表示、Firebase setup画面の主要状態を検証する。
- golden testは安定して比較できる静的画面から導入し、不安定な場合はwidget testへ置き換える。
- PCブリッジはclaim、timeout、failure、redactionの自動テストを持つ。
- Firebase Functions / Firestore RulesはEmulatorで代表的な許可・拒否ケースを検証する。
- 実機E2Eスモークは手順書と証跡テンプレートを持つ。
- 利用者からの診断ログはredaction済みだけを扱う。

### Cost仕様

- セットアップWeb UIは `google-services.json` の必須フィールドとpackage name一致を確認する。
- セットアップWeb UIはservice account JSONがAdmin SDK credentialらしい形かを確認する。ただし秘密値をQRへ含めない。
- セットアップWeb UIは `config.local.json` の雛形生成または不足項目確認を支援する。
- PCブリッジの起動状態、常駐化、ログ確認は、別ツールを増やさずセットアップWeb UIへ統合する。
- Firebase利用量、無料枠、課金注意点をREADME、利用者手順、セットアップWeb UIから確認できるようにする。

### Delivery仕様

- Release作業はRunbookに従い、APK、PCブリッジzip、SHA256、Release noteの整合を確認する。
- CIは署名鍵やservice account JSONなしで実行できる範囲のbuild、test、auditを担う。
- Release前の実Firebase E2EはローカルRunbookで確認し、証跡を残す。

### Security仕様

- PublicリポジトリではDependabot、audit、secret scan相当の継続監査を行う。
- 署名鍵、`key.properties`、service account JSON、Firebase credentialはGitHubへ公開しない。
- 秘密情報漏えい時は、該当keyの無効化、再発行、Release差し替え、影響範囲確認をRunbookに従って行う。
- Firebase service accountは最小権限化を検討し、MVPで複雑になりすぎる場合は推奨運用と注意喚起を文書化する。

## 関連Issue

- #152 Flutter widget/golden regression testsを拡充する。
- #153 PCブリッジのclaim/timeout/redaction自動テストを追加する。
- #154 Firebase Functions / Firestore Rules のテストを追加する。
- #155 実機E2Eスモークを手順化・半自動化する。
- #156 Android主要導線の回帰テストを追加する。
- #157 クラッシュログと診断ログ収集手順を整備する。
- #158 Firebase設定コスト削減案を比較し実装方針を決める。
- #159 セットアップWeb UIに設定チェックとconfig.local.json生成補助を追加する。
- #160 PCブリッジの常駐化・起動確認・ログ確認をセットアップWeb UIへ統合する。
- #161 Firebase利用量の目安・無料枠・課金注意点を明記する。
- #162 Release作業を自動化しRunbookを整備する。
- #163 CIでbuild/test/audit/release前チェックを実行する。
- #164 Publicリポジトリ向けの継続監査と依存関係監視を整備する。
- #165 署名鍵・Firebase credential・秘密情報インシデント対応Runbookを整備する。
- #166 Firebase service accountの最小権限化方針を検討する。
- #167 QCDS改善ロードマップを管理する。
