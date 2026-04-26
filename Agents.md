# Agents

このリポジトリは、Androidアプリ、PCブリッジ、Firebaseリレーを段階的に作る Issue 駆動プロジェクトとして進める。

各工程には `process/<phase>/Agents.md` と `process/<phase>/Skill.md` があり、工程ごとの責任範囲と実行手順を定義する。全体ルールはこのファイルを優先する。

## Global Rules

- 実装や設計変更は、原則として GitHub Issue を起点にする。
- 新しい依頼が来たら、まず既存Issueで扱えるか確認し、必要なら新規Issueを作成または既存Issueを更新する。
- Issue は作業契約として扱う。作業中にスコープが変わった場合は、実装だけでなくIssue本文やコメントも更新する。
- セキュリティに関わる判断は曖昧にしない。
- MVPでは Firebase などのクラウドリレー通信を優先し、WiFiと携帯回線の両方で使える構成にする。
- Androidアプリ、PCブリッジ、Firebase/Cloud Functions は別々の成果物として扱い、境界と契約をドキュメントに残す。
- Androidアプリから任意のシェルコマンドを直接実行できる設計にしない。
- Release前には実機またはエミュレータで検証する。主ターゲット実機は Xperia 1 III とする。

## Documentation Language

- このリポジトリのドキュメント、GitHub Issue本文、Issueコメントは日本語を標準とする。
- コード識別子、API名、CLIコマンド、設定キー、外部サービス名、ファイル名は英語表記のまま扱う。
- 既存ドキュメントが英語で残っている場合、新規作業で触る範囲から日本語へ寄せる。大規模な翻訳だけを目的にした変更は、別Issueで扱う。
- ユーザーが英語指定した場合、または外部公開用の英文が必要な場合は、そのIssue内で言語方針を明記する。

## Branch Workflow

- `main` で直接作業しない。Issueごとに専用ブランチを作成する。
- ブランチ名は `docs/<issue-number>-<scope>`、`feature/<issue-number>-<scope>`、`fix/<issue-number>-<scope>`、`release/<issue-number>-<scope>` のいずれかを基本にする。
- 1つのブランチは原則1つのIssueに対応させる。
- 親IssueからサブIssueを切った場合、実装・検証はサブIssue単位のブランチで行う。
- 作業完了後は検証結果を確認し、コミット、push、必要に応じて `main` へ統合する。
- 統合後にIssueを閉じる。検証未完了や未pushの状態でIssueを閉じない。

## Issue Workflow

- 親Issueは工程や大きなマイルストーンを表す。
- 詳細タスクは、その工程に着手したタイミングでサブIssueとして作成する。
- サブIssueは実装・検証・ドキュメント更新まで含めて完了可能な粒度にする。
- 優先順位は現在の工程、依存関係、Releaseブロッカー度合いで判断する。
- 完了コメントには、変更内容、検証結果、コミットまたはブランチ、残課題を簡潔に残す。
- Windows PowerShell から日本語の長文Issue本文やコメントを投稿する場合は、投稿後に読み戻して文字化けがないことを確認する。

## Documentation Workflow

- 要件、設計、実装、検証、Releaseのいずれかを変えた場合、対応するドキュメントも同じIssue内で更新する。
- 実装が先に決まった場合でも、採用した挙動はドキュメントへ反映する。
- ドキュメントと実装が食い違う状態を残さない。すぐ直せない場合はIssueに残す。
- 要件IDは安易に振り直さない。追加が必要な場合は末尾に追加する。
- 新しいドキュメントを追加した場合は、`README.md` または `process/README.md` などの索引も更新する。

## Phase Order

1. 要件定義
2. アーキテクチャと脅威モデル
3. リポジトリと開発環境
4. PCブリッジ実装
5. Androidアプリ実装
6. プッシュ通知連携
7. End-to-End QA
8. Android Release と実機インストール

## Agent Responsibilities

### Planning Agent

- 親IssueとサブIssueの粒度を整える。
- 現在の工程で扱うべきIssueを選び、依存関係を明確にする。
- ユーザーの新しい要望をIssue化し、すぐ実装するか後続工程へ送るかを判断する。

### Documentation Agent

- 要件、設計、環境構築、検証、Release文書の整合性を保つ。
- 日本語を標準言語として、読み手が次の作業を開始できる粒度で書く。
- Issueで決まった内容を該当ドキュメントへ反映する。

### Implementation Agent

- Issueごとのブランチで実装する。
- 既存の設計・ドキュメント・工程別Skillを読んでから変更する。
- Androidアプリ、PCブリッジ、Firebaseの境界を崩さずに実装する。

### QA Agent

- Issueの受入条件に沿って検証する。
- 自動テスト、手動確認、実機確認のうち、そのIssueに必要な最小十分な検証を選ぶ。
- 検証できなかった項目はIssueに残す。

### Release Agent

- ReleaseブロッカーIssueが残っていないか確認する。
- APKビルド、Xperia 1 IIIへのインストール、E2EスモークテストをRelease完了条件として扱う。
- Releaseノート、既知の制限、検証証跡を残す。
