# AIDLC ワークフロー

AIDLC は、設計書と規約があるプロジェクトで AI の実装ドリフトを抑えるための 5 フェーズ開発フローです。

## 全体像

| フェーズ | 名称 | 主な成果物 | 人間の関与 |
|---|---|---|---|
| 1 | コンテキスト読み込み | `phase1-context-summary.md` | 原則なし |
| 2 | 方針すり合わせ | `phase2-alignment-questions.md`, `phase2-alignment-decisions.md` | 矛盾・未定義がある時だけ |
| 3 | テスト契約設計 | `phase3-test-contract.md` | 必須 |
| 4 | テスト先行実装 | `phase4-implementation-plan.md`, 実装、テスト | 実装計画の承認 |
| 5 | 検証と設計書整合 | delta レポート、設計書更新、PR 準備 | レビュー、承認 |

## ステップ 0: 初期化

新規タスクでは、できるだけ専用 worktree とタスクフォルダを作ります。

```bash
scripts/aidlc-init.sh <short-task-name> --issue <issue-number>
```

初期化で作るもの:

- 作業ブランチまたは分離 worktree
- `aidlc-docs/{date}_{task}/`
- `audit.md`
- `aidlc-state.md`
- `work-log.md`

`audit.md` には、ユーザー依頼の原文、判断、承認を追記します。要約や上書きは禁止です。

## フェーズ 1: コンテキスト読み込み

目的は「AI が判断する前に、正本から事実を集める」ことです。

読むもの:

- 対象ドメインの context ファイル
- ドメインモデル仕様
- API 仕様
- 画面仕様
- 業務ルール
- 関連 ADR
- 既存コードの構造
- 過去の lessons

出力:

```text
phase1-context-summary.md
```

ここには事実だけを書きます。リスク評価、実装方針、推奨案はフェーズ 2 で扱います。

含める観点:

- 対象ドメインと依存
- 読んだ設計書
- 集約、Entity、Value Object、状態遷移
- UseCase と API
- 関連画面
- 業務ルール ID
- 既存コードの layer 別内訳
- 設計書に記述がない箇所

## フェーズ 2: 方針すり合わせ

目的は「仕様、設計、既存コードの矛盾を実装前に解消する」ことです。

まず AI が自己解決します。

- アーキテクチャ設計書を読む
- ADR を読む
- 既存コードを確認する
- 設計書に答えがある質問は人間に投げない

質問が必要な場合だけ、`phase2-alignment-questions.md` を作ります。

質問ファイルには次を必ず含めます。

- 原理原則 / 背景
- 用語定義
- 設計書ベースの根拠
- 外部リファレンス
- 選択肢比較
- 各選択肢の詳細
- AI の推奨
- 回答欄

ユーザーの回答後、`phase2-alignment-decisions.md` に確定方針を書きます。

ADR 候補になる判断:

- 既存ルールや ADR と違う例外を採用する
- 今後の標準になり得る新規パターンを初導入する
- 公開契約、Port、Event、Snapshot など後続が依存する shape を決める

## フェーズ 3: テスト契約設計

目的は「実装前に、何を満たせば完了かをテスト契約として固定する」ことです。

成果物:

```text
phase3-test-contract.md
```

含める内容:

- 対象 API と業務ルール ID
- シナリオレベルの業務判断マトリクス
- 観点カバレッジ表
- 未確定事項
- 単体テストケース仕様
- テスト形状とテストダブル戦略
- merge 前の完了条件

テスト契約は、AI が後から「十分できた」と自己判断することを防ぐための外部基準です。

## フェーズ 4: テスト先行実装

目的は「テスト契約を先にコード化し、実装を規約準拠で進める」ことです。

実装前に作るもの:

```text
phase4-implementation-plan.md
```

含める内容:

- 実装ユニット一覧
- 依存関係
- 作成・変更ファイル
- 実装順序
- 実行するテスト

実装順序は、アーキテクチャに合わせます。

例:

```text
domain -> application -> infrastructure -> presentation
```

各ユニットのループ:

1. テストを書く
2. 必要な interface / contract を定義する
3. 実装する
4. 対象テストを実行する
5. 規約とのズレを `phase4-convention-feedback.md` に記録する
6. `aidlc-state.md` を更新する

構造的な方針変更が必要になった場合は、黙って進めずフェーズ 2 に戻します。

## フェーズ 5: 検証と設計書整合

目的は「実装が動くだけでなく、設計書と整合していることを確認する」ことです。

実行する検証:

- unit test
- integration test
- architecture test
- module boundary test
- lint / typecheck
- build
- 画面確認が必要ならブラウザ検証
- 仕様と実装の差分確認

出力:

- `phase5-implementation-delta.md`
- `phase5-chain-delta.md`
- 必要な設計書更新
- 必要な ADR
- PR 準備メモ

設計書差分の観点:

- クラス名、型名、パッケージ配置
- API URL、HTTP method、request / response
- DB カラム、制約、migration
- UseCase、Port、Event
- 設計書にあるが未実装の概念
- 実装にあるが設計書にない概念

## 完了条件

AIDLC の完了は、次が揃った状態です。

- フェーズ 3 の merge 前の完了条件が満たされている
- 必要な検証が実行済み
- 失敗した検証が報告されている
- 設計書と実装の差分が記録されている
- 未解決スコープが明示されている
- PR に進める状態が説明できる
