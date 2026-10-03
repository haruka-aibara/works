# IAM ロールとポリシー

「EC2 から S3 にアクセスしたい」という場面でアクセスキーをコードに埋め込んでいる——これは典型的な事故の元。IAM ロールを使えばキー不要で安全にアクセスできる。ロールとポリシーの使い分けを正しく理解すると、IAM 設計の大部分が解決する。

---

## IAM エンティティの整理

| エンティティ | 用途 | 備考 |
|---|---|---|
| IAM ユーザー | 人間（開発者・運用者）の認証 | 長期的なアクセスキーを持つ。できるだけ少なくする |
| IAM ロール | AWS サービス・アプリ・CI/CD の認証 | 一時的な認証情報を発行。アクセスキー不要 |
| IAM グループ | IAM ユーザーをまとめてポリシーを適用 | チームごとの権限管理に使う |

**原則：AWS リソースからの操作はすべてロールを使う。アクセスキーはできるだけ使わない。**

---

## IAM ポリシーの種類

### アイデンティティベースポリシー

ユーザー・ロール・グループにアタッチする。「誰が何をできるか」を定義。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

### リソースベースポリシー

S3 バケット・KMS キー・SQS キューなど、リソース側にアタッチする。「誰がこのリソースを使えるか」を定義。クロスアカウントアクセスで使うことが多い。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::111111111111:role/my-app-role"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::shared-bucket/*"
    }
  ]
}
```

### 同じアカウント内では、リソースポリシーだけで許可が成立する

同じアカウント内のアクセスは、**IAM ポリシーかリソースポリシーのどちらか一方**が許可していれば通る（和集合）。
ロールの IAM ポリシーに `s3:GetObject` が 1 つもなくても、バケットポリシーの `Principal` にそのロールの ARN があれば読める。
明示的な Deny と SCP には負ける。

アカウントをまたぐときは逆で、相手の IAM ポリシーとこちらのリソースポリシーの**両方**が要る（積集合）。
「バケットポリシーで許可しても、相手の IAM で許可しないと使えない」はこちらの話で、同じアカウント内でもそうだと思い込むと見落とす。

KMS は例外で、キーポリシーが許可（か IAM への委任）しない限り、IAM ポリシーだけでは使えない。

困るのは棚卸しのとき。
「このロールは何ができるか」を IAM ポリシーだけで見ると、リソースポリシー側から与えられた権限が漏れる。
IAM Access Analyzer の内部アクセスの分析を使うと、リソースポリシーも含めてアカウント内で誰がどこに届くかが出る。

permissions boundary を付けたロールで、リソースポリシーからの許可がどこまで効くかは未確認。

---

## EC2 インスタンスへのロールのアタッチ

```bash
# インスタンスプロファイルを作成してロールをアタッチ
aws iam create-instance-profile --instance-profile-name my-app-profile
aws iam add-role-to-instance-profile \
  --instance-profile-name my-app-profile \
  --role-name my-app-role

# EC2 インスタンスにアタッチ
aws ec2 associate-iam-instance-profile \
  --instance-id i-0abc123 \
  --iam-instance-profile Name=my-app-profile
```

EC2 内からは環境変数やメタデータエンドポイント経由で自動的に認証情報が取れる。コードにキーを書く必要がない。

---

## 信頼ポリシー（Trust Policy）

ロールを「誰が引き受けられるか」を定義するポリシー。ロール設計の要。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

GitHub Actions から AssumeRole する場合（OIDC）：

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub": "repo:myorg/myrepo:ref:refs/heads/main"
    }
  }
}
```

---

## AWS 管理ポリシー vs カスタムポリシー

| | AWS 管理ポリシー | カスタムポリシー |
|---|---|---|
| 管理コスト | AWS が更新・管理 | 自分でメンテナンスが必要 |
| 権限の精度 | 広め | ユースケースに合わせて絞れる |
| 推奨用途 | プロトタイプ・ベースライン | 本番環境・最小権限が必要な場合 |

本番では `AmazonEC2FullAccess` のような広いポリシーを避け、必要な操作だけのカスタムポリシーを作る。
