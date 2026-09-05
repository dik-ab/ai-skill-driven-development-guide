---
paths:
  - "apps/backend/**"
---

# Backend ルール

`apps/backend/**` を触るタスクでのみ読み込まれる（frontmatter の `paths` でスコープ）。

- レイヤーは `domain` / `application` / `infrastructure` / `presentation`。依存は外→内のみ。
- domain 層は framework（DI・ORM・HTTP）に依存しない。
- UseCase は `VerbNounUseCase` 命名。HTTP DTO は `presentation/dto` に置く。
- 書き込みは Aggregate Root 経由 + `Repository.save(aggregate)`。
  操作別の raw な insert/update メソッドを増やさない。
- アーキテクチャ違反はテスト（ArchUnit 相当）で落ちる。green でも「設計書準拠」とは限らない
  ——配置が正しくても中身が設計と違うことはある。設計書との照合は別途行う。
