tags: aws, iam, sts, cloudtrail, audit, security

# ロールを乗り継いでも誰がやったか分かるように SourceIdentity を強制する

インシデント調査で CloudTrail を掘ると、`AssumedRole` のセッション名しか残っておらず、
誰がやったかを AssumeRole の記録から逆にたどる羽目になる。
もう 1 段乗り継がれると、セッション名は呼び出し側が好きに付けられるので当てにならない。

## SourceIdentity なら

- 最初の AssumeRole で付けた値が、乗り継いでも引き継がれ、後から変えられない
- CloudTrail の各イベントに載るので、1 件見るだけで人を特定できる
- 信頼ポリシーの `sts:SourceIdentity` 条件で、付けていない AssumeRole を拒否できる

## どこで付けるか

- SAML の IdP 連携なら、IdP の属性マッピングで社員 ID を入れる
- CLI で直接 AssumeRole するなら `--source-identity` を付け、信頼ポリシーで強制する
- 信頼ポリシーに `sts:SetSourceIdentity` の許可も要る

## 気をつけること

- IAM Identity Center 経由で自動で入るかは未確認
- いきなり全ロールで強制すると自動化が止まる。まず付いていない AssumeRole を CloudTrail で数える

関連：[CloudTrail は DuckDB で手元に落として掘る](./2026-09-29-CloudTrailはDuckDBで手元に落として掘る.md)
