# skills 運用

## 最初に: skill は何を解決するのか

skill は、AI に特定作業を再現可能な方法で実行させるための手順パッケージです。

AI は一般的なプログラミング知識を持っています。しかし、何も教えなければ次のプロジェクト固有情報は分かりません。

- どの設計書が正本か
- どのディレクトリへ実装するか
- どの既存パターンを使うか
- どの操作をしてはいけないか
- どのテストを実行すれば完了か
- 失敗した時にどこまで自分で調べ、どこで人間へ判断を戻すか

毎回長いpromptでこれらを説明する代わりに、作業単位の手順としてリポジトリへ保存したものがskillです。

```text
一般的なAI
  + プロジェクト固有のskill
  + 今回の依頼
  = このプロジェクトで再現可能な作業をするAI
```

skillの価値は「AIを賢くすること」よりも、「担当者やセッションが変わっても同じ入口、判断順序、検証方法を使わせること」にあります。

## skillと似た仕組みの違い

初学者が最も混乱しやすいのは、rule、skill、spec、ADRなどの役割の違いです。

| 仕組み | 答える質問 | 例 |
|---|---|---|
| 入口ガイド | 最初に何を確認するか | `CLAUDE.md` |
| rule | 常に何を守るか | 「生成API clientを手編集しない」 |
| skill | この作業をどう進めるか | 「認可機能を実装する手順」 |
| spec | 何を実現すべきか | API request/response、業務ルール |
| ADR | なぜその設計を選んだか | JWTではなくsession cookieを採用した理由 |
| template | どんな形で出力するか | PR本文、質問票、監査レポート |
| script | 何を機械的に実行するか | API生成、件数集計、link check |
| hook / CI | 何を機械的に強制するか | lint失敗、生成物編集を拒否 |
| subagent | 誰に作業を分担するか | domainごとの並列checker |
| MCP | 外部システムをどう操作するか | GitHub、AWS、チケット管理 |

例えば「予約キャンセルに認可を追加する」という依頼では、次のように複数の情報が合流します。

```text
CLAUDE.md
  └─ backend作業だと分類する

.claude/rules/backend.md
  └─ layer、命名、依存方向を守らせる

backend-modulith skill
  └─ UseCaseとdomain modelの作り方を示す

backend-auth skill
  └─ tenant、permission、scopeの確認順序を示す

reservation spec / business rule
  └─ 誰がどの状態でキャンセルできるかを定義する

ADR
  └─ 認可方式を選んだ理由を説明する

test / architecture test
  └─ 実装が契約と境界を守ったか検証する
```

skillだけで仕様を決めたり、ruleだけで作業手順を表現したりしないことが重要です。

## AIがskillを使うまで

skillの読込は、概ね3段階です。詳細は`03-how-ai-loads-instructions-and-skills.md`も参照してください。

### 段階1: metadataで候補を知る

AIは最初に、各skillの`name`、`description`、配置場所を確認します。この段階では長い本文をすべて読みません。

```yaml
---
name: backend-auth
description: >
  認証、認可、ログイン、セッション、権限、CSRF、RLS、テナント分離を扱う時に使う。
  一般的なCRUD、DDL、ログ設計、Terraformには使わない。
---
```

### 段階2: 依頼とdescriptionを照合する

例えば、次の依頼は`backend-auth`に一致します。

```text
「予約キャンセルに権限チェックを追加して」
「ログイン失敗時にアカウントをロックしたい」
「この一覧API、別テナントのデータが見えないか確認して」
```

一方、次の依頼は一致しません。

```text
「予約テーブルにindexを追加して」       → database skill
「Controllerの命名をレビューして」      → backend review skill
「ECSのtask数を変更して」               → Terraform / AWS skill
```

### 段階3: 選択後に本文と必要な資料を読む

skillが選択されると、AIは`SKILL.md`本文を読みます。本文が指定している場合だけ、`references/`、`templates/`、設計書などを追加で読み、`scripts/`を実行します。

```text
name + description
  ↓ 依頼と一致
SKILL.md本文
  ↓ 今回は認可変更
references/authorization-model.md
  ↓ 対象domainを特定
reservationのbusiness rule / API spec
  ↓
実装・テスト・報告
```

この方式をprogressive disclosureと呼びます。最初から全情報を詰め込まず、必要になった情報だけを段階的に読みます。

## skillの基本構成

代表的な構成です。

```text
.claude/skills/backend-auth/
  SKILL.md                   # 必須。起動条件と中心手順
  references/
    authentication.md        # 必要時に読む詳細知識
    authorization-model.md
  scripts/
    verify-permissions.sh    # 決定論的に実行する処理
  assets/
    report-template.html     # 出力へコピー・加工する素材
  templates/
    finding.md               # プロジェクト独自の出力雛形
  evals/
    trigger-eval.json        # プロジェクト独自の評価ケース
```

