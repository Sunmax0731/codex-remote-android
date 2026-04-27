# Firebase cost guide

Codex Remote Androidは、利用者自身のFirebase/GCPプロジェクトを使う。ホスト済みサービス方式は採用しないため、課金設定、予算アラート、利用量監視は利用者のプロジェクトで行う。

Firebaseの料金と無料枠は変更される可能性がある。正確な金額と最新条件は、必ず公式ページを確認する。

- Firebase pricing: <https://firebase.google.com/pricing>
- Firebase pricing plans: <https://firebase.google.com/docs/projects/billing/firebase-pricing-plans>
- Google Cloud Budgets & alerts: <https://docs.cloud.google.com/billing/docs/how-to/budgets>

## このアプリで使う主なリソース

| リソース | 使う場面 | 増えやすい操作 |
| --- | --- | --- |
| Firebase Authentication | Androidアプリの匿名UID作成 | 端末再インストール、複数端末利用 |
| Cloud Firestore | セッション、コマンド、PCブリッジ状態、端末token、health check | セッション一覧表示、command送信、watcher polling、heartbeat |
| Cloud Functions | command完了/失敗時のFCM通知 | command完了回数 |
| Firebase Cloud Messaging | Androidへの完了通知 | command完了通知 |
| Cloud Logging | Functionsログ、デプロイ/運用ログ | Functionsエラー、debugログ増加 |
| Artifact Registry / Cloud Build / Cloud Run / Eventarc等 | Functions初回デプロイ時に有効化される場合がある周辺サービス | Functions deploy、Functions実行基盤 |

## 少人数利用の目安

個人または少人数で、1日に数十件程度のセッション/コマンドを扱う想定では、Firestore read/writeとFunctions invocationは小さくなりやすい。ただし、次の条件では増えやすい。

- PCブリッジの `pollIntervalSeconds` を短くしすぎる。
- セッション一覧を頻繁に開き直す。
- 複数端末で同じFirebaseプロジェクトを共有する。
- コマンドを大量に送る、または短い間隔で自動送信する。
- Functionsで通知失敗が続き、ログが増える。

## 無料枠とBlazeプラン

Firebase公式ドキュメントでは、Sparkプランは支払い方法なしで始められ、Firestoreなど一部の有料対象プロダクトにも無料枠がある。一方、Cloud Functionsや追加のGoogle Cloudサービスを使うにはBlazeプランが必要になる。

このアプリは完了通知にCloud Functionsを使うため、Release相当のFirebase構成ではBlazeプランが必要になる。Blazeは従量課金で、無料枠を超えた分や関連Google Cloudサービスの利用に課金が発生し得る。

公式例では、Cloud Firestoreは1日あたり50,000 document readsと20,000 document writesが無料枠として説明されている。数値や対象サービスは変更される可能性があるため、運用前にFirebase pricingを確認する。

## コストを抑える運用

- このアプリ専用のFirebase/GCPプロジェクトを作る。
- Google Cloud Consoleで予算と予算アラートを設定する。
- `pollIntervalSeconds` は必要以上に短くしない。通常は既定値の5秒から始める。
- 使わない検証プロジェクト、Functions、service account keyは削除する。
- FunctionsログやCloud Loggingを定期的に確認する。
- Firestoreに保存するcommand本文と結果は必要最小限にする。
- 大量送信や自動連投は避ける。

## 予算アラート

Google CloudのBudgets & alertsは、BillingのCost managementから作成できる。単一プロジェクトだけを対象にした予算を作る場合は、対象Firebase/GCPプロジェクトを選択してからBillingへ進む。

推奨:

- 初回セットアップ直後に月額の小さな予算を設定する。
- 50%、90%、100%など複数しきい値でメール通知を受ける。
- Firebase/GCPプロジェクトを複数使う場合は、プロジェクト単位で予算スコープを確認する。

予算アラートは通知であり、必ずしも利用を自動停止する仕組みではない。予期しない増加に気づくための安全策として扱う。
