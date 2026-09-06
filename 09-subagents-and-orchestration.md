# サブエージェント定義とオーケストレーション

`05-skills-operation.md` では、skill から一時的にサブエージェントへ委譲する方法（work-log 共有）を扱いました。この章は、その一歩先である「再利用可能なサブエージェント定義」と、複数エージェントを組み合わせるパターンを扱います。

## 4 つの仕組みの使い分け

AI への指示を外部化する仕組みは 1 つではありません。役割で使い分けます。

| 仕組み | 置き場の例 | 役割 | 起動方法 |
|---|---|---|---|
| rule | `.claude/rules/*.md` | 対象領域で守るようAIへ伝える制約 | パスや文脈で自動適用 |
| skill | `.claude/skills/*/SKILL.md` | 特定作業の手順書。読む順番、成果物、検証 | description のトリガー語で自動起動 |
| command | `.claude/commands/*.md` | ユーザーが明示的に叩く定型作業 | `/コマンド名` で手動起動 |
| agent | `.claude/agents/*.md` | 分離コンテキストで動く専用ワーカー | 親エージェントが委譲 |

判断基準:

- 「いつでも守れ」なら rule。
- 「この依頼が来たらこの手順」なら skill。
- 「人間が意図的に開始する定型フロー」なら command。
- 「並列化したい」「親のコンテキストを汚したくない」「役割を固定したい」なら agent。

## agent 定義を作る基準

skillとの違いは、agentが別の実行主体として固定された責務を持つことです。多くのnamed agentは独立contextを使いますが、fork型は親contextを継承する場合があります。次の場合にagent化します。

- 同種の処理を多数の対象に並列適用する（ドメイン別検証、画面別レビューなど）。
- 処理の入出力が構造化できる（JSON を返すワーカーなど）。
- 親エージェントに読ませたくない大量の中間データを扱う。
- 役割ごとにモデルの強さを変えたい（統括は高性能モデル、単純作業は軽量モデル）。

agent 定義には最低限、次を書きます。

```markdown
---
name: domain-model-checker
description: ドメインモデル仕様と業務ルールの整合を検証する
---

## 役割

## 入力（親が prompt で渡すもの）

## 必ず読むファイル

## 検証手順

## 出力形式（構造化して返す）

## 禁止事項
```

サブエージェントのcontext継承は、AIツールと起動方式で異なります。独立contextで始まるnamed agentもあれば、親会話を継承するforkもあります。どちらの場合も、再現性のため「必ず読むファイル」とtask固有入力を明記します。

## 基本パターン: coordinator / worker

複数エージェント構成の基本形です。

```text
coordinator（統括）
  - 対象の一覧を作る
  - worker への割り当てと prompt を作る
  - 結果を統合し、最終判断をする
worker（実働、複数並列）
  - 1 対象だけを処理する
  - 構造化した結果を返す
  - 判断せず、事実と検出結果だけ返す
```

原則:

- worker は 1 つの対象、1 つの観点に限定する。範囲を広げるほど精度が落ちます。
- 最終判断は coordinator に置く。worker の報告をそのまま採用しない。
- 同じファイルを複数 worker に編集させない。編集が必要な場合は対象を排他的に分割します。

## 拡張パターン

| パターン | 構成 | 使う場面 |
|---|---|---|
| batch coordinator | 全対象用の統括が、対象ごとの coordinator を順次/並列起動 | 全ドメイン一括生成、全画面一括レビュー |
| aggregator | 並列 worker の結果を統合、重複排除、優先度付けする専用 agent | 検証パイプラインの fan-in |
| fixer | 検出済みの指摘を適用するだけの agent。検出と修正を分離する | 大量の機械的修正 |
| reviewer | 生成直後の成果物を別コンテキストで検証する agent | 生成 → 即レビューの品質ゲート |

検出（checker）と修正（fixer）を分ける理由は、検出の網羅性と修正の安全性を独立に制御するためです。1 つの agent に「見つけたら直せ」と指示すると、見つける精度も直す精度も下がります。

