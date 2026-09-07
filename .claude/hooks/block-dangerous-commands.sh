#!/usr/bin/env bash
# PreToolUse (Bash): 取り返しのつかないコマンドを実行前に拒否する。
# 「本番を壊さないでください」と文書に書く代わりに、パターンで機械的に止める。
set -eu

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

deny() {
  cat >&2 <<MSG
拒否: このコマンドはフックで禁止されています。
  理由: $1
  コマンド: $cmd
実行が本当に必要なら、AI ではなく人がターミナルで実行してください。
MSG
  exit 2
}

# 1. ファイルシステムの破壊
echo "$cmd" | grep -Eq '(^|[;&|[:space:]])rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)[[:space:]]+(/|~|\$HOME|\.\.)' \
  && deny "ルート・ホーム・親ディレクトリへの再帰削除"

# 2. Git 履歴の破壊
echo "$cmd" | grep -Eq 'git[[:space:]]+push[[:space:]].*(--force|-f)([[:space:]]|$)' \
  && deny "force push は履歴を破壊する"
echo "$cmd" | grep -Eq 'git[[:space:]]+(reset[[:space:]]+--hard|clean[[:space:]]+-[a-zA-Z]*f|branch[[:space:]]+-D)' \
  && deny "未コミットの変更やブランチを失う操作"

# 3. インフラ・DB への破壊的操作
echo "$cmd" | grep -Eq 'terraform[[:space:]]+(destroy|apply)' \
  && deny "terraform の適用・破棄は人が plan を確認してから実行する"
echo "$cmd" | grep -Eiq '(drop[[:space:]]+(table|database|schema)|truncate[[:space:]]+table)' \
  && deny "テーブル・DB の削除"
echo "$cmd" | grep -Eq 'aws[[:space:]]+[a-z0-9-]+[[:space:]]+(delete|terminate|remove|stop|reboot)[a-z-]*' \
  && deny "AWS リソースの削除・停止 (読み取り専用プロファイルの範囲を超える)"

# 4. 秘密情報の露出
echo "$cmd" | grep -Eq '(cat|less|more|head|tail|bat)[[:space:]]+[^|]*(\.env([./]|$)|credentials|id_rsa|\.pem([[:space:]]|$))' \
  && deny "秘密情報ファイルの内容表示 (値ではなく取得手順を扱う)"

exit 0
