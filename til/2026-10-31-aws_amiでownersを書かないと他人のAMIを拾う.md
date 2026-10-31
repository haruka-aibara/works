tags: aws, ec2, ami, terraform, supply-chain, security

# aws_ami で owners を書かないと他人の AMI を拾う

AMI は誰でも公開でき、名前は重複してよい。
所有者を指定せずに「名前のパターン＋最新」で探すと、**攻撃者が似た名前で後から公開した AMI が選ばれる**。

Datadog Security Labs が 2025 年 2 月に「whoAMI」と名付けて公表した。
dependency confusion と同じ型で、名前で探して出どころを確かめないところを突く。

Terraform なら、`aws_ami` に `most_recent = true` と名前の `filter` だけを書き、`owners` がないものが該当する。
`describe-images` を `--owners` なしで使うスクリプトも同じ。

## 対策

- **名前で探さない**：AWS 公式の AMI は SSM のパブリックパラメータ（`/aws/service/ami-amazon-linux-latest/...` など）から ID を取る。launch template なら `resolve:ssm:` で書ける
- **コードで強制する**：plan の JSON の `configuration` にある `aws_ami` で、`owners` がないものを落とす。data source は `resource_changes` に出ないので、そこだけ見るチェックでは素通りする
- **実行時に止める**：EC2 の Allowed AMIs（組織なら declarative policy）で、信頼する所有者の AMI しか起動させない。audit mode で洗い出してから締める

AWS provider が `owners` なしに警告を出すか、Allowed AMIs の audit mode の挙動は未確認。
