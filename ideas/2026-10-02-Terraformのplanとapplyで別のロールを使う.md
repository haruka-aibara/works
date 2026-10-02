tags: aws, terraform, iam, hcp-terraform, security

# Terraform の plan と apply で別のロールを使う

Terraform の実行ロールは、たいていアカウントでいちばん強い。
しかも plan は PR ごとに走るので、いちばん頻繁に使われる。

HCP Terraform の動的認証は、plan 用と apply 用で別のロールを指定できる
（`TFC_AWS_PLAN_ROLE_ARN` / `TFC_AWS_APPLY_ROLE_ARN`）。

- plan 用：ReadOnly 相当。PR の段階で悪意のある provider やコードが動いても、書き込めない
- apply 用：強い権限。信頼ポリシーの `sub` を `run_phase:apply` に絞る

## 試すこと

- いまは `TFC_AWS_RUN_ROLE_ARN` の1本で両方を回している。分けたとき、plan が読めずに落ちるリソースがないか
- `data` ソースで秘密（Secrets Manager の値など）を読んでいると、plan 用にもその権限が要る。それ自体が見直しどころ
- Object Lock の話と同じく、apply ロールが強い限り事故は防げない。破壊系の操作は SCP 側で止める

関連：[CloudTrail 証跡バケットは Terraform のミスで消えるので Object Lock をかける](./2026-09-26-CloudTrail証跡バケットはTerraformのミスで消えるのでObject_Lockをかける.md)
