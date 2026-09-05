---
name: drawio-diagram
description: >
  構成図・シーケンス図を draw.io 形式（XML）で作成・更新し、CLI で画像にレンダリングする。
  Triggers on: "構成図描いて", "図にして", "アーキテクチャ図を更新", "diagram", "/drawio-diagram".
  NOT for: 文章だけで足りる説明、UI モックアップ。
---

# draw.io 図面作成手順

## 前提: draw.io の実体はテキスト（XML）

だから AI が直接生成・編集でき、コードと同じく diff レビューとバージョン管理ができる。

## 手順

1. 図の目的と読者を確認する（何の判断に使う図か）。
2. `.drawio` XML を生成・編集する。既存図の更新なら**既存 XML を読んでから**差分で直す。
3. CLI でレンダリングして確認する:
   ```bash
   drawio -x -f png -o out.png diagram.drawio
   # macOS: brew install --cask drawio
   ```
4. XML はリポジトリにコミット（差分管理）、画像は PR や設計書に添付する。
5. 設計変更に図の更新が追従していない場合は、コードレビューと同じく指摘対象にする。
