tags: aws, iam, access-analyzer, terraform, ci, ai

# IAM ポリシーの差分は Access Analyzer のカスタムポリシーチェックで機械判定する

AI が PR を出し人間が承認する分担だと、一番見落としやすいのが IAM ポリシーの差分。
Access Analyzer のカスタムポリシーチェックなら「権限が増えたか」を機械に判定させられる。

- `check-no-new-access`：変更前と比べて、新しいアクセスが増えたか
- `check-access-not-granted`：`iam:PassRole` など指定アクションを許していないか
- `check-no-public-access`：リソースポリシーがパブリックになっていないか

## やりたい形

CI で `terraform plan` の JSON からポリシーを抜き出してチェックし、権限が増えた PR にだけラベルを付ける。
人間はその PR だけ IAM を丁寧に読む。

awslabs の `terraform-iam-policy-validator` が plan の JSON を読めるはずなので、まずこれを試す。

## 気になること

- 呼び出し単位の課金なので、差分のあるポリシーだけに絞る
- CI に AWS の認証が要る（CI は AI ではないので、「AI は AWS に接続しない」とは衝突しない）
- 条件キーが絡むと「増えた」に倒れるらしい

料金と validator の対応範囲は未確認。
[ポリシー生成](../modules/iam-access-analyzer-policy-generate) が「作る」側、こちらは「増やさない」側。
