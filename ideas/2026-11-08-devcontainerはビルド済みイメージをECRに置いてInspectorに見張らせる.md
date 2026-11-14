tags: devcontainer, ecr, inspector, vulnerability, supply-chain, claude-code, security

# devcontainer はビルド済みイメージを ECR に置いて Inspector に見張らせる

devcontainer を Template（新しいプロジェクトを作るときに一度コピーする雛形）で配るのをやめる。
ビルド済みのイメージを ECR に push し、各リポジトリの `devcontainer.json` から `image:` で参照する。

## うれしいこと

- **Inspector が見張り続ける。**
  push した後に出た CVE でも、再スキャンで拾える。PR 時点の Trivy では拾えない
- **全員が同じ環境になる。**
  digest で固定して Renovate で上げれば、VS Code が Rebuild を勧めてくる
- **初回の起動が pull だけで済む**
- **エージェントを閉じ込める箱になる。**
  ホストの認証情報が見えない環境で、Claude Code に強い権限を渡せる

## 失うもの

- **ツールを自分で入れる経験。**
  ただ、覚える価値があるのはバージョン固定や認証の仕組みのほうで、そちらは残る
- **ECR の手間と費用。**
  使う側も `docker login` が要り、Inspector はイメージ単位で課金される
- **中で好きに入れる自由。**
  入れたものは Rebuild で消える

詳しくは [devcontainer をビルド済みイメージで配る](../docs/Visual%20Studio%20Code/devcontainerをビルド済みイメージで配る.md)。
