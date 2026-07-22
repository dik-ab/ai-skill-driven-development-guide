# AI が instructions と skills を読み込む仕組み

この章では、実際のプロジェクト `sample-monorepo` を例に、AI がリポジトリのルールと skill をどのように発見し、必要な内容だけを読み込むかを説明します。

最初に重要な点を整理します。

- `CLAUDE.md` がすべての skill 本文を読み込むわけではない。
- `AGENTS.md` と `CLAUDE.md` は、リポジトリ全体の判断順序を示す入口である。
- Codex と Claude Code は、それぞれの標準ディレクトリから skill のメタデータを発見する。
- AI は依頼と `description` が一致する skill を選び、その時点で `SKILL.md` 本文と必要な参照資料を読む。
- 参考プロジェクト では `.agents/skills/` を共有する手順の正本にし、`.claude/skills/` からそこへ委譲する。

つまり、すべてを最初からコンテキストへ詰め込む方式ではありません。入口、選択用メタデータ、実行手順、詳細資料を段階的に読み込む構造です。

## 参考プロジェクト のディレクトリ構造

主要部分を抜き出すと、次のようになっています。

```text
sample-monorepo/
  AGENTS.md                    # Codex 向けのリポジトリ入口
  CLAUDE.md                   # Claude Code / Cursor 向けの入口
  .agents/
    skills/                   # Codex が発見する skill と共有手順の正本
      spa-frontend/
        SKILL.md
        references/
        evals/
      backend-auth/
        SKILL.md
        references/
        evals/
      aidlc/
        SKILL.md
        references/
        templates/
        scripts/
  .claude/
    rules/                    # Claude Code が読み込む固定・path-scoped rule
      monorepo.md
      pos-app.md
      backend.md
      terraform.md
    skills/                   # Claude Code が発見する薄い skill 入口
      spa-frontend/
        SKILL.md              # .agents 側の正本を読むよう指示
      backend-auth/
        SKILL.md              # .agents 側の正本を読むよう指示
  tasks/
    lessons.md                # 過去の失敗と再発防止策
```

`CLAUDE.md` には、次の参照関係が書かれています。

```text
- Codex 入口: AGENTS.md
- repo ルール: .claude/rules/
- Codex workflow: .agents/skills/
- Claude workflow: .claude/skills/
- 過去の落とし穴: tasks/lessons.md
```

これは skill 本文を Markdown import する記述ではありません。AI に「何をどの順番で参照するか」を伝えるルーティング表です。実際の自動発見は、Codex と Claude Code が持つディレクトリ探索の仕組みが担当します。

## 読み込みの全体フロー

```text
ユーザーの依頼
    │
    ▼
リポジトリ入口を読む
    ├─ Codex: AGENTS.md
    └─ Claude Code: CLAUDE.md + 対象に合う .claude/rules/
    │
    ▼
利用可能な skill の name / description を確認
    ├─ Codex: .agents/skills/*/SKILL.md
    └─ Claude Code: .claude/skills/*/SKILL.md
    │
    ▼
依頼、対象パス、トリガー条件に合う skill を選ぶ
    │
    ▼
選択した SKILL.md を全文読む
    │
    ├─ Codex: .agents/skills/<name>/SKILL.md
    └─ Claude Code: .claude 側の入口
                    → .agents 側の同名 master SKILL.md
    │
    ▼
SKILL.md が指定した references / templates / scripts / 設計書を読む
    │
    ▼
作業を実行し、skill が指定した方法で検証する
```

この段階的な読み込みを progressive disclosure と呼びます。全 skill の長い本文を起動時に読み込まず、最初は選択に必要な情報だけを使い、選ばれた skill の詳細だけをコンテキストへ追加します。

## Codex の読み込み

### 1. `AGENTS.md` を自動で読む

Codex は作業開始時に `AGENTS.md` を探索します。リポジトリルートから現在の作業ディレクトリまでに複数の `AGENTS.md` がある場合は、階層順に結合し、現在の作業場所に近い指示を優先します。

参考プロジェクト のルート `AGENTS.md` は、次の内容を短く固定しています。

- POS、Web Booking、backend、infra などの作業分類
- rules、skills、設計書を読む順序
- package manager や生成物に関する禁止事項
- 代表的な検証コマンド
- 仕様通りに進められない場合の停止条件

`AGENTS.md` は詳細な実装パターンをすべて抱えず、必要な rule と skill へ案内する入口です。

### 2. `.agents/skills/` から skill を発見する

Codex はリポジトリ内の `.agents/skills/*/SKILL.md` を skill として発見します。最初に重要なのは frontmatter の `name` と `description` です。

```yaml
---
name: spa-frontend
description: |
  Use this skill when working on the POS or Backyard frontend app.
  Triggers:
  - Creating or refactoring pages, components, hooks, stores, or routes
  - Any file under apps/frontend/pos/src/
  - 「画面を作って」「ページを追加」などの依頼
---
```

Codex はこの `description` とユーザー依頼を照合します。例えば「POSに新しい画面を追加して」という依頼なら `spa-frontend` が候補になります。skill が選ばれた後で、Codex は `SKILL.md` を最後まで読み、そこから指定された `references/` や設計書を追加で読みます。

## Claude Code の読み込み

