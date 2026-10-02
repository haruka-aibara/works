tags: aws, iam, access-analyzer, terraform, ci, security

# Terraform plan を IAM Access Analyzer のカスタムポリシーチェックで止める

IAM ポリシーのレビューは、人間が JSON を目で追うのが一番当てにならない。
Access Analyzer のカスタムポリシーチェックを CI に入れて、危ない変更を PR の時点で落とす。

## 使えるチェック

- `check-no-new-access`：変更前より権限が広がっていないか。広がったときだけ人間が見る
- `check-access-not-granted`：「`iam:PassRole` は誰にも渡さない」のような禁止リストを決めておく
- `check-no-public-access`：リソースポリシーが外部公開になっていないか

二値で返るので、lint のように CI を落とせる。

## なぜ Checkov などではなく

静的スキャナーはパターンマッチで、ワイルドカードや条件キーの組み合わせを推論しない。
Access Analyzer は自動推論で、ポリシーが実際に何を許すかを判定する。
「前より広がったか」を判定できるのはこちらだけ。

## 気をつけること

- チェックはリクエスト単位の課金。変わったものだけに絞る
- plan JSON からポリシーを取り出すのは awslabs の `terraform-iam-policy-validator` でできるはず
- CI からはチェック用 API だけを許すロールを OIDC で使う

金額と awslabs ツールの現状は未確認
