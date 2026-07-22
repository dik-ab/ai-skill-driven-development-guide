# レビューと品質ゲート

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

| 重要度 | 意味 |
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

## 品質ゲート

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

## 設計書整合

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

## lessons

失敗したレビュー観点は、`tasks/lessons.md` に追記します。

推奨フォーマット:

```markdown
## YYYY-MM-DD 短いタイトル

### 背景

### 何が起きたか

### 根本原因

### 再発防止策
```

lessons は AI が次回最初に読むべき再発防止リストです。

## レビューと品質ゲートの違い

レビューは「文脈を読んで判断する活動」、quality gateは「条件を満たしたか判定する関所」です。

```text
lint / typecheck / test
  → 機械的に判定できるquality gate

業務ルールとの整合、責務、将来リスク
  → 文脈が必要なreview
```

機械で判定できる問題を人間レビューへ残すと、レビュアーの時間を消費します。反対に、「この責務分割は妥当か」をlintだけで完全に判定することもできません。

## 具体例: 認可漏れのfinding

悪い指摘:

```text
権限チェックが足りない気がします。確認してください。
```

これでは、何が問題で、どう直し、どう確認するか分かりません。

改善例:

```markdown
### High: 更新前に対象店舗へのaccess scopeを検証する

実装の問題:
`UpdateReservationUseCase`はPermissionCodeだけを確認し、対象予約のstoreIdが
ユーザーのAccessScopeに含まれるか確認せずrepository.save()を呼んでいる。

正本の根拠:
- `businessRules/reservation.html` BR-RES-014
- `architecture/adr/ADR-021-authorization-order.md`

影響:
同じcompany内の権限を持つstaffが、scope外店舗の予約を更新できる。

期待する修正:
tenant → permission → scopeの順で検証し、scope外では403を返す。
repository.save()が呼ばれないtestも追加する。

対象:
- `UpdateReservationUseCase.java:42`
```

この形式なら、指摘の正しさを第三者が検証でき、修正担当も期待値を推測せずに済みます。

## quality gateを層に分ける

すべてを毎回project-wideで実行すると遅くなります。feedbackの速さと保証範囲を分けます。

| 層 | タイミング | 例 |
|---|---|---|
| 編集直後 | 秒単位 | format、対象file lint |
| unit loop | 数秒〜分 | 対象class/component test |
| feature完了 | 分単位 | package test、typecheck、integration |
| PR / merge | 広い範囲 | project-wide build、architecture、E2E |
| deploy後 | 実環境 | smoke、health、主要操作 |

```text
速い局所gate
  ↓
feature gate
  ↓
repository gate
  ↓
environment gate
```

ローカルでは最小の意味ある検証から始め、merge前の全体保証はCIへ置くのが基本です。ただし認証、DB migration、共通packageなど影響範囲が広い変更は早い段階で広いtestを実行します。

## testが通っても確認すること

test greenは重要ですが、次を自動的に証明するものではありません。

- testに書かれていないbusiness ruleを満たす
- 間違ったmock契約が実APIと一致する
- 認可のdeny caseが網羅されている
- migrationがproduction data量で安全である
- UIが実ブラウザで利用可能である
- 仕様書と実装が一致している

レビューでは「testがあるか」だけでなく、「意味のある失敗条件を検証しているか」を確認します。

## UIレビューの具体例

顧客一覧画面を変更した場合:

1. desktopとmobileで対象routeを開く。
2. loading、empty、error、dataありの4状態を確認する。
3. 長い氏名、長いメール、0件、100件など境界値を確認する。
4. console errorと失敗network requestを確認する。
5. keyboard操作とfocus順序を確認する。
6. 必要なら変更前後screenshotとpixel diffを保存する。

「画面が開いた」だけでは、empty/error stateやresponsive崩れを検証したことになりません。

## merge判断の例

| 状態 | 判断 |
|---|---|
| Blocker/High findingが未解決 | mergeしない |
| 必須testが失敗 | mergeしない |
| 必須test未実行・理由なし | mergeしない |
| 外部環境都合でE2E不能、代替証拠と残riskあり | ownerが判断 |
| Low改善だけ残る | follow-up可 |
| spec driftが未分類 | merge前に分類する |

AIは検証結果と残riskを提示できますが、例外的にgateを外してmergeする最終責任は人間のownerが持ちます。