## 並列実行の注意

- 並列数は対象の独立性で決める。ファイル編集を伴う worker は、書き込み先が重ならないことを保証してから並列化する。
- worker の出力は構造化形式（JSON、決まった見出しの Markdown）で受け取る。自由作文を統合するのは coordinator の負担になります。
- 進捗と結果は共有ログ（`work-log.md` など）か、worker ごとの出力ファイルに残す。チャット上の報告だけにしない。
- 失敗した worker はゼロ件成功と区別して記録する。「結果が空」と「実行されなかった」を混同すると、検証漏れが静かに起きます。

## session 固有の agent 定義

クライアント読み合わせや一時的な一括作業のために、日付入りの使い捨て agent 定義（例: `walkthrough-2026-04-14-session01.md`)を作る運用もあります。この場合:

- 再利用する定義と使い捨ての定義をディレクトリまたは命名で区別する。
- 使い捨て定義には、参照する会議資料や対象一覧のパスを直接書いてよい（汎用化しない）。
- 終わったセッションの定義は削除するかアーカイブへ移し、agent 一覧を汚さない。

## skillとsubagentの違い

```text
skill
  = 仕事のやり方

subagent
  = 仕事を担当する別の実行主体
```

例えば`backend-contract-review`はreview手順です。同じ手順をreservation、customer、accountingへ並列適用する時、それぞれをsubagentへ割り当てられます。

```text
coordinator
  ├─ reservation worker + review skill
  ├─ customer worker    + review skill
  └─ accounting worker  + review skill
```

agent定義へdomain知識を大量に複製せず、skillとspecを読むようにします。

## 具体例: 3 domainのAPI契約を並列reviewする

親が最初に対象を固定します。

```json
{
  "domains": ["reservation", "customer", "accounting"],
  "base": "main",
  "head": "feature/api-update",
  "output": "findings-first"
}
```

各workerへのprompt例:

```text
目的: customer domainのAPI契約driftをreviewする。

必須資料:
- .claude/skills/backend-contract-pr-review/SKILL.md
- deliverables/specs/backend/customer/05_api_spec.yaml
- .claude/rules/backend.md

対象:
- apps/backend/api/src/main/java/com/example/customer/**

禁止:
- fileを編集しない
- 他domainをreviewしない
- specにない要件を推測しない

出力:
- severity
- spec根拠
- implementation file:line
- 影響
- 期待する修正
```

worker結果:

```json
{
  "domain": "customer",
  "status": "completed",
  "findings": [
    {
      "severity": "High",
      "contract": "GET /api/v1/customers/{id}",
      "issue": "response.requiredのemailがDTOではnullable"
    }
  ],
  "validation_errors": []
}
```

aggregatorは、同じ根本原因によるfindingsをまとめ、spec間で矛盾した提案を検出します。workerが3件返したから3件すべて正しいとは判断しません。

## 並列化しない方がよい例

- 同じ中心fileを複数agentが編集する
- 1つ目の判断結果が2つ目の入力になる
- public contractを複数agentが別々に決める
- taskが小さく、委譲promptの作成costの方が大きい
- secretやproduction変更を含み、統制が複雑になる

次の変更は順次実行が安全です。

```text
OpenAPI変更
  → client生成
  → frontend修正
  → integration test
```

client生成前にfrontend workerを走らせると、古い型を基準に実装する可能性があります。

## 失敗とゼロ件を区別する

```json
{ "status": "completed", "findings": [] }
```

は「検証して問題なし」です。

```json
{ "status": "failed", "error": "spec file not found" }
```

は「検証していない」です。aggregatorが両方を空結果として扱うと、静かな検証漏れになります。

## coordinatorの完了条件

- [ ] 全対象にcompleted/failed/skippedの状態がある
- [ ] 同じfileを複数workerが変更していない
- [ ] 重複findingを統合した
- [ ] worker間の矛盾を解消した
- [ ] failed対象を「問題なし」に数えていない
- [ ] 最終判断をsourceで再確認した
- [ ] 未解決scopeと残riskを報告した
