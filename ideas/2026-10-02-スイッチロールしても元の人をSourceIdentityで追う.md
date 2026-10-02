tags: aws, iam, identity-center, cloudtrail, audit

# スイッチロールしても元の人を SourceIdentity で追う

Identity Center で入った人がさらに別のロールへスイッチすると、CloudTrail の `userIdentity` には最後のロールのセッションしか出ない。
「誰がやったか」を追うには、セッション名や `AssumeRole` のイベントを辿り直すことになる。

`sts:SourceIdentity` を使うと、最初に設定した値がロールチェーンをまたいで引き継がれ、途中で書き換えられない。
CloudTrail の `userIdentity.sessionContext.sourceIdentity` に、全イベントで元の人が残る。

## やること

- 信頼ポリシーで `sts:SetSourceIdentity` を許可し、条件で値の形式を縛る
- Identity Center 経由なら、ユーザー名が SourceIdentity に入るか確認する（未確認）
- 人間が使うロールは、SourceIdentity なしの AssumeRole を Deny する

## 効くところ

[CloudTrail を DuckDB で掘る](2026-09-29-CloudTrailはDuckDBで手元に落として掘る.md) ときに、`sourceIdentity` で GROUP BY するだけで人単位の操作が出る。
インシデント調査と、ISMS の「利用者の操作ログ」の説明が両方楽になる。
