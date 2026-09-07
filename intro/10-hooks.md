# 10. 応用 3: フックで「絶対にやらせないこと」を機械的に止める

この章で分かること:

- 文書に「禁止」と書いても止まらない理由と、フック（hook）が止められる理由
- 絶対にやらせてはいけない操作の一覧と、それを止める実際のスクリプト
- 「止める」と「注意する」の使い分け、フック自身の安全性

## 「禁止」と書いても止まらない

`CLAUDE.md` に「生成されたファイルは手で直さない」と書いてあっても、AI は忘れることがあります。長い作業の途中でコンテキストが薄まったとき、急いでいるとき、指示が別のルールと競合したときです。人と同じです。

02 章で「入口・ルール・スキルは AI へ渡す指示であり、強制ではない」と書きました。08 章では AWS 側を IAM で止めました。この章はリポジトリの中の操作を止めます。

```text
注意書き   → 読まれれば効く。読み飛ばされたら効かない
権限 (IAM) → AWS への操作を物理的に止める          … 08 章
フック     → ファイル編集・コマンド実行を直前で止める … この章
```

## フックとは

フックは、AI がツール（ファイル編集、コマンド実行など）を使う直前・直後に、自動で走るスクリプトです。AI の自己申告ではなく、実際の操作に割り込みます。

```text
AI が「このファイルを編集する」と決める
  ↓
クライアントが PreToolUse フックを呼ぶ（標準入力に JSON: ツール名と引数）
  ↓
フックが判定
  ├─ exit 0 → 編集が実行される
  └─ exit 2 → 編集は実行されず、標準エラー出力の文がそのまま AI に返る
  ↓
クライアントが PostToolUse フックを呼ぶ（lint や整形など）
```

| 種別 | タイミング | 向くこと |
|---|---|---|
| PreToolUse | 実行の直前 | 危険な操作を止める。注意を差し込む |
| PostToolUse | 実行の直後 | 編集したファイルだけ lint する。整形する |

大事なのは exit 2 のときの文です。AI はその文を読んで次の行動を決めるので、「禁止」だけでなく「代わりにどうするか」を書きます。そうすると AI は止まったまま固まらず、正しい手順に戻ります。

## 絶対にやらせてはいけない操作

止めるべきものは、失敗したときに取り返しがつかないものです。会社ごとに違いますが、たいてい次の 4 種類に収まります。

| 種類 | 例 | なぜ取り返しがつかないか |
|---|---|---|
| 生成物の手編集 | `generated/`、`dist/`、lock ファイル | 次の再生成で消える。元の定義とズレが残る |
| 履歴・ファイルの破壊 | `rm -rf /`、`git push --force`、`git reset --hard` | 復元できない。他人の作業も消える |
| インフラ・DB の破壊 | `terraform apply`、`DROP TABLE`、`aws ... delete` | 本番に即反映される |
| 秘密情報の露出 | `cat .env`、鍵ファイルの表示 | 一度ログや会話に出た値は回収できない |

「調査はしてよいが変更はだめ」という線引きは 08 章の読み取り専用と同じ考え方です。

## 実際のフック

この repo のルートに動く実物を置いています。

```text
.claude/
  settings.json                       ← どのイベントでどのスクリプトを呼ぶか
  hooks/
    block-generated-edit.sh           ← 生成物への編集を拒否
    block-dangerous-commands.sh       ← 危険コマンドを拒否
```

### 1. 生成物への編集を止める

`.claude/hooks/block-generated-edit.sh` の要点です。

```bash
#!/usr/bin/env bash
set -eu
file_path=$(jq -r '.tool_input.file_path // empty')   # 標準入力の JSON から対象パスを取る
[ -z "$file_path" ] && exit 0

case "$file_path" in
  */generated/*|*/dist/*|*/build/*|*.lock|*/node_modules/*)
    cat >&2 <<MSG
拒否: 生成物 ($file_path) は手で編集できません。
次の手順で対応してください:
  1. 元になる定義 (OpenAPI、schema、package.json など) を修正する
  2. 生成コマンドを実行する (例: pnpm generate:api-client)
  3. 生成された差分を確認する
MSG
    exit 2
    ;;
esac
exit 0
```

パスの判定だけです。AI がどんな理由を持っていても、このパスへの編集は通りません。

### 2. 危険コマンドを止める

`.claude/hooks/block-dangerous-commands.sh` は、実行しようとしたコマンド文字列をパターンで判定します。抜粋です。

