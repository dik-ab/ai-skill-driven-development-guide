# Repository And Documents Structure

## 推奨ディレクトリ構成

```text
project-root/
  AGENTS.md
  CLAUDE.md
  .agents/
    skills/
      aidlc/
      frontend-review/
      backend-review/
      testing/
      creating-pr/
  .claude/
    rules/
      frontend.md
      backend.md
      api.md
      database.md
      infra.md
  apps/
    frontend/
    backend/
  packages/
    api-client/
  infra/
    terraform/
  tasks/
    lessons.md
  aidlc-docs/
    2026-01-15_example-task/
      audit.md
      aidlc-state.md
      phase1-context-summary.md
      phase2-alignment-questions.md
      phase2-alignment-decisions.md
      phase3-test-contract.md
      phase4-implementation-plan.md
      phase4-convention-feedback.md
      phase5-implementation-delta.md
      phase5-chain-delta.md
      work-log.md
```

設計書を別リポジトリで管理する場合は、実装リポジトリと同じ親ディレクトリに置くと AI が参照しやすくなります。

```text
workspace/
  product-implementation/
  product-specs/
    deliverables/
      requirements/
      businessRules/
      specs/
        architecture/
        backend/
        frontend-design/
        api/
      adr/
```

## 入口ガイド

`AGENTS.md` は Codex などの AI エージェント向け入口です。ここには詳細を書きすぎず、判断順序と参照先を書きます。

含めるべき内容:

- リポジトリ概要
- 作業対象の分類
- 参照すべき rules / skills / 設計書
- 必須コマンド
- 生成物を手編集してはいけない場所
- 命名、言語、コメント、コミット方針
- 仕様通りに実装できない場合の停止ルール
- CI/CD の正本
- 検証方針

`CLAUDE.md` や他 AI ツール用の入口も、同じ判断順序に揃えます。ツールごとに情報が分岐すると、AI ごとに違う結論を出す原因になります。

## rules の置き方

`.claude/rules/` には、技術領域ごとの固定ルールを置きます。

```text
.claude/rules/
  monorepo.md
  frontend.md
  backend.md
  api-client.md
  database.md
  terraform.md
  aws.md
```

rules は「常に守る制約」です。作業手順そのものよりも、依存方向、命名、禁止事項、検証コマンド、生成物の扱いなどを書きます。

## skills の置き方

`.agents/skills/` には、AI が特定作業を行うための手順書を置きます。

```text
.agents/skills/
  aidlc/
    SKILL.md
    README.md
    templates/
    references/
    scripts/
  backend-testing/
    SKILL.md
  frontend-review/
    SKILL.md
    references/
  creating-pr/
    SKILL.md
```

skill は「この依頼なら何を読んで、どの順番で、何を出力するか」を定義します。

## 設計書の置き方

設計書は、AI が機械的に探せる単位に分けます。

```text
deliverables/specs/
  architecture/
    04_coding_standards.md
    05_implementation_patterns.md
    06_testing_guide.md
    12_directory_structure.md
    adr/
      001-record-title.md
  backend/
    <domain>/
      _context.yaml
      01_domain_model_spec.md
      05_api_spec.yaml
  frontend-design/
    <app>/
      SCR-001_design.html
  api/
    openapi.yaml
```

`_context.yaml` のような索引ファイルを置くと、AI がドメイン、集約、UseCase、Port、Event、依存関係を最初に読み取れます。

## 議事録の置き方

議事録は、日付とテーマで検索できるようにします。

```text
deliverables/meetings/
  2026-01/
    2026-01-15_api-policy.md
    2026-01-22_frontend-navigation.md
```

推奨フォーマット:

```markdown
# 2026-01-15 API Policy

## Participants

## Context

## Decisions

- DEC-001: ...

## Open Questions

- OQ-001: ...

## Follow-up

- [ ] ...

## Related Documents

- `deliverables/specs/architecture/...`
- `issues/...`
```

議事録で決まった内容は、最終的に ADR、設計書、issue、PR note のいずれかへ昇格させます。議事録だけを正本にしない方が安全です。

## 構成図の置き方

構成図は画像だけでなく、可能ならソースも保存します。

```text
deliverables/diagrams/
  system-context/
    system-context.md
    system-context.mmd
    system-context.png
  module-dependencies/
    module-dependencies.md
    module-dependencies.mmd
```

推奨は Mermaid などのテキスト形式です。AI が差分を読めるため、レビューや更新が容易になります。

## AIDLC タスク成果物

AIDLC の成果物は `aidlc-docs/{YYYY-MM-DD}_{task-name}/` に集約します。

| ファイル | 役割 |
|---|---|
| `audit.md` | ユーザー入力、判断、承認の完全ログ |
| `aidlc-state.md` | Phase とチェックリストの進捗 |
| `phase1-context-summary.md` | 読んだ設計書と事実抽出 |
| `phase2-alignment-questions.md` | 判断が必要な質問 |
| `phase2-alignment-decisions.md` | 確定方針 |
| `phase3-test-contract.md` | テスト契約、受入条件、観点 ID |
| `phase4-implementation-plan.md` | 実装単位、順序、ファイル一覧 |
| `phase4-convention-feedback.md` | 実装中に見つかった規約改善候補 |
| `phase5-implementation-delta.md` | 実装と設計書の差分 |
| `phase5-chain-delta.md` | 要件から実装までの定義チェーン差分 |
| `work-log.md` | サブエージェント間の共有ログ |

## 参照の仕方

AI には「この辺を見て」ではなく、具体的なファイルパスを渡します。

良い例:

```text
以下を読んでから実装してください。
- `deliverables/specs/backend/order/_context.yaml`
- `deliverables/specs/backend/order/01_domain_model_spec.md`
- `deliverables/specs/backend/order/05_api_spec.yaml`
- `.agents/skills/backend-testing/SKILL.md`
- `.claude/rules/backend.md`
```

避ける例:

```text
設計書を見ていい感じに実装して。
```