`SKILL.md`だけが必須です。それ以外は必要な場合だけ作ります。空のディレクトリを先に大量に作る必要はありません。

| パス | AIにとっての役割 | 具体例 |
|---|---|---|
| `SKILL.md` | 中心となる作業手順 | 読む順番、作業ステップ、停止条件 |
| `references/` | 必要時に読む詳細資料 | schema、判定表、API、コード例 |
| `scripts/` | 読解より実行が適した処理 | lint、生成、集計、差分検査 |
| `assets/` | 出力に利用する素材 | ロゴ、HTML雛形、boilerplate |
| `templates/` | 埋めて使う文章形式 | PR本文、質問票、レポート |
| `evals/` | skill品質を測るケース | trigger/no-trigger、期待する成果物 |

`templates/`や`evals/`はすべてのAI製品に共通する標準ではなく、プロジェクト側の運用規約として置くことがあります。

## `SKILL.md`の2つの部分

### 1. frontmatter: skillを選ぶための情報

ファイル先頭のYAML部分です。

```yaml
---
name: screen-api-triage
description: |
  画面で「アクセスできない」「500」「データが出ない」「ボタンが効かない」などの
  想定外挙動があり、API配線や契約driftを疑う時に使う。
  全画面の定期疎通、純粋なUIレビュー、画面症状のないbackend障害には使わない。
---
```

frontmatterはskill本文より先にAIへ見せる「起動契約」です。本文にだけ「認証変更時に使う」と書いても、本文は選択後まで読まれないため、起動判定には役立ちません。

よくないdescription:

```yaml
description: Backend作業を支援する。
```

これでは範囲が広すぎて、database、auth、API、loggingなど隣接skillとの区別ができません。

改善例:

```yaml
description: >
  backendの認証・認可・アクセス制御を実装またはレビューする時に使う。
  login/logout、session/cookie、CSRF、permission、scope、RLS、tenant isolationを含む。
  一般CRUDはbackend-modulith、DDLはbackend-database、ログ設計はbackend-observabilityを使う。
```

良いdescriptionには次を含めます。

- skillが何をするか
- どのような依頼で使うか
- ユーザーが実際に使う日本語・英語
- 対象パスや技術領域
- 隣接skillへ渡す対象外

### 2. body: 選択後に実行する手順

frontmatterの後ろのMarkdown本文です。本文には、AIが作業を完走するための手順を書きます。

```markdown
# Backend Auth

## 最初に読むもの

- `.claude/rules/backend.md`
- `references/authorization-model.md`
- 対象domainのbusiness ruleとAPI spec

## 手順

1. 対象UseCaseと必要なPermissionCodeを特定する。
2. tenant、permission、scopeの順で検証する。
3. 認可成功後だけ業務処理を実行する。
4. allow、deny、別tenant、scope外のtestを追加する。
5. 対象testとarchitecture testを実行する。

## 停止条件

- business ruleに必要権限が定義されていない場合は推測しない。
- 既存ADRと異なる認可方式が必要なら実装前に判断を戻す。
```

本文では「知っていると便利な話」を無制限に増やさず、今回の仕事を進めるために必要な順序、分岐、禁止事項、検証を優先します。

## resourceをどう使い分けるか

### `references/`: 読んで判断する資料

詳細な知識、表、schema、コード例を置きます。

```text
references/
  authentication.md
    → session、cookie、CSRFを扱う時に読む

  authorization-model.md
    → PermissionCode、AccessScopeを扱う時に読む

  rls.md
    → tenant isolationやDB policyを扱う時に読む
```

`SKILL.md`には、単にファイル名を列挙するのではなく、いつ読むかを書きます。

```markdown
- login/session変更時: `references/authentication.md`を読む。
- permission/scope変更時: `references/authorization-model.md`を読む。
- PostgreSQL RLS変更時: database skillも使い、`references/rls.md`を読む。
```

すべてのreferenceを毎回読む指示にすると、分割した意味がなくなります。

### `scripts/`: 機械に実行させる処理

毎回AIがshellを組み立てるより、結果が一意になる処理はscriptにします。

```text
scripts/init-task.sh
  → task folderとstate fileを同じ形式で作る

scripts/check-generated-files.sh
  → 生成物が手編集されていないか判定する

scripts/collect-api-paths.mjs
  → OpenAPIからpathとoperationIdを抽出する
```

scriptが向く判断基準:

- 同じ処理を繰り返す
- 件数や一致判定を正確に出したい
- 操作順序を間違えると危険
- 人間とAIで同じ結果を得たい

