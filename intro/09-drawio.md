# 09. 応用 2: draw.io 構成図の自動化

この章で分かること:

- 図面を AI に描かせ、更新させ、差分でレビューできる理由
- 自分の環境に入れる手順と置き場所
- Mermaid との使い分け

## 何が嬉しいか

構成図は、いちど描かれた後に更新されない文書の代表です。設計が変わっても図は古いまま残り、新しい人が古い図を信じます。

draw.io のファイルの実体は XML のテキストです。テキストであるということは、次の 3 つがそのまま成り立ちます。

1. AI が直接生成・編集できる。「構成図を描いて」でスキルが起動する
2. コマンドラインで画像に変換できる。人の操作なしで PNG が出る
3. XML をコミットすれば、図面が **diff レビューとバージョン管理の対象**になる

3 番目が本質です。設計変更の PR に図の更新が含まれていなければ、コードレビューと同じく「図が追従していない」と指摘できます。図面が「ドキュメント腐敗の例外」ではなくなります。

## 入れる手順

### 1. CLI を入れる

draw.io のデスクトップアプリに CLI が同梱されています。

```bash
# macOS
brew install --cask drawio

# 動作確認（XML → PNG）
drawio -x -f png -o out.png diagram.drawio
```

Windows と Linux も公式の配布物にコマンドラインが含まれます。

### 2. スキルを置く

`.claude/skills/drawio-diagram/SKILL.md` を作ります。この repo のルートにある実物の要点は次の通りです。

```markdown
---
name: drawio-diagram
description: >
  構成図・シーケンス図を draw.io 形式（XML）で作成・更新し、CLI で画像にする。
  「構成図描いて」「図にして」「アーキテクチャ図を更新」で使う。
  文章で足りる説明や UI モックアップには使わない。
---

# draw.io 図面作成手順

## 手順
1. 図の目的と読者を確認する（何の判断に使う図か）。
2. `.drawio` XML を生成・編集する。既存図の更新なら既存 XML を読んでから差分で直す。
3. `drawio -x -f png -o <出力>.png <入力>.drawio` で描画して確認する。
4. XML はリポジトリにコミットし、画像は PR や設計書に添付する。
5. 設計変更に図が追従していなければ、レビューで指摘する。
```

### 3. 置き場所を決める

図は設計書（正本）の隣に置きます。図ごとにフォルダを作り、XML と画像と 1 行の説明をセットにします。

```text
specs/diagrams/
  system-context/
    system-context.drawio     ← 正本。コミットする
    system-context.png        ← 生成物。PR や文書に貼る
    README.md                 ← 何の判断に使う図か、1〜3 行
  api-sequence-cancel/
    api-sequence-cancel.drawio
    api-sequence-cancel.png
```

`CLAUDE.md` の「リポジトリの地図」に、図の置き場所を 1 行足します。

### 4. 動かして確かめる

```text
「会議室予約アプリの構成図を描いて。Web、API、DB、通知サービスの 4 つ」
  → specs/diagrams/system-context/ に .drawio と .png ができるか

「API から通知サービスへの矢印を非同期（キュー経由）に変えて」
  → 既存 XML を読んでから差分で直しているか。git diff で変更が数行に収まるか
```

2 つ目が重要です。図を作り直させると diff が全行になり、レビューできません。「既存 XML を読んでから直す」をスキルに書いてあるのは、このためです。

## テキストであることの実感

draw.io の XML は、箱と線が 1 要素ずつ並んだだけの構造です。

```xml
<mxCell id="web" value="Web 画面" style="rounded=1;" vertex="1" parent="1">
  <mxGeometry x="40" y="40" width="120" height="60" as="geometry"/>
</mxCell>
<mxCell id="api" value="API サーバー" style="rounded=1;" vertex="1" parent="1">
  <mxGeometry x="240" y="40" width="120" height="60" as="geometry"/>
</mxCell>
<mxCell id="e1" edge="1" source="web" target="api" parent="1">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```

「API サーバー」を「予約 API」に改名すれば diff は 1 行です。この単純さが、AI に扱わせられる理由です。

## Mermaid との使い分け

どちらもテキストなので、AI 駆動開発との相性は同じです。違いは見た目の制御です。

| | Mermaid | draw.io |
|---|---|---|
| 配置 | 自動。手で動かせない | 座標を持つ。人が draw.io で微調整できる |
| 表示 | GitHub や多くの文書ツールがそのまま描画 | 画像に変換して貼る |
| 向く図 | 小さなフロー図、シーケンス図、状態遷移 | 要素が多い構成図、顧客向けの見栄えが要る図 |
| diff | 短く読みやすい | 座標が含まれるためやや長い |

迷ったら、文書に埋め込む小さな図は Mermaid、独立して配布する構成図は draw.io です。本編 02 章は Mermaid を第一候補にしています。両方使って構いません。

## 限界と対処

- **配置の美しさは AI 任せだと崩れます**。人が draw.io で位置を直し、その XML をコミットすれば、次回 AI はそこから差分で直します
- **要素が 30 を超える図は分割**します。1 枚に全部入れると AI も人も追えません
- **画像はレビュー対象にしません**。レビューするのは XML の diff と、描画結果の目視です

## 発表での見せ方

1. 「構成図描いて」でスキルが起動するのを見せる。仕組みは 02 章と同じ、と一言
2. 生成された PNG を開く
3. 「通知を非同期に変えて」と打ち、`git diff` で変更が数行なのを見せる
4. 「図面が diff とレビューの対象になった。だから腐らない」で締める

事前に `drawio` コマンドが通ることを確認し、生成済みの PNG を予備として用意しておきます。

詳しくは本編 `../12-live-demo-walkthrough.md` の 12.5 と、実物 `../.claude/skills/drawio-diagram/SKILL.md` を参照してください。
