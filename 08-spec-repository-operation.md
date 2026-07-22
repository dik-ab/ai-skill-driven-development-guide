# 設計書リポジトリの AI 運用

ここまでの章は「設計書が既にあるプロジェクトで、AI に実装させる」流れを扱いました。この章は、その前段である「設計書そのものを AI で生成、検証、保守する」運用を扱います。

設計書リポジトリを実装リポジトリと分ける場合、設計書リポジトリは単なる文書置き場ではなく、生成パイプライン、整合性検証、SSoT 管理を持つ独立した開発対象になります。

## SSoT の 3 層モデル

設計書は、正本（SSoT: Single Source of Truth）の所有者をレイヤーごとに 1 つに決めます。

| レイヤー | 内容 | SSoT の置き場 |
|---|---|---|
| 1. 要件・業務ルール | 業務ルール、要件定義、用語集、画面一覧、非機能要件 | `deliverables/businessRules/`, `deliverables/requirements/` |
| 2. 基本設計 | ドメインモデル仕様、集約、状態遷移 | `deliverables/specs/**/01_domain_model_spec.md` |
| 3. 詳細設計 | API 仕様、画面設計、テーブル定義 | `deliverables/specs/**/05_api_spec.yaml` など |

原則:

- 各情報の正本は 1 箇所だけ。他の文書は ID で参照する（例: `BR-ORD-001`）。
- 上位レイヤーは意図の基準だが、矛盾時に下位や実装を自動上書きしない。driftとして止め、ownerが更新対象を判断する。
- 下位文書に上位の内容をコピーしない。参照だけ書く。

## 変更ワークフロー

変更の種類によって、更新する順番を固定します。

| 変更の種類 | 更新順序 |
|---|---|
| 業務ルールの変更 | businessRules を先に更新 → 影響する specs を追随させる |
| 設計だけの変更 | specs を更新 → businessRules は触らない |
| 実装から見つかった仕様差分 | delta として記録 → どちらを直すか人間が判断 → 正本を更新 |

AI に設計書を編集させる時は、この順序をスキップさせません。「specs だけ直して businessRules と矛盾したまま」が最も起きやすい事故です。hook で編集時に注意喚起する方法は `10-hooks-and-machine-guards.md` を参照してください。

## 設計書生成パイプライン

ドメイン数が多い場合、設計書は 1 つずつ手で作らず、生成用のサブエージェントをパイプライン化します。

```text
spec-coordinator（統括）
  ├── spec-domain-model  … 01_domain_model_spec.md を生成
  ├── spec-api           … 05_api_spec.yaml (OpenAPI) を生成
  ├── spec-screen        … 画面仕様を生成
  └── _context.yaml 生成 … 機械可読な索引を更新
spec-reviewer            … 文書間の整合性をレビュー
spec-dedup-checker       … ドメイン間の重複を検出
```

ポイント:

- 生成の入力は必ず上位レイヤー（業務ルール、要件）にする。
- 生成物には ID（UC-、SCR-、BR- など）を振り、後続の検証が機械的にたどれるようにする。
- 全ドメイン一括生成用の batch coordinator を分けて作る。1 ドメイン用と全体用を同じ agent にしない。

## 整合性検証パイプライン

設計書は書いた瞬間から腐り始めます。定期的に、または変更のたびに、AI で整合性を検証します。

代表的なパイプライン構成（fan-out / fan-in）:

```text
parser        … 業務ルール HTML / MD を構造化 JSON に変換
splitter      … 検証可能な粒度（100-300 行）に分割
domain-mapper … 各項目を所有ドメインに割り当て
checkers      … 並列実行
  ├── domain-model-checker … ドメインモデル仕様との整合
  ├── api-checker          … API 仕様との整合
  ├── screen-checker       … 画面仕様との整合
  ├── state-checker        … 状態遷移との整合
  └── table-checker        … テーブル定義との整合
aggregator    … 結果を統合、重複排除、優先度付け
fixer         … 修正を適用（または修正案を提示）
```

設計の要点:

- checker は「検証観点 1 つにつき 1 agent」に分ける。1 つの agent に全観点を持たせると精度が落ちます。
- aggregator を必ず挟む。checker の出力をそのまま fixer に渡すと、重複修正や矛盾した修正が起きます。
- fixer を自動適用にするか提案止まりにするかは、対象が正本かどうかで決める。正本（上位レイヤー）は提案止まりが安全です。

## トレーサビリティ

要件から実装までの定義チェーンを、機械的に検証できるようにします。

```text
業務ルール (BR-xxx)
  → UseCase (UC-xxx)
    → API (operationId)
      → 画面 (SCR-xxx)
        → 実装
```