script自体は実際に実行して検証します。存在しないcommandを例だけ書いて完了にしません。

### `templates/`: 出力の形を揃える

自由作文では成果物の粒度が毎回変わります。templateは「何を書くか」を固定します。

```markdown
# Review finding

## 結論

## 根拠

## 影響

## 期待する修正

## 検証方法
```

templateは判断そのものを代替しません。空欄を機械的に埋めるのではなく、skill本文に「根拠がない場合は指摘として確定しない」などの品質条件も書きます。

### `assets/`: 成果物へ利用する素材

AIが読む知識ではなく、成果物にコピー・加工して利用するものです。

```text
assets/
  company-logo.svg
  report-theme.css
  frontend-starter/
```

例えばレポート生成skillなら、デザインを毎回作り直さず、既存のCSSやlogoを利用します。

### `evals/`: skill自体をテストする

skillには少なくとも2種類の品質があります。

1. 正しい依頼で起動し、関係ない依頼では起動しないか
2. 起動後に期待する手順と成果物を実行できるか

trigger evalの例:

```json
{
  "skill": "backend-testing",
  "cases": [
    { "prompt": "UseCaseのテストを書いて", "expect": "trigger" },
    { "prompt": "統合テストが落ちてる", "expect": "trigger" },
    { "prompt": "フロントのtestを追加して", "expect": "no-trigger" },
    { "prompt": "この関数の意味を説明して", "expect": "no-trigger" }
  ]
}
```

成果物evalでは、例えば次を確認します。

- specを先に読んだか
- allowだけでなくdeny testも作ったか
- 指定commandを実行したか
- 未実行検証を隠していないか
- 対象外のファイルを変更していないか

## skillの種類と具体例

| 種類 | 代表例 | 入力 | 主な出力 |
|---|---|---|---|
| lifecycle | `aidlc` | issue、DoD、設計書 | phase成果物、実装、検証 |
| implementation | `spa-frontend` | 画面・feature依頼 | React実装、test |
| domain/security | `backend-auth` | 認証・認可変更 | UseCase wiring、security test |
| testing | `backend-testing` | 対象class・仕様 | unit/integration test |
| diagnosis | `screen-api-triage` | 画面症状 | 根拠付き原因、局所修正 |
| review | `backend-contract-pr-review` | PRと関連spec | severity付きfindings |
| operation | `aws-ops` | 環境、症状、resource | ログ・状態・診断結果 |
| infrastructure | `terraform` | resource変更 | HCL、plan、validate結果 |
| delivery | `creating-pr` | branch、issue、検証 | PR title/body |
| workspace | `worktree` | issue、branch | isolated worktree |

## 複数skillが同時に必要な例

skillは必ず1つだけ選ぶものではありません。責務が直交していれば併用します。

依頼:

```text
「予約キャンセルAPIに認可を追加して、テストも書いて」
```

役割分担:

| skill | 担当する判断 |
|---|---|
| `backend-modulith` | UseCase、domain、repository、layer構造 |
| `backend-auth` | tenant、permission、scope、RLS |
| `api-design` | URL、status、Problem Details |
| `backend-testing` | unit/integration testの形 |

この時、4つのskillへ同じ責務を持たせません。例えばHTTP statusは`api-design`、認可順序は`backend-auth`を正本にします。

逆に、似たskillが同じ問題を別方式で解決しようとする場合は併用せず、descriptionの`NOT for`や所有範囲で衝突を解消します。

## 作業フローの具体例: 画面で500が出る

依頼:

```text
「会計画面を開くと500になる。APIの配線合ってる？」
```

`screen-api-triage`が起動した場合の流れ:

```text
1. 環境要因を除外
   - 開発環境が停止していないか
   - login lockやsession切れではないか

2. ブラウザで再現
   - 対象画面へ移動
   - networkとconsoleを確認

3. 事実を収集
   - request URL
   - HTTP status
   - response body
   - correlation ID

4. 3ソースを比較
   - 画面仕様
   - frontend/MSW
   - backend OpenAPI

5. 修正範囲を判定
   - URLやDTOの違いなら配線修正
   - UseCaseや業務ルール変更が必要なら重い設計フローへ戻す

6. 実APIで再検証
```

この例では、skillは単なる「APIの知識」ではなく、憶測で修正しないための診断順序と停止条件を提供しています。

## skillを作る手順

### 1. 実際の依頼例を集める

先に「ユーザーが何と言うか」を集めます。

```text
起動させたい:
- 「ログインを直して」
- 「権限チェックを追加して」
- 「別店舗のデータが見える」

起動させたくない:
- 「staffテーブルにindexを追加して」
- 「認可設計書の誤字を直して」
```

