tags: aws, cloudtrail, guardduty, siem, detection, security

# AccessDenied の急増は偵察のサイン

盗んだクレデンシャルで何ができるかを、攻撃者は総当たりで試す。
すると短時間に `AccessDenied` が並ぶ。ふだんの運用ではまず起きない。

## まずマネージドで拾う

| 仕組み | 何を見るか |
|---|---|
| CloudTrail Insights（API エラーレート） | API ごとのエラー（`AccessDenied` など）の率が、直近 7 日の基準から跳ねたら Insights イベントを出す |
| GuardDuty `Discovery:IAMUser/AnomalousBehavior` | `Describe*` `Get*` `List*` などの偵察系 API が、その主体にとってふだんと違う呼ばれ方をしたら出す（ML） |

## 足りない分だけ自作する

上で拾えないのは次のときだけ。SIEM で数えるのはここに絞る。

- **主体ごと**の拒否件数で見たい（Insights は API 単位で、誰がやったかでは数えない）
- **拒否が続いたあとに成功**、という並びを拾いたい（通る権限を見つけた）

## ノイズ

権限の少ない人がコンソールを開くと、裏の読み取り API が大量に拒否される。人間のコンソール操作は除くか、しきい値を分ける。

Insights は追加料金。主体単位で数えない点は `ListInsightsMetricData` の仕様から読んだ範囲。
