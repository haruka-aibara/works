tags: aws, s3, terraform, audit

# Object Lock は既存バケットにあとからかけられる

AWS は 2023 年 11 月から対応済み。
Terraform の `aws_s3_bucket` も v6.63.0 から、`object_lock_enabled = true` で作り直さなくなった（terraform-provider-aws #36530）。
`aws_s3_bucket_object_lock_configuration` なら、それ以前からその場で有効化できる。

## 前提

- 先にバージョニングを有効にする
- 一度有効にすると無効に戻せない
- `false` に戻すと、今でもバケットは作り直しになる

## 既存のオブジェクトは守られない

デフォルトの保持期間は、有効化した後に入れたオブジェクトにしか効かない。
既存分は S3 Batch Operations で保持期間を付ける。非現行バージョンも対象に含める。

バケットごと消えるのを防ぐなら、既存分は放っておいてもいい。
ロック中のオブジェクトが1つでも残れば、バケットは空にできない。

## force_destroy で消えるか

provider の `force_destroy` は、ロック中のオブジェクトも消そうとする。
コンプライアンスモードなら消せない。
ガバナンスモードは、`s3:BypassGovernanceRetention` を持つロールなら消せる。

関連：[証跡バケットに Object Lock をかける案](../ideas/2026-09-26-CloudTrail証跡バケットはTerraformのミスで消えるのでObject_Lockをかける.md)
