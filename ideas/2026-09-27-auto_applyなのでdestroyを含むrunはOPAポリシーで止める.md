tags: terraform, hcp-terraform, opa, policy-as-code, operations

# auto_apply なので destroy を含む run は OPA ポリシーで止める

`works` ワークスペースは `auto_apply = true`。
main にマージされると、plan を人が見る段階を挟まずに apply される。
PR の plan で「1 to destroy」を見落とせば、そのまま消える。

HCP Terraform の Free でも、ポリシーセット1つ（ポリシー5本まで）は使える。
「`resource_changes[].change.actions` に `delete` を含む run を止める」ポリシーを1本だけ置く。
`["delete", "create"]` の作り直しもここで引っかかる。

## Object Lock との役割分担

[証跡バケットの Object Lock](2026-09-26-CloudTrail証跡バケットはTerraformのミスで消えるのでObject_Lockをかける.md) は、消えても中身を残すための最後の砦。
このポリシーは、その手前で消す操作自体を止めるためのもの。

## 未確認

- 意図して消すときの逃がし方。「使わなくなったら `main.tf` の呼び出しをコメントアウトして止める」運用も destroy になるので、全部止めると自分の運用とぶつかる。OPA の mandatory が Free で override できるかを確認する。できないなら、対象を `aws_s3_bucket` などに絞る
- Free でポリシーセットを tfe provider から作れるか。VCS 連携のポリシーセットは Standard 以上らしい
