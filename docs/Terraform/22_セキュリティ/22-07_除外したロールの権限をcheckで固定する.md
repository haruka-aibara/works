# 除外したロールの権限を check で固定する

SCP やバケットポリシーで、特定のロールだけを Deny から除外することがある。
除外は「どのロールか」に効き、そのロールの中身は見ていない。
除外したあとに信頼ポリシーやアタッチしたポリシーが変わっても、除外は効き続ける。

確認した時点の権限を JSON でリポジトリに置き、`check` ブロックで今の値と比べる。
変わっていれば、普段の `terraform plan` の最後に警告が出る。

## 比べるもの

| 対象 | データソース | 比べ方 |
|---|---|---|
| 信頼ポリシー | `aws_iam_role` の `assume_role_policy` | 中身すべて |
| アタッチした管理ポリシー | `aws_iam_role_policy_attachments` と `aws_iam_policy` の `policy` | どれが付いているかと、それぞれの中身すべて |
| インラインポリシー | `aws_iam_role_policies` | 1つも付いていないこと |

`aws_iam_policy` の `policy` はデフォルトバージョンの中身を返す。
AWS 管理ポリシーを AWS が更新して権限が広がった場合も、これで気づける。
この経路は CloudTrail にも Terraform のドリフトにも出てこない。

インラインポリシーは中身を取るデータソースが見当たらないので、付けない運用にして「ないこと」だけを見る。

## コード

```hcl
locals {
  approved = jsondecode(file("${path.module}/approved/breakglass.json"))
}

data "aws_iam_role" "breakglass" {
  name = "breakglass"
}

data "aws_iam_role_policies" "breakglass" {
  role_name = "breakglass"
}

data "aws_iam_role_policy_attachments" "breakglass" {
  role_name = "breakglass"
}

data "aws_iam_policy" "breakglass" {
  for_each = toset(data.aws_iam_role_policy_attachments.breakglass.attached_policies[*].policy_arn)
  arn      = each.key
}

check "breakglass_unchanged" {
  assert {
    condition     = jsonencode(jsondecode(data.aws_iam_role.breakglass.assume_role_policy)) == jsonencode(local.approved.trust)
    error_message = "breakglass の信頼ポリシーが確認時点から変わった"
  }

  assert {
    condition     = length(data.aws_iam_role_policies.breakglass.policy_names) == 0
    error_message = "breakglass にインラインポリシーが付いた"
  }

  assert {
    condition     = jsonencode({ for arn, p in data.aws_iam_policy.breakglass : arn => jsondecode(p.policy) }) == jsonencode(local.approved.managed)
    error_message = "breakglass の管理ポリシー（付け外し・中身）が確認時点から変わった"
  }
}
```

`approved/breakglass.json` の形。

```json
{
  "trust": { "Version": "2012-10-17", "Statement": [] },
  "managed": {
    "arn:aws:iam::aws:policy/ReadOnlyAccess": { "Version": "2012-10-17", "Statement": [] }
  }
}
```

比べる前に両側を `jsonencode(jsondecode(...))` に通す。
空白とキーの順番の差を吸収でき、`==` が型まで比べる問題も避けられる。

## 運用

- 権限を絞る変更でも警告が出る。「確認した時点から変わったか」を見る仕組みなので、それでよい
- 変更に問題がなければ JSON を更新する PR を出す。それが再確認の記録になる
- 警告なので plan も apply も止まらない
- plan を実行したときにしか気づけない。plan がよく走るワークスペースに置く
- データソースを `check` の外に置いているので、ロールが消えると plan がエラーになる

## 追加するなら：アクセス許可の境界

アクセス許可の境界を使っているロールなら、外されると権限が広がる。
JSON に `permissions_boundary` を足し、assert を1つ足す。

```hcl
assert {
  condition     = data.aws_iam_role.breakglass.permissions_boundary == local.approved.permissions_boundary
  error_message = "breakglass のアクセス許可の境界が確認時点から変わった"
}
```

## 合わせてやること

- 除外を `aws:PrincipalArn` で書くと、同じ名前で作り直されたロールにも効く。
  `aws:userid`（`AROA...:*`）で書けば、作り直すと一意な ID が変わるので除外から外れる
- 除外したロールの信頼ポリシーやポリシーの変更は、SCP で Terraform の実行ロール以外に禁止する。
  中身の変更が Terraform のコードの変更と同じ意味になり、PR のレビューで止められる

## 未確認

- `aws_iam_role` の `assume_role_policy` が URL エンコードされずに JSON のまま返るか
- `aws:userid` を SCP の条件で使ったときに、上のとおりに動くか
