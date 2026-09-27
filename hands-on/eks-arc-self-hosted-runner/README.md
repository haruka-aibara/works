# EKS で GitHub Actions の self-hosted runner（ARC）を試す

EKS に Actions Runner Controller（ARC）を入れて、ジョブが来たときだけ runner Pod を立てる構成を試すハンズオン。

試し終わったら必ず `terraform destroy` する。
全部が時間課金なので、置きっぱなしにすると月 $100 前後かかる。

## 費用の目安（東京リージョン）

| 項目 | 月額（常時起動） |
|---|---|
| EKS コントロールプレーン（$0.10/h） | 約 $73 |
| ノード t3.medium Spot × 1 | 約 $15〜20 |
| パブリック IPv4 × 1（$0.005/h） | 約 $4 |
| EBS gp3 20GB | 約 $2 |

半日触って消すだけなら $1〜2 程度。

NAT Gateway（約 $45/月）を避けるため、ノードは public subnet に置いている。
ARC は GitHub へのロングポーリングで動くので、インバウンドの口は要らない。

## 使う前に

**public リポジトリには登録しない。**
fork からの PR で、誰でも自分のクラスタ上でコードを実行できてしまう。
試すときは private のテスト用リポジトリを使う。

runner 登録用に fine-grained PAT を作る。
リポジトリ単位なら、対象リポジトリの Administration（Read and write）が要る。
PAT は Helm release の値として state に平文で残るので、destroy 後に PAT も消す。

## 実行

```hcl
# terraform.tfvars
api_allowed_cidrs = ["<手元のグローバル IP>/32"]
github_config_url = "https://github.com/<owner>/<private-repo>"
github_token      = "github_pat_..."
```

```bash
terraform init
terraform apply   # 15〜20 分ほどかかる
```

ワークフロー側は `runs-on` に scale set 名を書く。

```yaml
jobs:
  hello:
    runs-on: eks-arc
    steps:
      - run: echo "hello from $(hostname)"
```

## 制約

- **コンテナを使うジョブは動かない。** `containerMode` を設定していないので、runner Pod の中に Docker がない。`container:` や `services:`、docker build を試すなら chart の `containerMode.type` に `dind` か `kubernetes` を設定する
- **ノードは増えない。** Cluster Autoscaler も Karpenter も入れていないので、`max_runners` まで Pod は立つが、ノードに収まらない分は Pending のまま待つ
- **Spot なので、ジョブの途中でノードが回収されることがある。** 気になるなら `capacity_type = "ON_DEMAND"`（ノード代は約 $40/月 になる）

## 片付け

```bash
terraform destroy
```

GitHub 側の runner 登録は controller が消す。
念のため destroy 後にリポジトリの Settings → Actions → Runners に残っていないことを確認する。