### 1. `CLAUDE.md` と `.claude/rules/` を読む

Claude Code は `CLAUDE.md` をプロジェクトの入口として読みます。また、`.claude/rules/*.md` をルールとして発見します。

rule には `paths` frontmatter を付けられます。参考プロジェクト の POS rule は次の形です。

```yaml
---
paths:
  - apps/frontend/pos/**
---
```

これにより、POS以外の作業へPOS固有ルールを常に混ぜるのではなく、対象パスに応じたルールを読み込ませられます。

### 2. `.claude/skills/` から skill の入口を発見する

Claude Code が標準で発見するプロジェクトskillは `.claude/skills/` に置きます。一方、参考プロジェクトでは長い手順をCodex用とClaude用に二重管理していません。

`.claude/skills/spa-frontend/SKILL.md` は、トリガー判定に必要な frontmatterを持ち、本文では共有masterを読むよう指定します。

````markdown
---
name: spa-frontend
description: |
  Use this skill when working on the POS or Backyard frontend app.
  ...
---

# spa-frontend (Claude)

This is the Claude entry point. The canonical skill body lives in:

```text
.agents/skills/spa-frontend/SKILL.md
```

Read the master SKILL.md first and follow it.
````

この薄い入口は adapter の役割を持ちます。

1. Claude Code が標準の `.claude/skills/` からskillを発見できる。
2. `description` により自動起動条件を判定できる。
3. 実際の作業手順は `.agents/skills/` の共有masterを読む。
4. `references/`、`scripts/`、`templates/` の相対パスもmaster側を起点に解決する。

この構造により、ツールごとの発見場所は分けつつ、詳細手順の正本を一つにできます。

## 具体例: 「POS に新しい画面を追加して」

この依頼を受けた場合、概ね次の順序で情報が絞り込まれます。

1. 入口ガイドから、対象が `apps/frontend/pos` であると分類する。
2. Claude Codeでは `paths: apps/frontend/pos/**` を持つ `pos-app.md` が対象になる。
3. `spa-frontend` の `description` が依頼内容と一致する。
4. `spa-frontend/SKILL.md` の本文を読む。
5. skill が指定するディレクトリ規約、component pattern、state管理、API連携のreferenceを読む。
6. API仕様や画面仕様など、今回必要な正本だけを読む。
7. 実装後、skillと入口ガイドが指定するtest、lint、buildを実行する。

```text
「POS に新しい画面を追加して」
  → POS の path rule
  → spa-frontend skill
  → component / state / API references
  → 対象画面と API の仕様
  → 実装
  → test / lint / build
```

## 自動で読むものと、指示されてから読むもの

この区別は重要です。

| 情報 | Codex | Claude Code |
|---|---|---|
| リポジトリ入口 | `AGENTS.md` を自動探索 | `CLAUDE.md` を自動探索 |
| 固定・path rule | `AGENTS.md` やskillから必要ファイルを明示 | `.claude/rules/` を自動探索 |
| skill候補 | `.agents/skills/` を自動発見 | `.claude/skills/` を自動発見 |
| skill本文 | skill選択後に全文を読む | skill選択後に全文を読む |
| master skill | `.agents/skills/` を直接読む | `.claude`入口の指示で `.agents` masterを読む |
| references / scripts | 選択したskillの指示に従って読む | 選択したskillの指示に従って読む |
| 設計書・業務ルール | 対象skillや入口が指定したものを読む | 対象skillや入口が指定したものを読む |

`CLAUDE.md` にパスを書いただけで、その配下の全ファイルが自動的に全文ロードされるわけではありません。同様に、`AGENTS.md` に「skillsを読む」と書くだけでskill選択が実装されるわけでもありません。ツールが認識する配置、選択可能なfrontmatter、本文からの明示的な参照を組み合わせる必要があります。

## 設計上の原則

### 入口を短くする

入口には全技術詳細ではなく、分類、優先順位、禁止事項、参照先、代表コマンドを書きます。長い実装パターンはskillかreferenceへ分離します。

### `description` を起動契約として扱う

skill本文が優れていても、`description` が曖昧ならAIは選べません。対象作業、対象パス、ユーザーが使う表現、対象外を短く明示します。

### 本文の正本を一つにする

複数AIツールを使う場合、ツールごとの標準配置には薄い入口を置き、詳細手順は共有masterへ集約します。全文をコピーすると、修正漏れによるdriftが発生します。

### 参照を必要な時だけ読む

大きなskillは、概要と手順を `SKILL.md`、詳細な判定表やコード例を `references/`、決定論的処理を `scripts/` に置きます。これによりコンテキスト消費と読み漏れを両方抑えます。

### 指示と強制を区別する

`AGENTS.md`、`CLAUDE.md`、rules、skillsは、AIへ渡す指示とコンテキストです。セキュリティ上の禁止操作、必須チェック、merge条件など、確実な強制が必要なものはpermission、hook、CI、branch protectionなどの決定論的な仕組みでも実施します。

## 公式仕様

- [Codex: Custom instructions with AGENTS.md](https://developers.openai.com/codex/guides/agents-md/)
- [Codex: Agent Skills](https://developers.openai.com/codex/skills/)
- [Claude Code: How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Claude Code: Extend Claude with skills](https://code.claude.com/docs/en/skills)
