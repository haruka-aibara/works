tags: aws, iam, sts, cloudtrail, ai, audit

# AI エージェントの AWS 操作は SourceIdentity で人間と見分ける

AI エージェントに AWS を触らせると、CloudTrail 上は同じロールを人間が使ったのと区別がつかない。
事故のとき、まず知りたいのは「人間か AI か」。

`AssumeRole` のときに `SourceIdentity` を付けると、CloudTrail の各イベントにその値が残る。
一度付けたら、ロールを乗り継いでも引き継がれ、書き換えられない。
セッションタグと違って後から上書きされない点が監査向き。

## やること

- 信頼ポリシーで `sts:SetSourceIdentity` を許し、条件で `ai-agent-*` のような命名を強制する
- 人間は Identity Center のユーザー名、AI は `ai-agent-<名前>` を入れる
- 条件で `sts:SourceIdentity` を必須にし、付けずに AssumeRole させない

[DuckDB で掘る](./2026-09-29-CloudTrailはDuckDBで手元に落として掘る.md) ときに、`sourceIdentity LIKE 'ai-agent-%'` だけで AI の操作を全部抜き出せる。

## 前提との関係

いまは「AI は AWS に接続しない」方針なので、すぐには要らない。
DevOps Agent のように AWS 側で AI が動くものを入れる日に、最初にやることとして取っておく。
マネージドなエージェントが SourceIdentity を付けられるかは未確認。
