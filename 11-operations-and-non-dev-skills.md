# 運用系 skill と開発以外の AI 活用

AI 活用は実装フローだけで終わりません。インフラ運用、障害調査、プロジェクト管理、クライアント向け文書にも同じ「skill として外部化する」考え方が適用できます。

## 運用系 skill の考え方

インフラ操作や障害調査は、毎回同じ準備（認証、接続、対象の特定）から始まります。この準備を skill に埋め込むと、AI は「ログ見て」「なんか落ちてる」という曖昧な依頼から、自力で認証・接続して調査まで完走できます。

運用系 skill に書くもの:

- 認証方式と自動化手順(後述)
- 環境の全体像（アカウント構成、リージョン、命名規則、接続方式）
- サービス別の定型調査コマンド
- 安全原則（読み取り専用が基本、破壊的操作は必ず人間に確認）
- 機密情報の扱い（シークレット値を表示しない、ログに残さない）

## AWS への自動認証・接続

skill に認証手順を組み込めば、AI はユーザーに手動操作を求めずに AWS へ接続できます。

構成例（MFA セッション方式）:

```markdown
## 認証（skill 内の記述例）

- AWS Profile: `<project>-dev-session`（MFA セッション付きプロファイル）
- リージョン: `ap-northeast-1`（全コマンドに `--region` を付与）
- MFA: 仮想 MFA。OTP は OS のキーチェーン + `oathtool` で自動生成
- 組織policyが許可する範囲でrefreshを自動化する。対話認証や追加承認が必要なら人間へ依頼する

## セッション確認と自動リフレッシュ

# 1. セッション有効性を確認
aws sts get-caller-identity --profile <project>-dev-session

# 2. 失敗した場合（ExpiredToken 等）→ リフレッシュスクリプトを実行
bash ~/.aws/<project>-mfa-session.sh
```

ポイント:

- OTP シークレットは OS のキーチェーン等の安全な保管庫に置き、リフレッシュスクリプトが取得して一時セッションを作る。skill やリポジトリに認証情報そのものは書かない。
- skillには「操作開始時にsessionを確認し、切れていたら組織policyに従ってrefreshまたは再認証を依頼する」という手順を明記する。credentialやMFA seedをAIへ露出しない。
- SSO を使う組織なら `aws sso login` ベースで同じ構成にできる。この場合ブラウザ認証だけは人間に依頼する手順として書く。
- 全コマンドに profile と region を強制する（デフォルトプロファイル頼みにしない）。事故防止と再現性のためです。

安全原則も skill 側に固定します。

- 調査系（describe / get / list / logs）は自動実行してよい。
- 変更・削除・停止系は実行前に必ず人間へ確認する。
- シークレット値、アクセスキーは表示しない。
- 出力は `--query` や `--output table` で絞り、コンテキストを浪費しない。

## DB アクセスの skill 化

DB 調査も同様に、接続経路ごと skill に固定できます。

- 踏み台なし構成（ECS Exec、SSM Session Manager、port forwarding など）の接続 runbook を skill の `references/` に置く。
- 読み取り専用ロールでの接続をデフォルトにする。
- 「接続確認 → 対象テーブル特定 → クエリ実行 → 切断」の定型フローを手順化する。
- トラブルシューティング（権限不足、タスク未起動など）も references に含めると、AI が自己解決します。

## プロジェクト管理・報告系 skill

開発以外の定型業務も skill 化の対象です。

| skill の例 | 役割 |
|---|---|
| daily-standup | チケット管理ツールと Git から情報収集し、稼働開始/終了報告を生成 |
| session-recap | AI セッションログ、コミット、チケット更新を横断して 1 日の振り返りを生成 |
| ticket-writer | クライアント向けチケットを起票。文体ルールを内包 |
| requirements-doc-writer | 要件定義書のドラフト作成。文体ルールを内包 |
| project-pm | 計画策定、リスク洗い出し、マイルストーン整理を PM 視点で行う |

文書生成系 skill では、文体ルールを skill に明記するのが有効です。

- AI 特有の過剰な表現（「極めて重要」「包括的」「唯一の」など）を禁止語として列挙する。
- 実務者が書いたような密度と語彙に抑える基準を書く。
- 出力先の記法（Markdown、チケットツール固有記法）を固定する。

クライアントに出る文書ほど、この文体制御の価値が大きくなります。

## 専門家パネル型 skill

設計判断の壁打ちに、複数の専門家視点を持たせた skill を使うパターンがあります。

```markdown
---
name: ddd-design-experts
description: >
  DDD 設計の相談時に使う。複数の専門家視点（戦略的 DDD、テスト設計など）で
  ディスカッション形式の助言を返す。
---
```

