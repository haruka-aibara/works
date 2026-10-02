tags: aws, iam-identity-center, iam, security, jit

# 本番の強い権限は Identity Center で申請制の一時付与にする

本番の Admin 権限セットを常時割り当てていると、使わない日もずっと持っていることになる。
資格情報が盗まれたときの被害は、持っている時間に比例する。

申請 → 承認 → 数時間だけ割り当て → 自動で外す、にすれば常時持つ人がいなくなる。
誰が、いつ、なぜ使ったかの記録も申請の形で残る。

## 選択肢

- **TEAM**（AWS の OSS、Temporary Elevated Access Management）：Identity Center 用の申請・承認画面が丸ごとついてくる。ただし Amplify のアプリを自分で保守する
- **IdP 側の機能**：Entra ID の PIM や Okta のアクセス申請でグループ所属を一時付与し、SCIM で Identity Center に流す。IdP の契約があるならこちらが素直
- **自作**：Slack ワークフローで承認 → Lambda が `CreateAccountAssignment`、Step Functions で数時間後に `DeleteAccountAssignment`。部品は少ないが、保守するのは自分

比べる軸は「申請画面と期限切れの外し忘れ対策を、誰が保守するか」。

## 気をつけること

- 外す処理が失敗すると、常時付与に戻る。割り当ての棚卸しは別で回す
- 障害対応中に承認者がつかまらない。ブレイクグラス用の経路は別に残す
