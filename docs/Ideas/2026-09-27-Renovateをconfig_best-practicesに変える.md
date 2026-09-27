tags: github, renovate, security, operations

# Renovate を config:recommended から config:best-practices に変える

best-practices に変えると、npm の3日間の cooldown（`minimumReleaseAge`）と digest でのピン留めが入る。
いま `renovate.json` で claude-code にだけ手で3日を入れているのは、これを部分的にやっている状態。

変えたら、claude-code 用の手書きの `minimumReleaseAge` は外せるはず。

詳細は [Renovate](../GitHub/41_Renovate/README.md) に書く。