```bash
cmd=$(jq -r '.tool_input.command // empty')

deny() {
  cat >&2 <<MSG
拒否: このコマンドはフックで禁止されています。
  理由: $1
  コマンド: $cmd
実行が本当に必要なら、AI ではなく人がターミナルで実行してください。
MSG
  exit 2
}

echo "$cmd" | grep -Eq 'git[[:space:]]+push[[:space:]].*(--force|-f)([[:space:]]|$)' \
  && deny "force push は履歴を破壊する"
echo "$cmd" | grep -Eq 'terraform[[:space:]]+(destroy|apply)' \
  && deny "terraform の適用・破棄は人が plan を確認してから実行する"
echo "$cmd" | grep -Eiq '(drop[[:space:]]+(table|database|schema)|truncate[[:space:]]+table)' \
  && deny "テーブル・DB の削除"
```

`terraform plan` は通り、`terraform apply` は止まります。`aws ecs describe-services` は通り、`aws ecs delete-service` は止まります。「調べるのは自由、変えるのは人」を機械にしたものです。

### 3. 設定でつなぐ

スクリプトを置くだけでは動きません。`.claude/settings.json` で、どのツールのときに呼ぶかを登録します。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/block-generated-edit.sh", "timeout": 10 }]
      },
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/block-dangerous-commands.sh", "timeout": 10 }]
      }
    ]
  }
}
```

`matcher` がツール名、`command` が呼ぶスクリプトです。設定の形やイベント名はクライアントのバージョンで変わるので、導入時は公式ドキュメントで確認してください。

## 動作を確認する

フックはスクリプトなので、AI を介さずに直接テストできます。標準入力に JSON を渡し、終了コードを見ます。

```bash
echo '{"tool_input":{"command":"terraform apply"}}' | bash .claude/hooks/block-dangerous-commands.sh
echo "exit=$?"    # → 拒否メッセージが出て exit=2

echo '{"tool_input":{"command":"terraform plan"}}' | bash .claude/hooks/block-dangerous-commands.sh
echo "exit=$?"    # → 何も出ず exit=0
```

この repo のフックは、止めるべき 11 ケースと通すべき 7 ケースの表でテストしてあります。「正しい操作を誤って止めない」テストが特に重要です。止めすぎるフックは、人も AI も外し方を探し始めます。

AI に直接頼んで確かめる方法もあります。

```text
「generated/api.ts のタイポを直して」
  → 編集が拒否され、AI が「OpenAPI を直して再生成します」と手順を切り替えるか

「本番の予約テーブルを空にして」
  → コマンドが拒否され、AI が「人が実行してください」と止まるか
```

## 止めるものと、注意するだけのもの

すべてを exit 2 で止めてはいけません。

| 判定 | 使い方 | 例 |
|---|---|---|
| 機械的に正誤が決まる | 止める（exit 2） | 生成物の編集、force push、`DROP TABLE` |
| 意味を理解しないと決まらない | 注意だけ（exit 0 で文を出す） | 「業務ルールを編集しています。設計書との整合を確認してください」 |

「設計書を変えたら必ず ADR を作る」を止める側に入れると、誤字修正まで止まります。こういうものは注意にとどめ、判断は AI とレビューに残します。注意も乱発すると、AI は人と同じように無視し始めます。

## フック自身の安全性

フックは AI の入力を受けて shell を動かすので、フック自体が穴になり得ます。

- 入力をそのまま shell に展開しない。`jq` で取り出し、必ず引用符で囲む
- 秘密情報やファイル内容をログに出さない
- ネットワーク送信や本番操作をフックの中でしない
- 重いテストを毎回の編集で走らせない。`timeout` を付ける
- 他人が置いたフックは、信頼する前に中身を読む

## 一つに頼らない

フックはクライアント依存で、設定を外せば無効になります。重要な禁止事項は複数の層で守ります。

```text
生成物の手編集を防ぐ
  ├─ CLAUDE.md に理由を書く     … AI が正しい手順を知る
  ├─ フックで即時に拒否する     … 編集の瞬間に止める
  └─ CI で再生成との差分を見る … すり抜けても merge 前に検出する
```

08 章の権限、この章のフック、次章で扱うテストとレビューが重なって、初めて「注意力に依存しない」状態になります。

## 発表での見せ方

1. `CLAUDE.md` の「生成物は手編集しない」の行を見せ、「これだけでは止まらない」と言う
2. ターミナルで `echo ... | bash .claude/hooks/block-dangerous-commands.sh` を打ち、`terraform apply` が止まり `terraform plan` が通るのを見せる
3. 拒否メッセージに「代わりの手順」が入っていることを指す
4. 「AWS は IAM、リポジトリはフック。どちらもプロンプトではなく機械が保証する」で締める

詳しくは本編 `../10-hooks-and-machine-guards.md` と、実物 `../.claude/settings.json`、`../.claude/hooks/` を参照してください。
