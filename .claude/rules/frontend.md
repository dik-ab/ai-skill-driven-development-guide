---
paths:
  - "apps/frontend/**"
---

# Frontend ルール

`apps/frontend/**` を触るタスクでのみ読み込まれる（frontmatter の `paths` でスコープ）。

- named export を基本にする。framework が default export を要求する場合のみ例外。
- API 型は生成クライアントを使う。生成物 `packages/api-client/generated/**` は手編集しない。
- 表示項目を指示なく増やさない。UI 変更はチケットに書かれた範囲だけ。
- コンポーネント変更時は対応するテストと Storybook の有無を確認し、無ければ追加する。
