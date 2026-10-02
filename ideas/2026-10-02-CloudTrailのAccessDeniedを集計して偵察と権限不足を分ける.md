tags: aws, cloudtrail, iam, duckdb, security

# CloudTrail の AccessDenied を集計して偵察と権限不足を分ける

`errorCode` が `AccessDenied` / `UnauthorizedOperation` のイベントは、2 種類の情報が混ざっている。

- 権限が足りなくて仕事が止まっている人・CI（最小権限の調整材料）
- 盗まれたクレデンシャルで「何ができるか」を総当たりしている攻撃者（偵察の兆候）

## 見分け方の仮説

- 短時間に、多くのサービスにまたがって Deny されている → 偵察っぽい
- 同じ API が毎日同じ時刻に Deny → CI の権限不足っぽい
- `List*` / `Describe*` / `Get*` ばかり Deny → 偵察っぽい

[DuckDB で手元に落とした証跡](2026-09-29-CloudTrailはDuckDBで手元に落として掘る.md) に、主体ごと・1時間ごとの「Deny されたサービス数」を数えるクエリを投げれば、どちらが多いかすぐ分かる。

## GuardDuty との関係

GuardDuty にも偵察系の検出はある。
差が出るのは、GuardDuty が拾わない「権限不足で詰まっている」側を同じ集計で見られること。
偵察の検知だけなら GuardDuty で足りるはずなので、自作する理由は権限調整のほう。
