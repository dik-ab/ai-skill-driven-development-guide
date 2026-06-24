# skills 運用

## skill とは何か

skill は、AI に特定作業をさせるための実行手順書です。単なる知識メモではなく、次を明確にします。

- いつ起動するか
- 作業前に何を読むか
- どの順番で進めるか
- 何を成果物として出すか
- 何を禁止するか
- どの検証を実行するか

## skill の基本構成

```text
.agents/skills/<skill-name>/
  SKILL.md
  README.md
  references/
    *.md
  templates/
    *.md
  scripts/
    *.sh
```

| パス | 役割 |
|---|---|
| `SKILL.md` | 起動条件、作業手順、成果物、禁止事項 |
| `README.md` | skill の目的、背景、設計思想 |
| `references/` | 詳細ルール、判定表、読み込みマップ |
| `templates/` | 質問、レポート、テスト契約などのフォーマット |
| `scripts/` | 初期化、検査、集計などの決定論的処理 |

## SKILL.md の推奨フォーマット

```markdown
---
name: backend-testing
description: >
  バックエンドのテスト作成・修正・実行時に使う。
  Trigger: "テストを書いて", "test", "integration test", "coverage"
  NOT for: フロントエンドテスト、単発コマンドだけで完了する作業
---

# バックエンドテスト

## 目的

## 入力

## 作業前に必ず読むもの

## 作業手順

## 成果物

## 検証

## 禁止事項
```

description は重要です。AI はここを見て skill を起動するため、トリガー語と対象外を明確に書きます。

## skill の種類

| 種類 | 例 | 役割 |
|---|---|---|
| ライフサイクル skill | `aidlc` | 作業全体の phase 管理 |
| 実装 skill | `backend-modulith`, `frontend-spa` | 実装パターン、ディレクトリ、責務 |
| テスト skill | `backend-testing`, `frontend-testing` | テスト作成、テストダブル、実行コマンド |
| レビュー skill | `backend-contract-pr-review`, `frontend-review` | PR 前、差分、仕様準拠チェック |
| 運用 skill | `terraform`, `aws-ops`, `db-access` | インフラ、ログ、DB、障害調査 |
| PR skill | `creating-pr` | PR タイトル、本文、push、merge 後処理 |
| 管理 skill | `worktree-create`, `worktree-sweep` | isolated worktree の作成と掃除 |

## skills の読み込み原則

AI は、skill を使う前に `SKILL.md` を最後まで読みます。`SKILL.md` が `references/` や `templates/` を指定している場合は、該当ファイルも読みます。

サブエージェントへ委譲する場合、親のコンテキストは引き継がれません。prompt に読み込むべきファイルを明示します。

```markdown
## 必須読み込みファイル

作業開始前に以下を読むこと。

- `.agents/skills/backend-testing/SKILL.md`
- `.agents/skills/backend-testing/references/test-doubles.md`
- `.claude/rules/backend.md`
- `deliverables/specs/backend/order/01_domain_model_spec.md`
```

## skill-map

AIDLC では、phase ごとに読むべき skill と rule を map 化します。

例:

| タイミング | 読むもの |
|---|---|
| Phase 2 質問作成前 | アーキテクチャ設計書、ADR、対象ドメイン仕様 |
| Phase 4 実装前 | 実装 skill、対象技術 rule、テスト skill |
| DDL 変更時 | database skill、migration rule |
| API 変更時 | API design skill、OpenAPI 仕様 |
| 認証・認可変更時 | auth skill、security rule |
| PR 前 | review skill、testing skill、creating-pr skill |

## templates の使い方

テンプレートは自由作文を防ぐために使います。

代表例:

- `question.md`: 判断が必要な質問を根拠付きで書く
- `context-summary.md`: Phase 1 の事実抽出を書く
- `test-contract.md`: Phase 3 のテスト契約を書く
- `multi-agent-coordination.md`: サブエージェント連携を書く
- `pr-body.md`: PR 本文を統一する

AI には「このテンプレートに従って出力」と明示します。

## scripts の使い方

繰り返し実行する処理は scripts にします。

例:

- AIDLC タスク初期化
- worktree 作成
- layer 別ファイル数集計
- API drift check
- coverage / viewpoint check
- docs link check

AI が長い shell を毎回手で組み立てるより、script 化した方が再現性が高くなります。

## サブエージェント連携

複数 AI に分担させる場合は、`work-log.md` を共有ログにします。

```markdown
## U-001 ドメインモデル
**状態**: completed / in-progress / blocked
**担当 AI**: backend-agent
**作成・変更ファイル**:
- `apps/backend/src/domain/order/Order.java`
**重要な判断**:
- 合計金額は application service ではなく domain method で計算する。
**公開インターフェース**:
- `Order#confirm()`
**後続ユニットへの申し送り**:
- application unit は policy validation 後に `confirm()` を呼び出せる。
```

親エージェントの責務:

- サブエージェントへ読み込み対象を明示する
- 同じファイルを複数サブに編集させない
- work-log を読んで結果を統合する
- サブの報告をそのまま最終判断にしない

## skill を増やす基準

新しい skill は、次の条件を満たす時に作ります。

- 同じ作業が 3 回以上出てくる
- 作業前に読むべきファイルが多い
- 判断ミスが起きやすい
- レビュー観点が明確に定義できる
- script や template で再現性を高められる

逆に、1 回きりの小さな修正は skill 化しません。
