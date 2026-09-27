# EKS で GitHub Actions の self-hosted runner（ARC）を試す

EKS に Actions Runner Controller（ARC）を入れて、ジョブが来たときだけ runner 用のノードと Pod を立てる構成を、本番に近い形で試すハンズオン。
1〜2 日で消す前提。

## 構成

| 層 | 管理するもの | 何で入れるか |
|---|---|---|
| `terraform/infra` | VPC（private subnet + NAT 1 個）、EKS、Karpenter と ESO 用の IAM・SQS | Terraform |
| `terraform/bootstrap` | Argo CD と root Application | Terraform（Helm provider） |
| `gitops/apps` | Karpenter、ESO、ARC | Argo CD |

infra と bootstrap を分けているのは、クラスタができる前に Helm provider の接続先を決められないため。
bootstrap は infra の state（ローカル）を読むので、同じ作業ディレクトリで順に apply する。

Argo CD は GitHub 上の `gitops/` を読む。
手元の変更は push するまで反映されない。

runner の流れは次のとおり。

1. ジョブが来ると、ARC が runner Pod を作る
2. Pod が Pending になり、Karpenter が Spot の x86_64 ノードを立てる
3. ジョブが終わってノードが 5 分空くと、Karpenter が消す

常駐する controller 類（Argo CD・Karpenter・ESO・ARC）は、system ノード（t4g.medium × 1）に載る。

## 費用の目安（東京リージョン・2 日間）

| 項目 | 2 日分 |
|---|---|
| EKS コントロールプレーン（$0.10/h） | 約 $4.8 |
| NAT Gateway（$0.062/h ＋ 転送量） | 約 $3 |
| system ノード t4g.medium On-Demand | 約 $2 |
| runner ノード（Spot、ジョブがあるときだけ） | 使った分 |

合計 $10 前後。
Secrets Manager のシークレット（$0.40/月）は destroy しても残す想定。

## 使う前に

**public リポジトリには登録しない。**
fork からの PR で、誰でも自分のクラスタ上でコードを実行できてしまう。
private のテスト用リポジトリを使う。

### GitHub App を作る

ARC が runner を登録するための GitHub App を作り、テスト用リポジトリにインストールする。

- 権限は Repository permissions の Administration（Read and write）と Metadata（Read-only）
- App ID、Installation ID、秘密鍵（.pem）を控える

### 認証情報を Secrets Manager に入れる

Terraform の state に秘密鍵を載せないよう、シークレットは Terraform の外で作る。
キー名は ARC が読む名前に合わせる。

```bash
aws secretsmanager create-secret \
  --region ap-northeast-1 \
  --name arc-hands-on/github-app \
  --secret-string "$(jq -n \
    --arg id '<App ID>' \
    --arg inst '<Installation ID>' \
    --rawfile key ./app.private-key.pem \
    '{github_app_id: $id, github_app_installation_id: $inst, github_app_private_key: $key}')"
```

### Spot 用のサービスリンクロールを作る

アカウントで一度も Spot を使ったことがないと、Karpenter が Spot インスタンスを起動できない。
既にある場合はエラーになるだけなので、無視してよい。

```bash
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
```

## 作る

```hcl
# terraform/infra/terraform.tfvars
api_allowed_cidrs = ["<手元のグローバル IP>/32"]
```

```hcl
# terraform/bootstrap/terraform.tfvars
github_config_url = "https://github.com/<owner>/<private-repo>"
# main にマージする前に試すなら、このディレクトリを push したブランチを指定する
# gitops_revision = "<branch>"
```

```bash
terraform -chdir=terraform/infra init
terraform -chdir=terraform/infra apply      # 15〜20 分
terraform -chdir=terraform/bootstrap init
terraform -chdir=terraform/bootstrap apply

aws eks update-kubeconfig --region ap-northeast-1 --name arc-hands-on
kubectl -n argocd get applications          # 全部 Synced / Healthy になるまで数分
```

Argo CD の UI を見るときは次のとおり。

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
kubectl -n argocd port-forward svc/argocd-server 8080:443   # https://localhost:8080 に admin でログイン
```

ワークフロー側は `runs-on` に scale set 名を書く。

```yaml
jobs:
  hello:
    runs-on: eks-arc
    steps:
      - run: echo "hello from $(hostname)"
```

## 片付け

**いきなり `terraform destroy` しない。**
Karpenter が立てた EC2 は Terraform の管理外なので、先に消さないと VPC の削除が止まる。
GitHub 側の runner 登録も、ARC の controller が動いているうちに外す。

```bash
# 1. root を消して、配下の Application が自動で作り直されないようにする（配下は残る）
kubectl -n argocd delete application root
# 2. runner scale set を消す。GitHub 側の登録も controller が外す
kubectl -n argocd delete application arc-runner-set
# 3. NodePool を消す。Karpenter が runner ノードを終了する
kubectl -n argocd delete application karpenter-resources
kubectl get nodeclaims                      # 空になるまで待つ

terraform -chdir=terraform/bootstrap destroy
terraform -chdir=terraform/infra destroy
```

## 制約

- **コンテナを使うジョブは動かない。** runner Pod の中に Docker がない。`container:` や `services:`、docker build を試すなら、`gitops/apps/templates/arc-runner-set.yaml` で `containerMode.type` に `dind` か `kubernetes` を設定する
- **Spot なので、ジョブの途中でノードが回収されることがある。** `karpenter.sh/do-not-disrupt` で防げるのは Karpenter 自身の統合による削除だけで、Spot の中断は防げない
