# Review And Quality Gates

## レビューの基本姿勢

AI 駆動開発のレビューは、コードの見た目を確認するだけでは不十分です。次を分けて確認します。

- 実装が仕様を満たしているか
- 設計書とコードが一致しているか
- テスト契約を満たしているか
- アーキテクチャ境界を破っていないか
- データ、認可、監査、冪等性などの横断要件を満たしているか
- UI が実際に崩れていないか
- 生成物や API client を手編集していないか

## レビューの種類

| レビュー | タイミング | 主な観点 |
|---|---|---|
| 差分レビュー | コミット前 | 変更ファイル、責務、テスト不足、明らかなバグ |
| feature レビュー | 実装完了後 | feature 全体の構造、依存、テスト、Storybook |
| contract レビュー | PR 前 / PR 中 | 設計書、API、業務ルール、DB 定義との整合 |
| quality gate | merge 前 | lint、test、build、architecture test、E2E |
| reconciliation | Phase 5 | 実装と設計書の差分、ADR 要否 |

## レビューの出力形式

指摘は、必ず actionable にします。

```markdown
結論: 修正すべき内容を 1 文で書く

実装の問題:
現在の差分が何をしているか

正本の根拠:
設計書、ADR、rule、API 仕様のパスと章節

影響:
振る舞い、セキュリティ、データ、保守性、レビュー上の影響

期待する修正:
具体的にどう直すか
```

## 指摘の優先度

| Severity | 意味 |
|---|---|
| Blocker | merge すると仕様違反、データ破壊、セキュリティ問題、重大障害になる |
| High | 重要な仕様漏れ、テスト不能、設計境界違反 |
| Medium | 保守性、拡張性、テスト不足に実害がある |
| Low | 軽微な改善。merge blocker ではない |

レビューでは、重要度順に findings を先に出します。総評や感想を先に置くと、修正すべき点が埋もれます。

## 契約レビューの観点

バックエンドや API では、次を確認します。

- API 仕様と Controller / DTO の一致
- request / response のフィールド名、型、必須性
- HTTP status とエラー形式
- 業務ルール ID とテストの対応
- 集約、UseCase、Repository、Port の責務
- 書き込み処理が domain behavior を通っているか
- DB migration と table definition の一致
- 認可、スコープ検証、監査ログ
- 冪等性、楽観ロック、同時実行
- 例外変換と Problem Details

## フロントエンドレビューの観点

フロントエンドでは、次を確認します。

- page / feature / ui / hooks の配置
- feature 間の直接依存がないか
- API 取得と状態管理の責務
- schema / validation の共通化
- テストと Storybook の存在
- API mock が MSW などの共通仕組みに乗っているか
- ハードコードされた仮データが残っていないか
- 画面が実ブラウザで崩れていないか
- レスポンシブ、ローディング、空状態、エラー状態

## Quality Gate

merge 前に、対象範囲に応じて検証を実行します。

例:

```bash
pnpm lint
pnpm test
pnpm build
pnpm generate:api-client
./gradlew test
./gradlew archTest
./gradlew modularityTest
./gradlew integrationTest
```

小さな変更では最小検証でよいですが、merge 判断前には project-wide guard を 1 回は通します。filtered test だけでは、全体 guard がスキップされることがあります。

## UI の検証

UI 変更は、コードレビューだけで終わらせません。

確認するもの:

- dev server が起動する
- 対象画面に到達できる
- 主要操作ができる
- console error がない
- text がはみ出していない
- loading / empty / error が表示される
- mobile / desktop の崩れがない
- 必要なら screenshot を保存する

## Reconciliation

Phase 5 では、実装と設計書の差分を確認します。

差分の分類:

- P0: 実装か設計書を直さないと merge できない
- P1: merge 前に更新すべき
- P2: follow-up issue でよい

確認観点:

- 要件から設計、実装、テストまでつながっているか
- 設計書にある概念が未実装で残っていないか
- 実装にだけ存在する概念がないか
- 新しい公開契約が ADR 対象ではないか

## PR 作成

PR は、差分をファイル単位で羅列するのではなく、レビューしやすい単位でまとめます。

推奨 PR 本文:

```markdown
## 概要

この PR で実現することを 1-2 文で書く。

## 変更点

- ...
- ...

## 検証

- [x] `pnpm test`
- [x] `pnpm build`

## 備考

- 関連 issue
- 未解決スコープ
- follow-up
```

DoD が未完了なら、issue を閉じるキーワードは使いません。

## Lessons

失敗したレビュー観点は、`tasks/lessons.md` に追記します。

推奨フォーマット:

```markdown
## YYYY-MM-DD Short Title

### Context

### What went wrong

### Root cause

### Preventive action
```

lessons は AI が次回最初に読むべき再発防止リストです。

