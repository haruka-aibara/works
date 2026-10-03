tags: terraform, hcp-terraform, drift, security, operations

# Terraform の差分が出たら鳴らす

変更は Terraform からだけ、という運用にしているなら、
**Terraform の外で何かが変わったら、それ自体が異常**として扱える。

一番安いのは、定期的に plan を回して差分（ドリフト）が出たら鳴らすこと。

## やり方

- HCP Terraform のヘルス評価（drift detection）を有効にして、ワークスペースの通知でドリフトだけ流す
- 使えないなら、CI で毎日 `terraform plan -detailed-exitcode` を回し、終了コード 2 のときだけ通知する

## おまけ：ローテーションの合図にもなる

`time_rotating` でトークンや鍵を回しているなら、期限が来た時点で差分が出る（はず）。
通知が「apply してローテーションして」の合図を兼ね、別のリマインダーが要らない。

## 気をつけること

- 鳴るのは管理下のリソースだけ。Terraform の外で**新しく作られた**ものは差分にならない
- plan の間隔ぶん遅れる。止めるなら Deny、気づくならこれ
- 毎回出る差分があると狼少年になる。`ignore_changes` で潰してから入れる
- コードに戻すか、コードを追随させるかを決めるまでが対応

ヘルス評価が使えるプランと、`time_rotating` の期限切れがドリフト扱いになるかは未確認。
