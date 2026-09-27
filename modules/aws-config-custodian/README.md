# aws-config-custodian

[Cloud Custodian](https://cloudcustodian.io/)（c7n）のポリシーを、AWS Config のカスタムルールとしてデプロイするモジュール。
判定ロジックは c7n 本体を使い、Lambda のコードは書かない。
デプロイは c7n の CLI ではなく Terraform が行う。

`policies/` に YAML を 1 つ置くと、Config ルールが 1 本増える。

## なぜこの作りか

- **c7n 本体は関数の zip に入れず、layer に分ける。**
  Lambda の中身は `custodian run` が `config-poll-rule` モードでデプロイするものと同じ形で、違いはここだけ。
- **layer に入れるのは c7n だけ。**
  依存ライブラリは入れず、Lambda ランタイムの boto3 を使う（c7n の CLI がデプロイする場合と同じ）。
- **Config レコーダーの記録対象は、個人アカウントにまず存在しないタイプ 1 つに絞っている。**
  レコーダーは Config ルールを作るための前提として置いているだけで、記録料金をかけないため。

## 気をつけること

- **Config のレコーダーはリージョンに 1 つしか作れない。**
  既にあるアカウントで使う場合は `main_config_recorder.tf` を消し、`main_config.tf` の `depends_on` から外す。
- **c7n を上げるときは、wheel と `locals.tf` の `c7n_version` を両方変える。**
  wheel は `pip download --no-deps c7n==<版> -d vendor/` で取り、古い wheel は消す。
