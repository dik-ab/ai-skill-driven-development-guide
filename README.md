# AI スキル駆動開発ガイド

このフォルダは、AI エージェントと人間が共同で開発するための汎用ガイドです。
特定の業種・案件・組織に依存しない形で、設計書、議事録、構成図、skills、レビュー、PR、導入手順をまとめます。

## まず入門編から

初めて読む人、社内発表で使う人は `intro/` の入門編から始めてください。
用語集、3 層の仕組み、仕様書駆動、自動レビュー、AIDLC の 5 フェーズを、架空の会議室予約アプリの例で 45 分で読めるようにまとめています。
以下の 01〜12 章は詳細なリファレンスです。

## 読む順番（リファレンス）

1. `01-overview.md`
   AI 駆動開発の全体像、基本原則、置くべき情報の種類。
2. `02-repository-and-docs-structure.md`
   リポジトリ、設計書、議事録、構成図、タスク成果物の置き方。
3. `03-how-ai-loads-instructions-and-skills.md`
   `sample-monorepo` を例に、入口ガイド、rules、skills がどのように発見・選択・読み込みされるか。
4. `04-aidlc-workflow.md`
   AIDLC の 5 フェーズ開発フロー。実装開始前から検証まで。
5. `05-skills-operation.md`
   skills の作り方、読み方、起動条件、サブエージェント連携。
6. `06-review-and-quality-gates.md`
   レビュー、テスト、仕様照合、PR 前チェックの運用。
7. `07-new-project-adoption.md`
   新規プロジェクトへ導入する手順と初期テンプレート。
8. `08-spec-repository-operation.md`
   設計書そのものを AI で生成、検証、保守する運用。SSoT の層構造と整合性パイプライン。
9. `09-subagents-and-orchestration.md`
   再利用可能なサブエージェント定義と、coordinator / worker などの組み合わせパターン。
10. `10-hooks-and-machine-guards.md`
   hooks、パススコープ付き rules、MCP、監査ログなどの機械的ガード。
11. `11-operations-and-non-dev-skills.md`
    クラウド認証・接続を自動化する運用系 skill と、PM・報告・文書などの開発以外の AI 活用。
12. `12-live-demo-walkthrough.md`
    勉強会60分ガイド。ルートの動く最小構成（`CLAUDE.md` + rules + skills 5枚）を使い、
    基礎（読み込み3層・レビューのトレース）→ AWS連携 → Claude in Slack → draw.io →
    ブラウザ試験自動化を「同じ型のskill追加」として一本のストーリーで説明する台本。

補助テンプレートは `templates/` に置いています。

- `templates/CLAUDE-template.md`
- `templates/SKILL-template.md`
- `templates/aidlc-question-template.md`
- `templates/meeting-minutes-template.md`
- `templates/review-finding-template.md`

## 読者別の入口

最初から全章を読む必要はありません。

| 読みたいこと | 推奨する章 |
|---|---|
| AI駆動開発の考え方を知りたい | 01 |
| fileをどこへ置くか知りたい | 02 |
| AIが`CLAUDE.md`やskillをどう読むか知りたい | 03 |
| feature開発をphaseで管理したい | 04 |
| skillを設計・改善したい | 05 |
| reviewとmerge条件を整えたい | 06 |
| 新しいprojectへ導入したい | 07 |
| 設計書自体をAIで保守したい | 08 |
| 複数agentへ分担したい | 09 |
| 指示をhookやCIで強制したい | 10 |
| AWS、DB、PM、報告へ広げたい | 11 |
| 勉強会でライブデモしたい | 12 |

## このガイドの位置付け

このガイドにおけるAIDLCとskill運用は、設計書とcoding standardがあるproject向けに整理した実務modelです。業界標準規格を意味しません。

AI clientの自動読込場所、frontmatter、hook、subagentなどの仕様はversionによって変わります。考え方とproject内の正本はこのガイドで管理し、製品固有の挙動は各公式documentationと実際のclient表示で確認してください。

具体例には`sample-monorepo`の構造を使いますが、業務仕様そのものを他projectへコピーすることは意図していません。移植するのは、入口・rule・skill・spec・test・guardを分ける考え方です。

## この方式の目的

- AI の思い込みや実装ドリフトを、文書・テスト・レビューで抑える。
- 判断根拠をチャットに閉じず、後から追跡できるファイルに残す。
- 設計書、実装、テスト、レビュー観点を同じ流れで接続する。
- 新しい AI エージェントや人間メンバーが、同じ手順で作業を再開できるようにする。

## 禁止する書き方

- プロジェクト固有の業種名を前提にした説明。
- 「既存コードがそうだから正しい」という根拠だけの判断。
- 設計書を読まずにユーザーへ質問すること。
- レビュー結果を「問題なさそう」で終えること。
- PR や作業ログに、未検証の完了表現を書くこと。
