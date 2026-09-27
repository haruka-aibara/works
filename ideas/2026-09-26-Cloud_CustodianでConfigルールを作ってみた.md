tags: aws, config, cloud-custodian, terraform

# Cloud Custodian で Config ルールを作ってみた

判定ロジックを自作せずに Config ルールを増やせないかと思い、Cloud Custodian（c7n）のポリシーを Config ルールとして Terraform だけでデプロイする形を試した（`modules/aws-config-custodian`）。`policies/` に YAML を置けば、ルールが 1 本ずつ増える。

分かったこと:

- RDS のパラメータはパラメータグループの値までしか見られず、再起動待ちまでは追わないのが現実的な落としどころだろう → [RDSパラメータの監視は再起動待ちまでは追えない](<../Cloud Custodian (c7n)/RDSパラメータの監視は再起動待ちまでは追えない.md>)
- c7n は wheel のまま持つのがよさそう。ソースを丸ごと持つと約 8.8 万行を抱えることになる → [c7nのソースを丸ごとgit管理するかwheelで持つか](<../Cloud Custodian (c7n)/c7nのソースを丸ごとgit管理するかwheelで持つか.md>)
- c7n の Config 連携は評価を ID（IAM ロールなら `AROA...`）で書き込むので、IAM や RDS のルールだと Config の一覧から非準拠のリソースが分からない。Config の画面を利用者に見せるなら、ここだけは何かを自分で持つことになる → 同じく [c7nのソースを丸ごとgit管理するかwheelで持つか](<../Cloud Custodian (c7n)/c7nのソースを丸ごとgit管理するかwheelで持つか.md>) の後半

## 結局どうするか

判定ロジックを持たずに済むのが c7n の良さだが、今は AI でカスタム Lambda のコードも書きやすい。Config の一覧に名前を出すために c7n へ手を入れるくらいなら、最初から自作するのと大差ない。コンソールでの見えやすさまで考えると、普通にカスタム Lambda のルールを書くのでよさそう。

## 参考

- [Serverlessconf London での Capital One による Cloud Custodian の講演レポート（DevelopersIO）](https://dev.classmethod.jp/articles/serverlessconf-london-cloud-custodian-at-capital-one/)
