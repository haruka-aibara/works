tags: aws, ec2, ami, terraform, supply-chain, security

# aws_ami で owners を書かないと他人の AMI を拾う

AMI は誰でも公開でき、名前は早い者勝ちで重複してよい。
所有者を指定せずに「名前のパターン＋いちばん新しいもの」で探すと、**攻撃者が同じような名前で後から公開した AMI が選ばれる**。

Datadog Security Labs が 2025 年 2 月に「whoAMI」と名付けて公表した。
パッケージの dependency confusion と同じ型で、名前で探して出どころを確かめないところを突く。
AWS 社内の非本番のシステムにも、これを踏んでいるものがあったと報告されている。

Terraform なら、`aws_ami` の data source に `most_recent = true` と名前の `filter` だけを書き、`owners` を書いていないものが該当する。
CLI の `describe-images` を `--owners` なしで使うスクリプトも同じ。

## 対策

- **名前で探さない**：AWS 公式の AMI は、SSM のパブリックパラメータ（`/aws/service/ami-amazon-linux-latest/...` など）から ID を取る。launch template なら `resolve:ssm:` で書ける
- **コードで強制する**：plan の JSON の `configuration`（モジュールの中も含む）にある `aws_ami` で、`owners` がないものを落とす。data source は `resource_changes` に出ないので、そこを見るチェックでは素通りする
- **実行時に止める**：EC2 の Allowed AMIs（組織なら declarative policy）で、信頼する所有者の AMI しか起動できないようにする。audit mode で、許可リスト外の AMI を使っているところを洗い出してから締める

AWS provider が `owners` なしの `most_recent` に警告を出すか、Allowed AMIs の audit mode の挙動は未確認。