作り方の要点:

- 視点は 2〜3 に絞り、それぞれの立場・重視する原則・代表的な著作や思想を定義する。
- 一括回答ではなく、視点間で意見が割れる論点を明示させる。
- 領域ごとに skill を分ける（設計、認証・セキュリティ、認可、フロントエンド設計など）。1 つの万能パネルにしない。
- 実装依頼はスコープ外と明記する。判断・方針の議論専用にする。

これは「AI に答えを出させる」のではなく「判断材料と対立軸を出させる」使い方です。最終判断は人間が行い、決定は ADR や決定記録に残します。

## 開発用と非開発用の skill を分ける

skill が増えると、トリガーの衝突が起きやすくなります。

- description の `NOT for:` に、隣接する skill 名を明記して相互に排他する。
- 開発系（実装、テスト、レビュー）と非開発系（PM、報告、文書）は命名で区別する。
- 定期的にトリガー精度を測る仕組みは `05-skills-operation.md` の evals を参照してください。

## 実装skillより慎重にする理由

運用skillは外部状態を変更できます。

```text
code編集
  → Git diffで戻しやすい

production resource削除
  → data lossやservice停止につながる
```

そのため、運用skillでは「できるcommand」だけでなく、権限、対象環境、実行前確認、rollback、監査を中心に設計します。

## 操作をriskで分類する

| Level | 操作例 | 自律実行 |
|---|---|---|
| Read | describe、list、logs、metrics | 原則可 |
| Reversible | desired count変更、feature flag | target確認と承認方針に従う |
| Destructive | delete、drop、purge | 明示承認とbackup確認が必要 |
| Irreversible / external | 顧客通知、決済、公開 | 人間の最終確認を必須にする |

「調査して」という依頼は、production resourceの変更許可まで含みません。診断と修正を分けます。

## 具体例: APIの5xxを調査する

依頼:

```text
「dev環境の予約APIが500になっている。原因を調べて」
```

安全な調査フロー:

1. environment、region、service名を確定する。
2. `sts get-caller-identity`でaccountと認証状態を確認する。
3. ECS service/taskの状態をread-onlyで確認する。
4. ALB target healthを確認する。
5. request時刻・correlation IDでCloudWatch Logsを絞る。
6. DBが疑わしい場合、read-only経路とRLS前提を確認する。
7. 原因、証拠、影響、修正候補を報告する。
8. deploymentやresource変更は、依頼scopeと承認を確認して別stepで行う。

悪い進め方:

```text
500を発見
  → とりあえずECSをrestart
  → 一時的に直ったので原因不明のまま完了
```

restartで証拠が消える可能性があります。まず観測し、変更前状態を保存します。

## 認証情報を書かない

skillに書いてよいもの:

```text
- profile名
- region
- 認証refresh scriptの場所
- secretを取得する安全な方法
```

書いてはいけないもの:

```text
- access key
- secret key
- MFA seed
- password
- DB connection stringのcredential
```

skillはsecretの値ではなく、secretへ安全にアクセスする手順を持ちます。

## DB調査の具体例

症状:

```text
APIは200だが一覧が空
```

可能性:

- 本当にdataがない
- tenant contextが設定されていない
- RLSで見えない
- query条件が誤っている
- 誤ったenvironmentを見ている

調査順序:

```text
environment/account確認
  → requestのtenant context確認
  → read-only接続
  → RLS/session variable確認
  → 対象tableの存在確認
  → query条件確認
```

空結果を即座に「dataなし」と結論付けません。

## 非開発skillの具体例: 日次報告

`daily-standup` skillは、単に文章を生成するのではなく、sourceと出力規則を固定します。

```text
入力source:
- 今日更新したticket
- Git commit / PR
- 実行したtest
- blocker

出力:
- 完了したこと
- 継続中
- blockerと必要な支援
- 次に行うこと
```

生成例:

```markdown
## 完了
- 予約キャンセルAPIの認可testを追加した。
- PR #123を作成し、backend unit testを実行した。

## 継続中
- Web Booking側のerror表示を確認中。

## Blocker
- 当日キャンセル料金のAPI response仕様が未確定。
```

「かなり進みました」のような主観表現ではなく、ticket、commit、testなど追跡可能な事実へ結び付けます。

## 運用skillの完了条件

- [ ] environment、account、regionを確認した
- [ ] readとwrite操作を区別した
- [ ] 変更前の状態と証拠を保存した
- [ ] secretを表示・保存していない
- [ ] 変更操作の承認条件を満たした
- [ ] rollbackまたは復旧方法を確認した
- [ ] 実行結果と残riskを記録した
- [ ] 一時的な復旧と根本原因解決を区別した
