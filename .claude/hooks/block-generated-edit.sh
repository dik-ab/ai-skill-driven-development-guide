#!/usr/bin/env bash
# PreToolUse (Edit|Write|MultiEdit): 生成物ディレクトリへの手編集を拒否する。
# 標準入力に JSON が渡される。tool_input.file_path を読み、禁止パスなら exit 2 で止める。
# exit 2 のとき、標準エラー出力の内容が AI にエラーとして返る。
set -eu

file_path=$(jq -r '.tool_input.file_path // empty')
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
