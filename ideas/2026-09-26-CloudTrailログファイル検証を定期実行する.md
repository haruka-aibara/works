tags: aws, cloudtrail, security, audit

# CloudTrail ログファイル検証を定期実行する

CloudTrail のログファイル検証は、有効化しただけでは意味がない。
`aws cloudtrail validate-logs` を定期的に実行して、初めて改ざんに気づける。
マネージドな自動照合も通知もないため、自前で実装する必要がある。

優先度は高くないが、監査対応として年次か日次で回す仕組みを小さな Lambda で用意しておくと安く済む。

## 実装メモ（未確認）

`validate-logs` は CLI 独自の処理で、boto3 にはない。
Lambda でやるなら、ダイジェストの署名とハッシュを自前で照合する（`cryptography` を同梱）か、`awscli` を同梱する。

これは Claude との会話で聞いた話で、根拠になる公式ドキュメントはまだ自分で確認していない。
