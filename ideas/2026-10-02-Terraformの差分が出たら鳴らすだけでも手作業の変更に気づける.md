tags: terraform, hcp-terraform, drift, security, operations

# Terraform の差分が出たら鳴らすだけでも、手作業の変更に気づける

ここまでの ideas は「Terraform の実行ロール以外は Deny」に寄りかかっている。
逆に言えば、**Terraform の外で何かが変わったら、それ自体が異常**として扱える。

一番安いのは、定期的に plan を回して差分（ドリフト）が出たら鳴らすこと。
Deny を書いていないリソースでも、バケットポリシーやセキュリティグループを手で書き換えられたら気づける。

## やり方

- HCP Terraform のヘルス評価（drift detection）を有効にして、ワークスペースの通知でドリフトだけ流す
- 使えないなら、GitHub Actions で毎日 `terraform plan -detailed-exitcode` を回し、終了コード 2 のときだけ通知する

## 気をつけること

- 鳴るのは「Terraform が管理しているリソースの属性」だけ。Terraform の外で**新しく作られた**リソースは差分にならない。そこは CloudTrail や Config の担当
- 気づくのは最大で plan の間隔ぶん遅れる。止めたいものは Deny、気づきたいものはこれ、と役割を分ける
- 毎回出る差分（AWS 側が値を足す属性など）があると狼少年になる。`ignore_changes` で潰してから入れる
- 差分が出たら「コードに戻す」か「コードを追随させる」かを決めるまでが対応。鳴らしっぱなしにしない

ヘルス評価が使える HCP Terraform のプランは未確認。