### 2. 毎回再発見しているものを分類する

| 再発見しているもの | 置き場所 |
|---|---|
| 作業順序 | `SKILL.md` |
| 詳細なdomain知識 | `references/` |
| 同じshell処理 | `scripts/` |
| 同じ出力形式 | `templates/` |
| 出力へ使う素材 | `assets/` |
| 起動・成果物テスト | `evals/` |

### 3. 自由度を決める

- 複数の妥当な方法がある設計相談: 原則と比較観点を示す
- 推奨patternがある実装: 擬似コードと選択条件を示す
- migrationや本番操作など危険な作業: command、順序、停止条件を固定する

### 4. frontmatterを書く

what、when、対象外をdescriptionへまとめます。

### 5. 本文とresourceを実装する

本文から各resourceへ直接リンクし、いつ読むかを書きます。referenceからreferenceへ何段もたどらせないようにします。

### 6. 検証する

- YAMLが正しいか
- 正しい依頼で選ばれるか
- 隣接skillと衝突しないか
- scriptが実行できるか
- 実タスクを最初から完走できるか

## サブエージェントとskill

skillは作業手順、subagentは作業を担当する別の実行主体です。

```text
親agent
  ├─ backend-auth skillを自分で使う
  └─ domainごとの調査をsubagentへ委譲する
       └─ subagentも必要なskillと資料を読む
```

コンテキスト継承はAIツールと起動方式によって異なります。独立コンテキストのnamed subagentもあれば、親会話を継承するforkもあります。そのため「必ず引き継がれる」「絶対に引き継がれない」と一律に仮定しません。

委譲promptには最低限、次を明示します。

- 目的
- 対象範囲
- 読むskillと正本
- 編集してよいファイル
- 編集してはいけないファイル
- 実行する検証
- 返却形式

詳細は`09-subagents-and-orchestration.md`を参照してください。


## よくある失敗

### skillが起動しない

原因:

- descriptionが抽象的
- ユーザーが使う表現が含まれていない
- skillがツールの発見場所にない
- YAMLが壊れている
- skill数が多く説明が短縮されている

対策:

- 実際に失敗した依頼文をtrigger evalへ追加する
- descriptionの先頭へ中心用途を書く
- 利用中ツールのskill一覧・debug表示を確認する

### skillが何にでも起動する

原因:

```yaml
description: コードを変更する時に使う。
```

のように範囲が広すぎます。対象技術、作業種類、対象外を追加します。

### SKILL.mdが巨大になる

症状:

- 毎回関係ない章まで読む
- 重要な停止条件が埋もれる
- 同じ説明が複数箇所にある

対策:

- 中心workflowだけを`SKILL.md`に残す
- domain別・variant別詳細を`references/`へ分ける
- 本文から一段で到達できるようにする

### 指示だけで危険操作を防ごうとする

「本番DBを削除しない」とskillに書くだけでは強制になりません。permission、hook、CI、read-only credentialなどの機械的ガードも使います。

### 存在しないcommandを書く

skillに`./scripts/check.sh`と書いたのにscriptがない、または実行できない状態です。ドキュメントレビューだけでなく、scriptの存在と実行結果を検証します。

## skillを増やす基準

次のどれかに該当する時はskill化を検討します。

- 同じ作業が繰り返される
- 毎回読む正本が複数ある
- 手順の順番を間違えやすい
- セキュリティ、データ、運用上のリスクがある
- 出力形式を統一したい
- scriptやtemplateで再現性を上げられる
- 専門領域の境界を明確にしたい

回数だけで機械的に決めません。1回目でも、認証・本番操作・migrationのように失敗コストが大きい作業はskill化する価値があります。

逆に、次は通常skill化しません。

- 一度しか使わない小さな修正
- AIの一般知識だけで安全に完了できる作業
- 既存skillへ数行追加すれば足りる作業
- 起動条件を明確に定義できない曖昧な役割

## 完成チェックリスト

- [ ] `name`が短く役割を表している
- [ ] `description`にwhat、when、対象外がある
- [ ] 実際の日本語・英語依頼例で起動を確認した
- [ ] 隣接skillとの所有範囲が分かれている
- [ ] `SKILL.md`に作業順序、停止条件、検証がある
- [ ] referenceごとに「いつ読むか」が書かれている
- [ ] scriptを実行して成功を確認した
- [ ] templateに品質条件がある
- [ ] 指示でなく機械的に強制すべきものをhook/CIへ分けた
- [ ] 実タスクでforward testした

## 公式仕様

- [Claude Code: Extend Claude with skills](https://code.claude.com/docs/en/skills)
