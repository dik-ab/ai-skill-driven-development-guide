# hooks と機械的ガード

ルールを文書に書いても、AI は読み飛ばすことがあります。「文書で頼む」より「機械的に検知する」方が確実です。この章は、AI の編集や操作に対して決定論的に働くガードの作り方を扱います。

優先順位はこうです。

1. CI で落とせるものは CI に置く。
2. 編集の瞬間に検知したいものは hook に置く。
3. 機械化できない判断だけを、rule / skill の文書と人間レビューに残す。

## hook とは

hook は、AI エージェントのツール実行（ファイル編集、コマンド実行など）の前後で自動実行されるスクリプトです。AI の自己申告に頼らず、実際の操作に対して割り込めます。

| 種別 | タイミング | 主な用途 |
|---|---|---|
| PreToolUse | ツール実行の直前 | 注意喚起、危険な操作のブロック |
| PostToolUse | ツール実行の直後 | lint、フォーマット、検証の即時実行 |

## blocking 型と advisory 型

hook には 2 つの強さがあり、使い分けが重要です。

**blocking 型**: 違反を検出したらエラーとして返し、AI に修正を強制します。

例: 編集されたファイルを即座に lint し、失敗したらエラー内容を AI に返す。

```bash
#!/bin/bash
# PostToolUse (Edit|Write): 編集ファイルを単体 lint する
file_path=$(jq -r '.tool_input.file_path')
case "$file_path" in
  *node_modules*|*dist*|*generated*) exit 0 ;;
  *.ts|*.tsx|*.js|*.jsx) ;;
  *) exit 0 ;;
esac
if ! lint_output=$(pnpm exec eslint "$file_path" 2>&1); then
  echo "$lint_output" >&2
  exit 2   # AI にエラーとしてフィードバックされる
fi
```

**advisory 型**: 処理は通しつつ、注意だけを AI に注入します。判断が文脈依存で、機械的に正誤を決められない時に使います。

例: SSoT 文書の編集時に、連動して更新すべき文書を思い出させる。

```bash
#!/bin/bash
# PreToolUse (Edit|Write): SSoT 編集時のリマインダー
file_path=$(jq -r '.tool_input.file_path')
if [[ "$file_path" == *"businessRules"* ]]; then
  echo "SSoT レイヤー 1 を編集しています。specs 側の追随更新が必要か確認してください。"
elif [[ "$file_path" == *"01_domain_model_spec"* || "$file_path" == *"05_api_spec"* ]]; then
  echo "設計 SSoT を編集しています。businessRules との整合を確認してください。"
fi
exit 0   # ブロックしない
```

使い分けの基準:

- 正誤が機械的に決まる（lint、型、生成物の手編集禁止）→ blocking。
- 「確認してほしい」レベルの文脈依存判断 → advisory。
- advisory を乱発しない。毎回同じ注意が出ると、AI も人間と同じように無視し始めます。

## hook に向くもの

- 編集ファイルの単体 lint / format（プロジェクト全体ではなく該当ファイルだけ。速度が重要）。
- 生成物ディレクトリ（API client、ビルド成果物）への手編集の拒否。
- SSoT・正本文書の編集時の整合性リマインド。
- 危険コマンド（本番向け操作、破壊的操作）の実行前確認。

## パススコープ付き rule

rule はすべてを常時読み込ませるのではなく、対象パスに触れた時だけ有効化します。rule ファイルの frontmatter に対象 glob を書きます。

```markdown
---
paths:
  - "apps/backend/**"
---

# バックエンドルール
...
```

これにより:

- フロントエンド作業中にバックエンドルールがコンテキストを占有しない。
- rule を領域ごとに分割する基準が「パスで切れるか」になり、分割が明確になる。

## MCP サーバー

繰り返し使う決定論的処理は、shell script のほかに MCP（Model Context Protocol）サーバーとして提供する選択肢があります。

script との使い分け:

| 形態 | 向くもの |
|---|---|
| script | 単発の変換、集計、検証。入出力がファイル |
| MCP サーバー | 状態を持つ処理、対話的に何度も呼ぶ処理、複数ツールから共有したい処理 |

MCP サーバーを導入したら、リポジトリの `mcp.json` などの設定ファイルとサーバー実体の場所を一致させ、README に起動要件を書きます。設定だけ残ってサーバー実体が消えている状態は、AI が毎回接続エラーを踏む原因になります。

## 操作の監査ログ

AI にツール操作をさせる範囲が広がるほど、「いつ、どのツールを、どのパラメータで呼んだか」の記録が重要になります。

- MCP サーバーや script 側で、呼び出しを JSONL に記録する（timestamp、tool、params、result summary）。
- ログは `.claude/logs/` など決まった場所に日付単位で置く。
- インシデント調査だけでなく、「AI がどの操作でつまずくか」の改善データとして使う。

## 権限の絞り込み

エージェント設定（`settings.json` など）で、使わせないツールを明示的に拒否できます。

- そのリポジトリで使う理由がないツールは deny に入れる（例: notebook 編集、外部送信系）。
- 破壊的コマンドは許可リスト方式にし、都度確認へ倒す。
- 「禁止事項」を文書に書くだけでなく、可能なものは設定で機械的に塞ぐ。
