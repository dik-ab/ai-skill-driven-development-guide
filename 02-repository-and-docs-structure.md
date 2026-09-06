# リポジトリとドキュメント構成

## 推奨ディレクトリ構成

```text
project-root/
  CLAUDE.md
  .claude/
    rules/
      frontend.md
      backend.md
      api.md
      database.md
      infra.md
    skills/
      aidlc/
      frontend-review/
      backend-review/
      testing/
      creating-pr/
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

`CLAUDE.md` は AI エージェント向けの入口です。Claude Code がセッション開始時に自動で読みます。ここには詳細を書きすぎず、判断順序と参照先を書きます。

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

rules は「対象領域で常に守るようAIへ伝える制約」です。作業手順そのものよりも、依存方向、命名、禁止事項、検証コマンド、生成物の扱いなどを書きます。ruleはcontextであり強制機構ではないため、確実に拒否すべき操作にはhook、permission、CIも使います。

rules には frontmatter で対象パスの glob を付け、該当パスに触れた時だけ有効化するのが推奨です（`10-hooks-and-machine-guards.md` 参照）。

## skills の置き方

`.claude/skills/` には、AI が特定作業を行うための手順書を置きます。

```text
.claude/skills/
  aidlc/
    SKILL.md
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
# 2026-01-15 API 方針確認

## 参加者

## 背景

## 決定事項

- DEC-001: ...

## 未決事項

- OQ-001: ...

## TODO

- [ ] ...

## 関連ドキュメント

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

## ADRの置き方

ADR（Architecture Decision Record）は、「どんな構造になっているか」ではなく「なぜその設計を選んだか」を残す文書です。

```text
設計書
  → 現在どうなっているか

ADR
  → なぜそうしたか、何を比較し、何を受け入れたか
```

例えばcodeからsession cookieを使っていることは分かっても、次は分かりません。

- JWTを検討したか
- なぜJWTを採用しなかったか
- 即時session失効が必要だったか
- modular monolithという前提が影響したか
- 将来どの条件なら判断を見直すか

判断理由がないと、人間やAIは一般論だけで過去の案へ戻す可能性があります。

推奨構造:

```text
deliverables/specs/architecture/adr/
  ADR-001-use-session-cookie.md
  ADR-002-module-boundaries.md
```

最小format:

```markdown
# ADR-001: Session Cookieを採用する

## Status
Accepted

## Context
即時失効、複数ECS task、browser securityを満たす認証方式が必要。

## Decision drivers
- 即時にsessionを無効化できる
- HttpOnly cookieを利用できる
- 運用を複雑にしない

## Considered options
1. Server-side session
2. JWT access/refresh token

## Decision
共有session storeを使うserver-side sessionを採用する。

## Consequences
Positive: 即時失効できる。
Negative: session storeの運用が必要。
```

ADRに向く判断:

- 複数の有力案がある
- 後から戻すcostが高い
- 複数team・featureへ影響する
- 公開契約、security、data、module境界を決める
- 既存ruleの例外や新しい標準patternを採用する

変数名や既存pattern内の小さな実装判断までADRにしません。判断が変わった場合は古いADRを黙って書き換えず、新しいADRから`Supersedes ADR-001`のように履歴をつなぎます。

## AIDLC タスク成果物

AIDLC の成果物は `aidlc-docs/{YYYY-MM-DD}_{task-name}/` に集約します。

| ファイル | 役割 |
|---|---|
| `audit.md` | secret・個人情報を除外した依頼、判断、承認の監査ログ |
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
- `.claude/skills/backend-testing/SKILL.md`
- `.claude/rules/backend.md`
```

避ける例:

```text
設計書を見ていい感じに実装して。
```

## なぜファイルを分けるのか

すべてを`CLAUDE.md`や1つの巨大設計書に入れると、次の問題が起きます。

- frontend作業でもbackend規約が入り、重要な指示が埋もれる
- APIだけ変更したいのに全domainの仕様を読む
- 同じ説明を複数場所へコピーし、更新差分が生まれる
- AIがどれを正本としてよいか判断できない

分割の基準は「誰が読むか」ではなく、「どの条件で必要になるか」です。

| 情報 | 分割単位 | 例 |
|---|---|---|
| 入口 | repository / package | root `CLAUDE.md`、package別`CLAUDE.md` |
| rule | 技術領域・対象path | frontend、backend、Terraform |
| skill | 作業種類 | 実装、test、review、障害調査 |
| spec | domain・契約 | reservation、customer、accounting |
| ADR | 1つの重要判断 | session方式、module境界 |
| task成果物 | issue・作業単位 | test契約、delta、work log |

## 具体例: 新しいPOS画面を追加する時に読む範囲

```text
project-root/
  CLAUDE.md
  .claude/rules/pos-app.md
  .claude/skills/spa-frontend/SKILL.md
  .claude/skills/spa-frontend/references/component-patterns.md
  deliverables/specs/frontend-design/pos/SCR-POS-101.html
  deliverables/specs/backend/reservation/05_api_spec.yaml
  apps/frontend/pos/src/pages/
```

各ファイルの役割:

1. `CLAUDE.md`: POSの配置と作業順序を知る。
2. `pos-app.md`: POS配下で守る固定ルールを知る。
3. `spa-frontend/SKILL.md`: 画面を作る手順を知る。
4. `component-patterns.md`: Page、Feature、UIの具体的な書き方を知る。
5. `SCR-POS-101.html`: 画面が何を表示し、どう操作されるかを知る。
6. `05_api_spec.yaml`: 呼び出すAPIのpath、request、responseを知る。
7. 既存code: 現在の実装方法と変更箇所を確認する。

これらは同じ情報を重複して持つのではなく、入口、制約、手順、仕様、実装という別の責務を持ちます。

## 正本の所有表を作る

「上位文書が常に勝つ」とだけ決めると、稼働DBや公開APIなど別の現実を見落とします。情報の種類ごとに所有元を決めます。

| 情報 | 正本の例 | 矛盾時の扱い |
|---|---|---|
| 業務上の意図 | business rule | 実装で勝手に変更しない |
| 公開API契約 | OpenAPI | client生成物とControllerを追随させる |
| DB変更履歴 | migration | table定義との差分を調査する |
| 設計判断の理由 | ADR | 変更するなら新しいdecisionを残す |
| 現在の実挙動 | codeと実行test | specとの差分として報告する |

文書が古い可能性もあるため、矛盾を見つけたAIは上位へ盲従せず、「意図」「契約」「実状態」のどこがずれているかを報告します。

## 命名とlinkの実務ルール

- ファイル名だけでdomainと文書種類が推測できるようにする。
- 見出しを安定させ、`§`やIDで参照できるようにする。
- 「こちら」「上記」だけで参照せず、相対pathとIDを書く。
- 移動時は`rg`で旧pathを検索し、内部linkを更新する。
- 生成索引と手書き正本を区別し、生成物には編集禁止を明記する。
- owner、最終更新日、source commitなど、鮮度を判断できる情報を持たせる。
