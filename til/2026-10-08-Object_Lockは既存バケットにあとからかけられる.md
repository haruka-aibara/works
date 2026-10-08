tags: aws, s3, terraform, audit

# Object Lock は既存バケットにあとからかけられる

AWS では 2023 年 11 月から、既存のバケットにも Object Lock を有効化できる。
Terraform の AWS provider は v6.63.0 から、`aws_s3_bucket` の `object_lock_enabled` を `true` にしてもバケットを作り直さなくなった（[#36530](https://github.com/hashicorp/terraform-provider-aws/issues/36530)）。
それより前は、作り直しの差分が出ていた。
`aws_s3_bucket_object_lock_configuration` なら、v6.63.0 より前からその場で有効化できる。

## かけるときの前提

- 先にバージョニングを有効にしておく
- 一度有効にすると無効に戻せず、バージョニングも止められない
- `object_lock_enabled` を `true` から `false` に戻すと、今でもバケットは作り直しになる

## 既存のオブジェクトは守られない

デフォルトの保持期間が効くのは、有効化した後に入れたオブジェクトだけ。
既存のオブジェクトも守るなら、S3 Batch Operations の Object Lock retention 操作で、1つずつ保持期間を付ける。
保持期間はバージョンごとに付くので、非現行バージョンも守るなら、それらも対象に含める。

バケットごと消えるのを防ぐだけなら、既存分は放っておいてもいい。
ロック中のオブジェクトが1つでも残っていれば、バケットは空にできない。

## force_destroy で消えるかはモードと権限しだい

provider の `force_destroy` は、ロック中のオブジェクトも消そうとする。
コンプライアンスモードなら消せない。
ガバナンスモードは、`s3:BypassGovernanceRetention` を持つロールなら消せる。
Terraform の実行ロールがこの権限を持っていると、事故を防げない。

関連：[CloudTrail 証跡バケットは Terraform のミスで消えるので Object Lock をかける](../ideas/2026-09-26-CloudTrail証跡バケットはTerraformのミスで消えるのでObject_Lockをかける.md)

v6.63.0 より前に、コンソールで有効化してからコードを `true` に合わせた場合に No changes になったかは未確認。
