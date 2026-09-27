tags: aws, cloudtrail, s3, terraform, audit

# CloudTrail 証跡バケットは Terraform のミスで消えるので Object Lock をかける

証跡バケットに Object Lock をかける理由は、外部攻撃より先に「Terraform で自分が消す」事故がある。

## 消える経路

- `force_destroy = true` のまま `terraform destroy`、またはリソース名の変更で `moved` ブロックを書き忘れて作り直しになる。中身ごと消える
- `lifecycle { prevent_destroy = true }` は、リソースブロックがコードに残っている間しか効かない。ブロックごと消す・モジュールを外すと素通りする

## Object Lock で何が変わるか

- コンプライアンスモードなら、保持期間中はルートユーザーでもオブジェクトを消せない。消せないオブジェクトが残るのでバケットも消えない
- ガバナンスモードは `s3:BypassGovernanceRetention` を持つ人が消せる。Terraform の実行ロールが強い権限を持つなら事故防止にならない

## 気をつけること

- コンプライアンスモードは、間違えても保持期間が終わるまで消せず費用もかかる。最初は短い期間で試す
- バージョニングが必須

関連：[CloudTrail ログファイル検証を定期実行する](./2026-09-26-CloudTrailログファイル検証を定期実行する.md)
