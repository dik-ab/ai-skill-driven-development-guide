# AI Skill-Driven Development Guide

このフォルダは、AI エージェントと人間が共同で開発するための汎用ガイドです。
特定の業種・案件・組織に依存しない形で、設計書、議事録、構成図、skills、レビュー、PR、導入手順をまとめます。

## 読む順番

1. `01-overview.md`  
   AI 駆動開発の全体像、基本原則、置くべき情報の種類。
2. `02-repository-and-docs-structure.md`  
   リポジトリ、設計書、議事録、構成図、タスク成果物の置き方。
3. `03-aidlc-workflow.md`  
   AIDLC の 5 フェーズ開発フロー。実装開始前から検証まで。
4. `04-skills-operation.md`  
   skills の作り方、読み方、起動条件、サブエージェント連携。
5. `05-review-and-quality-gates.md`  
   レビュー、テスト、仕様照合、PR 前チェックの運用。
6. `06-new-project-adoption.md`  
   新規プロジェクトへ導入する手順と初期テンプレート。

補助テンプレートは `templates/` に置いています。

- `templates/AGENTS-template.md`
- `templates/SKILL-template.md`
- `templates/aidlc-question-template.md`
- `templates/meeting-minutes-template.md`
- `templates/review-finding-template.md`

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
