# 新規プロジェクトへの導入

## 導入の考え方

新規プロジェクトに AI skill-driven development を入れる時は、最初から大量の skill を作る必要はありません。まず、AI が迷わない入口、正本ドキュメント、最小の AIDLC、レビュー skill から始めます。

## フェーズ 0: 最小セットを作る

最初に作るもの:

```text
project-root/
  AGENTS.md
  CLAUDE.md
  .agents/
    skills/
      aidlc/
        SKILL.md
        templates/
        references/
      creating-pr/
        SKILL.md
      code-review/
        SKILL.md
  .claude/
    rules/
      monorepo.md
      frontend.md
      backend.md
      infra.md
  deliverables/
    requirements/
    businessRules/
    specs/
      architecture/
      backend/
      frontend-design/
      api/
    adr/
  tasks/
    lessons.md
```

## フェーズ 1: AGENTS.md を作る

`AGENTS.md` に書くこと:

```markdown
# エージェントガイド

## リポジトリ概要

## 作業分類

1. フロントエンド
2. バックエンド
3. API / API クライアント
4. インフラ
5. ドキュメント

## 作業順序

1. 変更対象を分類する。
2. 対象に合う rules と skills を読む。
3. 設計判断の前に正本ドキュメントを読む。
4. 変更範囲を最小にする。
5. 意味のある検証を実行する。
6. 未解決スコープと失敗した検証を報告する。

## 必須ルール

## コマンド

## 正本ドキュメント

## 検証
```

## フェーズ 2: rules を作る

最初の rules は短くて構いません。

例:

- `frontend.md`: ディレクトリ、UI コンポーネント、テスト、Storybook、API mock
- `backend.md`: layer、UseCase、Repository、Port、DTO、transaction、logging
- `api.md`: URL、HTTP method、status、error、pagination
- `database.md`: migration、index、constraint、seed、audit column
- `infra.md`: Terraform、secret、environment、plan / validate

## フェーズ 3: AIDLC skill を導入する

`.agents/skills/aidlc/SKILL.md` を作り、5 フェーズを定義します。

最小版:

```markdown
# AIDLC

## フェーズ 1: コンテキスト読み込み

要件、設計書、rules、既存コードを読む。
`phase1-context-summary.md` を出力する。

## フェーズ 2: 方針すり合わせ

矛盾を検出する。未解決の質問だけを `templates/question.md` 形式で作る。
確定方針を出力する。

## フェーズ 3: テスト契約

実装前に受入条件とテストケースを定義する。

## フェーズ 4: 実装

ユニットごとにテスト先行で実装する。状態ファイルを更新する。

## フェーズ 5: 検証

検証を実行する。実装と設計書の差分を照合する。
```

必要なテンプレート:

- `templates/question.md`
- `templates/context-summary.md`
- `templates/test-contract.md`
- `templates/multi-agent-coordination.md`

## フェーズ 4: 設計書の正本を作る

AI が参照できるように、設計書は粒度を揃えます。

```text
deliverables/specs/backend/<domain>/
  _context.yaml
  01_domain_model_spec.md
  05_api_spec.yaml
```

`_context.yaml` 例:

```yaml
bounded_context: order
type: core
cqrs_level: 1
aggregates:
  - Order
usecases:
  - UC-ORD-001 CreateOrder
  - UC-ORD-002 ConfirmOrder
exposed_ports:
  - CustomerLookupPort
published_events:
  - OrderConfirmed
dependencies:
  - customer
```

API 仕様は OpenAPI など機械可読な形式にします。画面仕様や業務ルールは HTML / Markdown でもよいですが、ID を付けます。

## フェーズ 5: レビュー skill を作る

最初に必要なのは、差分レビューと契約レビューです。

`code-review/SKILL.md` に書くこと:

- 変更ファイルの収集方法
- 対象外ファイル
- rules の読み込み
- 設計書との照合
- テスト有無
- 指摘の出力形式
- 重要度

契約レビューでは、必ず正本ファイルのパスと実装ファイルのパスを両方示します。

## フェーズ 6: PR skill を作る

PR 作成 skill では、次を標準化します。

- branch と base の確認
- diff stat
- area prefix
- 日本語またはチーム標準言語での PR 本文
- 検証結果
- issue の閉じ方
- merge 後の worktree cleanup

## フェーズ 7: lessons を運用する

AI の失敗は資産になります。レビュー漏れ、検証漏れ、仕様読み違いが起きたら、`tasks/lessons.md` に再発防止策を書きます。

AI には、作業開始時に lessons を読むよう入口ガイドで指示します。

## 導入チェックリスト

- [ ] `AGENTS.md` がある
- [ ] AI ツールごとの入口ガイドが同じ判断順序になっている
- [ ] `.claude/rules/` に領域別ルールがある
- [ ] `.agents/skills/aidlc/` がある
- [ ] `templates/question.md` がある
- [ ] `templates/test-contract.md` がある
- [ ] 設計書の正本パスが決まっている
- [ ] 議事録の置き場がある
- [ ] 構成図の置き場がある
- [ ] ADR の置き場がある
- [ ] `tasks/lessons.md` がある
- [ ] PR 前検証コマンドが明記されている
- [ ] review skill が findings-first の形式を持っている
- [ ] generated files の手編集禁止ルールがある
- [ ] issue DoD と PR close ルールがある

## 最初の 30 日の進め方

1. 最初の 1 週間は AIDLC を小さな feature で試す。
2. skill が長すぎる場合は、references と templates に分割する。
3. レビュー漏れが起きたら lessons に追記し、必要なら review skill に反映する。
4. 3 回以上繰り返した作業は script 化する。
5. 重要判断がチャットに残ったら、ADR または設計書へ移す。
6. CI で検知できるものは、人間レビューではなく機械 gate に寄せる。

## 移植時の注意

- 既存プロジェクトの固有名詞をそのまま持ち込まない。
- 業種固有の業務ルールを、汎用 skill に混ぜない。
- skill は手順、rule は制約、spec は正本として分ける。
- AI が読む順番を明示する。
- 「質問する前に読む」を徹底する。
- 完了条件はチェックリストとして外部化する。
