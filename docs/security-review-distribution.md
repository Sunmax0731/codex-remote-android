# 配布前セキュリティレビュー

実施日: 2026-04-27
対象Issue: #129

## レビュー対象

- Android APK配布に関係する固定設定
- PCブリッジ設定ファイルとログ
- Firebase setup QR payload
- Firebase Functions通知payload
- Git管理対象と `.gitignore`
- 利用者向けドキュメント

## 結論

配布物へ含めてはいけないローカル設定、service account JSON、Firebase debug log、PCブリッジログ、署名鍵、APK生成物は `.gitignore` で除外されている。

追加対応として、Codex CLIの標準出力/標準エラー由来の `progressText` と `errorText`、および通知本文プレビューに対して、代表的な秘密情報パターンのredactionを追加した。

## 確認結果

### Git管理外にするファイル

次のファイル種別は `.gitignore` で除外されている。

- `*.apk`
- `*.aab`
- `*.keystore`
- `key.properties`
- `local.properties`
- `app/android/app/google-services.json`
- `firebase/serviceAccount*.json`
- `firebase/firebase-debug.log`
- `.env`
- `.env.*`
- `pc-bridge/config.local.json`
- `pc-bridge/*.local.json`
- `pc-bridge/.local/`
- `pc-bridge/logs/`

ローカル環境には `pc-bridge/config.local.json`、`pc-bridge/logs/`、`firebase/firebase-debug.log`、`app/android/app/google-services.json` が存在するが、Git管理対象には含まれていない。

### QR payload

Firebase setup QRは `google-services.json` から次のクライアント設定だけを抽出する。

- `projectId`
- `apiKey`
- `appId`
- `messagingSenderId`
- `storageBucket`

QR payloadには次を含めない。

- service account JSON
- private key
- Admin SDK credential
- PCブリッジのローカル設定
- Codex / GitHub / OpenAI など外部サービスのtoken

### PCブリッジ設定

`pc-bridge/config.example.json` の既定値は次の方針に合っている。

- `relayMode`: `local`
- `codexMode`: `stub`
- `codexBypassSandbox`: `false`
- `serviceAccountPath`: ダミーのローカルパス
- `ownerUserId`: 空文字

利用者は `config.local.json` を作成して自分の環境値を設定する。`config.local.json` はGit管理外である。

### Codex CLI出力の扱い

PCブリッジはCodex CLIの実行中にstdout/stderrの末尾を `progressText` に保存し、失敗時にstderr/stdoutを `errorText` に保存する。

配布前の追加対応として、保存前に次のパターンをredactする。

- PEM private key block
- JSON `private_key`
- JSON `client_secret`
- JSON `refresh_token`
- JSON `access_token`
- Firebase API key形式
- Google access token形式
- GitHub token形式
- Slack token形式

### 通知本文

Cloud Functionsは完了通知本文に `resultText` または `errorText` の短いプレビューを使う。

配布前の追加対応として、通知本文プレビューにも同じredactionを適用した。

## 残るリスク

- Codexの最終結果 `resultText` 自体には、ユーザーが指示した内容やCodexが生成した内容が保存される。これは機能要件上必要だが、利用者には「秘密情報を指示や結果に含めない」注意が必要。
- Firebase API keyはFirebase client configの一部であり、QR payloadに含める必要がある。private keyやAdmin SDK credentialとは扱いが異なるが、公開ログやIssueには貼らない運用を推奨する。
- スクリーンショット手順を追加する際は、Firebase project ID、UID、メールアドレス、token、service account情報をマスクする必要がある。

## 配布前チェックリスト

- [x] `config.local.json` がGit管理外である。
- [x] service account JSONがGit管理外である。
- [x] Firebase debug logがGit管理外である。
- [x] PCブリッジログがGit管理外である。
- [x] APK、AAB、署名鍵がGit管理外である。
- [x] QR payloadにservice account JSONやprivate keyを含めない。
- [x] Codex CLI由来のprogress/error保存にredactionを適用する。
- [x] 通知本文プレビューにredactionを適用する。
- [x] 配布ドキュメントにservice account JSONを共有しない注意がある。

## 関連Issue

- #124 release APK作成手順と署名方針を整備する
- #125 利用者向けクイックスタートを整備する
- #126 PCブリッジ配布パッケージを整備する
- #127 Firebaseセットアップ手順にスクリーンショットを追加する
- #128 配布利用者向けトラブルシュート集を整備する
