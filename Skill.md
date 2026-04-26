# Skill

Codex Remote Android プロジェクトを進めるときは、このSkillを使う。

このプロジェクトでは、GitHub Issue を作業単位とし、Issueごとにブランチを切り、実装・検証・ドキュメント更新・Issueクローズまでを一連の完了条件として扱う。

## Operating Mode

1. `gh issue list` で現在のIssue状態を確認する。
2. ユーザーの依頼が既存Issueで扱えるか判断する。
3. 既存Issueで扱えない場合は、新しいIssueを作成してスコープと完了条件を記録する。
4. 親Issueが大きい工程の場合は、着手時に実作業サイズのサブIssueを作る。
5. 作業対象Issueを1つ選び、そのIssueを作業契約として読む。
6. `process/<phase>/Agents.md` と `process/<phase>/Skill.md` を読む。
7. Issue用ブランチを作成または切り替える。
8. 実装、ドキュメント、検証をIssue範囲に絞って進める。
9. 変更を検証し、結果をIssueコメントまたは完了コメントに残す。
10. コミットしてpushする。
11. `main` へ統合した後、Issueを閉じる。

## Issue and Branch Procedure

### 1. Issue確認

```powershell
gh issue list --state open --limit 50
gh issue view <issue-number>
```

- Releaseまでの親Issueは工程管理用として扱う。
- 詳細タスクは工程に着手するタイミングで作る。
- 1回の作業では、原則1つのサブIssueだけを完了させる。

### 2. ブランチ作成

```powershell
git status --short --branch
git switch main
git pull --ff-only
git switch -c <type>/<issue-number>-<short-scope>
```

推奨ブランチ名:

- `docs/<issue-number>-<scope>`: ドキュメント中心
- `feature/<issue-number>-<scope>`: 機能追加
- `fix/<issue-number>-<scope>`: 不具合修正
- `release/<issue-number>-<scope>`: Release準備

### 3. 作業

- 先に関連ドキュメントを読む。
- 実装だけで完了にしない。必要なドキュメントも同じIssue内で更新する。
- スコープが広がる場合は、作業を増やす前にIssueを更新するか、別Issueへ分ける。
- セキュリティ、認証、通知、PCブリッジ実行境界に関わる変更は、設計ドキュメントへ必ず反映する。

### 4. 検証

Issueの種類に応じて、最小十分な検証を行う。

- ドキュメントのみ: Markdownの整合、リンク、関連索引の確認
- Flutter: `flutter analyze`、`flutter test`、必要に応じて実機またはエミュレータ確認
- PCブリッジ: ユニットテスト、ローカル実行、Firebase接続の安全な確認
- Firebase/通知: Emulatorまたは検証用Firebaseプロジェクトでのルール・Functions・FCM確認
- Release: APKビルド、Xperia 1 IIIへのインストール、E2Eスモーク

Flutter SDKなどのローカルツールが未導入の場合は、失敗を隠さずIssueまたは最終報告に残す。

### 5. コミット、push、統合

```powershell
git diff --check
git status --short
git add <files>
git commit -m "<message>"
git push -u origin <branch>
```

小さなドキュメント修正や単独作業では、検証後に `main` へfast-forward統合してpushしてよい。PRが必要な作業では、ドラフトPRを作成し、レビューまたはユーザー確認後に統合する。

Issueを閉じるのは、変更がリモートへ反映され、検証結果が説明できる状態になってからにする。

## Documentation Policy

- 標準言語は日本語。
- コード、識別子、CLI、API名、設定キー、ファイル名は英語のまま記述する。
- 既存の英語ドキュメントは、触る範囲から日本語へ更新する。
- 大きな翻訳や構成変更は、実装Issueに混ぜず別Issueにする。
- Issue本文、Issueコメント、Releaseノートも原則日本語で書く。
- Windows PowerShellから日本語の長文をGitHubへ投稿した場合は、投稿後に読み戻して文字化けを確認する。

## Documentation Ownership

- `docs/requirements.md`: ユーザー価値、MVP範囲、受入条件、非機能要件
- `docs/architecture.md`: システム構成、通信方式、データモデル、セキュリティ境界
- `docs/release-plan.md`: Release条件、APK配布、実機インストール、検証証跡
- `process/`: 工程別の担当、手順、検証観点
- `README.md`: プロジェクト概要、現在の進め方、主要ドキュメントへの入口

新しいドキュメントを追加したら、関連する入口文書も更新する。

## Product Constraints

- Android app target: Xperia 1 III.
- Mobile network support is required; do not rely on LAN-only discovery for core workflows.
- PC is normally powered on.
- VS Code is normally running for MVP.
- Later design may include a PC-side service that starts VS Code.
- Intermediate Codex progress is not required in the app.
- Completion must trigger a push notification.
- MVP assumes one user, one primary PC bridge, and one fixed workspace.

## Preferred MVP Stack

- Flutter for Android UI.
- Firebase Authentication or Firebase-supported single-user pairing for identity.
- Cloud Firestore for sessions, commands, and final results.
- Firebase Cloud Messaging for completion notification.
- PC bridge implemented as a small companion process first, with optional VS Code extension integration later.

## Completion Checklist

Before finishing an Issue:

- The active Issue number is clear.
- Work was done on an Issue branch.
- Scope matches the Issue body and comments.
- Relevant docs are updated.
- Validation was run, or the reason it could not run is recorded.
- Changes are committed and pushed.
- `main` is updated when integration is part of the requested boundary.
- The Issue is updated or closed with evidence.
