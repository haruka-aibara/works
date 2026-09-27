# aws-config-custodian

[Cloud Custodian](https://cloudcustodian.io/)（c7n）のポリシーを、AWS Config のカスタムルールとしてデプロイするモジュール。
判定ロジックは c7n 本体を使い、Lambda のコードは書かない。
デプロイは c7n の CLI ではなく Terraform が行う。

`policies/` に YAML を 1 つ置くと、Config ルールが 1 本増える。