推奨する仕組み:

- 画面仕様には参照する API を、API 仕様には対応する UseCase を、ID で明記する。
- 対応表の抽出と突き合わせは、AI の読解ではなく決定論的スクリプトで行う（`scripts/` に置く）。
- スクリプトが検出した不整合の解釈と修正だけを AI に任せる。

「抽出はスクリプト、判断は AI」という分担にすると、検証が安く速く再現可能になります。

## 機械可読な索引

リポジトリ全体とドメインごとに、AI が最初に読む索引を置きます。

| ファイル | 役割 |
|---|---|
| `DOCUMENT_MAP.yaml` | リポジトリ全体の文書地図。どの種類の文書がどこにあるか |
| `deliverables_index.json` | 成果物の一覧。ツールからの参照用 |
| `<domain>/_context.yaml` | ドメイン単位の索引。集約、UseCase、API、画面、依存 |

索引は人間向けの目次ではなく、AI・スクリプト向けの入力です。人間には HTML / Markdown の一覧を別に生成します。索引の手動編集は禁止し、生成スクリプトで更新します。

## 実装リポジトリとの往復

設計書リポジトリと実装リポジトリを分ける場合、次を決めておきます。

- 実装リポジトリの入口ガイド（`CLAUDE.md` など）に、設計書リポジトリへの相対パスを明記する（例: `../product-specs/deliverables/specs/`）。
- AIDLC フェーズ 5 の delta 反映は「実装リポジトリの AI が設計書リポジトリの文書を直接更新してよいか」を先に決める。
- 上位レイヤー（要件・業務ルール）は実装側から変更しない。差分として報告し、設計側で判断する。

## SSoTは「一番偉い文書」ではない

SSoTは情報種類ごとの所有元です。1つの文書がすべてに勝つわけではありません。

```text
キャンセル可能条件     → business rule
APIのrequest/response  → OpenAPI
DB変更履歴             → migration
設計を選んだ理由       → ADR
現在productionで起きる挙動 → 実環境の観測
```

例えばbusiness ruleと稼働中codeが違う場合、「上位文書が正しいからcodeを即変更」とは限りません。文書が古い、migrationが未適用、段階release中などの可能性があります。差分を検出し、ownerがどちらを直すか判断します。

## 具体例: キャンセル期限を変更する

変更内容:

```text
予約開始24時間前までキャンセル可能
  ↓
予約開始12時間前までキャンセル可能
```

更新の流れ:

1. business ruleのBR-IDを更新し、変更理由と適用日を記録する。
2. domain specの状態遷移・policyが24時間を持っていないか検索する。
3. API error、画面文言、通知文面への影響を確認する。
4. acceptance testの境界値を更新する。
5. 生成物を再生成し、実装repositoryへspec commitを渡す。
6. 実装側で12時間未満、12時間丁度、12時間超のtestを作る。
7. release後に旧ruleの予約dataへ影響がないか確認する。

```text
BR-RES-010
  ├→ Domain policy
  ├→ API error
  ├→ SCR-POS-020の表示文言
  ├→ Web Bookingの注意書き
  └→ acceptance test
```

この参照をIDで追えるようにするのがtraceabilityです。

## indexがあると何が嬉しいか

AIへ毎回repository全体を検索させる代わりに、`_context.yaml`で入口を与えます。

```yaml
domain: reservation
aggregates:
  - Reservation
usecases:
  - id: UC-RES-008
    name: CancelReservation
business_rules:
  - BR-RES-010
api_spec: 05_api_spec.yaml
screens:
  - SCR-POS-020
dependencies:
  - customer
  - staff
```

AIは最初にこのindexを読み、必要な正本だけへ進めます。ただしindexは正本の要約・案内であり、詳細仕様そのものではありません。

## 設計書reviewの具体的な出力

```markdown
### P1: BR-RES-010の12時間境界がAPI specへ反映されていない

事実:
- business ruleは12時間へ変更済み
- API specのerror exampleは24時間のまま
- Web Booking画面文言も24時間のまま

影響:
clientとbackendが異なる期限を表示・判定する可能性がある。

修正順序:
1. API specのerror exampleを更新
2. 画面仕様の文言を更新
3. generated clientを再生成
4. 境界testを更新
```

「不整合あり」だけでなく、ID、両方の根拠、影響、修正順序を出します。

## 鮮度とversionを管理する

- 設計書repositoryのcommitを実装PRへ記録する。
- snapshotを使う場合はsource commitと取得日時を持つ。
- link check、ID重複、未参照IDをCIで検出する。
- deprecatedなspecを削除せず、後継と適用期間を示す。
- AI生成文書は人間ownerがacceptedにするまでproposalとして扱う。
