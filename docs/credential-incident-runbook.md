# Credential incident runbook

このRunbookは、Android署名鍵、`key.properties`、Firebase service account JSON、その他秘密情報の保管、復旧、漏えい時対応をまとめる。

## 保管ルール

### Android署名鍵

- keystore / JKS / p12 はrepository外のローカル安全領域に置く。
- `app/android/key.properties` はrepository内に作成してよいが、Git管理外のままにする。
- store password、key password、key alias、keystore pathは、GitHub、Issue、スクリーンショット、ログ、Release noteへ貼らない。
- keystore本体とpasswordは別経路でバックアップする。
- バックアップ先は、PC故障時に復旧でき、かつGit同期や公開クラウド共有へ自動混入しない場所にする。

Androidの更新モデルでは、既存アプリの更新には同じ署名鍵が必要である。Google Play App Signingを使わず自前署名APKを配布している場合、署名鍵を紛失すると同じpackage nameの更新APKを利用者へ配布し続けることができなくなる。別鍵で配布する場合は、利用者側で既存アプリのuninstallや別package nameへの移行が必要になる。

### Firebase service account JSON

- service account JSONはPCローカルだけで保管する。
- `pc-bridge/config.local.json` にはservice account JSONのローカルpathだけを書く。
- service account JSON本文、`private_key`、`client_email`、key IDはGitHub Issue、スクリーンショット、ログ、QR、Androidアプリ設定へ貼らない。
- 利用者自身のFirebase projectを使うため、共有されたservice account JSONをこちらで預からない。
- 不要になったservice account keyは削除し、必要なときだけ再発行する。
- PCブリッジ用service accountの推奨権限は [Firebase service account permissions](firebase-service-account-permissions.md) に従う。

## 貼ってはいけない情報

- keystore / JKS / p12 / upload key
- `key.properties`
- store password / key password / key alias
- Firebase service account JSON
- JSON `private_key`
- OAuth access token / refresh token
- GitHub token
- OpenAI / Codex / Slackなど外部サービスのtoken
- `pc-bridge/config.local.json` 全文
- Firebase project ID、UID、email addressを含む未マスクスクリーンショット
- 未redactのFirebase debug log、PC bridge log、diagnostic output

## 通常点検

Release前に次を実行する。

```powershell
.\scripts\scan-secrets.ps1
```

続けて [Release runbook](release-runbook.md) と [Public repository continuous security audit](security-continuous-audit.md) のRelease前確認を行う。

## 誤公開時の初動

1. 公開範囲を止める。
   - GitHub Release assetに含めた場合は、該当assetまたはReleaseを削除する。
   - Issue、PR comment、discussionに貼った場合は、本文を削除またはredactする。
   - screenshotに含めた場合は、画像を削除し、マスク済み画像だけを再投稿する。
2. 秘密情報を無効化する。
   - service account keyはGoogle Cloud IAMで該当keyを削除する。
   - GitHub tokenなど外部tokenは発行元でrevokeする。
   - Firebase client configのAPI keyが意図せず公開された場合は、必要に応じてAPI key制限、再発行、Firebase Security Rulesを確認する。
   - Android署名鍵が漏えいした場合は、その署名鍵で作ったAPKを信頼できないものとして扱い、配布停止、利用者告知、次回配布方針を決める。
3. 影響を確認する。
   - GitHub secret scanning alertsとDependabot alertsを確認する。
   - Google Cloud IAM audit logs、service account key usage、Firestore/Functions logsを確認する。
   - 影響したFirebase project、service account、Release artifact、端末配布経路を記録する。
4. 復旧する。
   - service account keyを再発行し、PCローカルの保存先を更新する。
   - `pc-bridge/config.local.json` のpathを必要に応じて更新する。
   - `npm.cmd run diagnose` やRelease E2E smokeでPCブリッジ接続を確認する。
   - GitHub Release assetを作り直す場合は、`scripts/prepare-release.ps1` で再生成し、SHA256SUMSも更新する。
5. 再発防止する。
   - `scripts/scan-secrets.ps1` とCI結果を確認する。
   - `.gitignore` に不足があれば追加する。
   - Issueやdocsに貼る診断情報のテンプレートを見直す。
   - 漏えいの原因と対応内容を、秘密情報を含めずにIssueへ記録する。

## service account key削除と再発行

Google Cloud Consoleまたは`gcloud`で、漏えいしたservice account keyを削除する。keyを削除すると、そのkey fileではGoogle APIへ認証できなくなる。

`gcloud`を使う場合の例:

```powershell
gcloud iam service-accounts keys list --iam-account <service-account-email>
gcloud iam service-accounts keys delete <key-id> --iam-account <service-account-email>
```

削除後、新しいkeyを作成し、PCローカルの安全な場所へ保存する。新しいJSON本文は共有せず、`config.local.json` にはpathだけを設定する。

## Android署名鍵の紛失・漏えい

### 紛失

- 同じ署名で更新APKを作れない。
- 既存利用者は同じpackage nameのまま通常更新できない。
- 対応案は、バックアップから復旧、Google Play App Signingを使っている場合はPlay Consoleの手順確認、または別package name/別配布として再配布することになる。

### 漏えい

- その鍵で署名されたAPKを第三者が作成できる可能性がある。
- 既存artifactの配布を止める。
- 利用者へ、信頼できるRelease URLとSHA256を案内する。
- 次回配布では、同一package nameを維持するか、別package nameへ移行するかを決める。

## 関連リンク

- Google Cloud: [Create and delete service account keys](https://cloud.google.com/iam/docs/keys-create-delete)
- Google Cloud: [Best practices for managing service account keys](https://docs.cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)
- Android Developers: [Sign your app](https://developer.android.com/guide/publishing/app-signing.html)
- GitHub Docs: [Working with secret scanning and push protection](https://docs.github.com/code-security/secret-scanning/working-with-secret-scanning-and-push-protection)
