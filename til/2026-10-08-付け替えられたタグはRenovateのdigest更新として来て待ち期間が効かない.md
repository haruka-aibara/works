tags: github, renovate, security, supply-chain

# 付け替えられたタグは Renovate の digest 更新として来て、待ち期間が効かない

action を SHA でピンしていても、Renovate はタグの指す先が変わると「同じバージョンでコミットだけ変わった」digest 更新の PR を出す。
trivy-action の侵害（2026 年 3 月）のように既存タグを付け替えられると、それが PR になる。

## minimumReleaseAge では止まらない

GitHub Actions の公開日時は、タグが指すコミットの日時か、GitHub Release の公開日時の新しいほう。
付け替えではバージョンも Release も元のままで、コミットの日時は偽装できる（trivy では 2021 年だった）。
だから「公開から 3 日待つ」はすでに満たした扱いになり、digest 更新をオートマージしていると即取り込む。

## どうするか

- action の digest 更新は自動マージしない。PR が来たら、付け直した理由をリリースノートやアドバイザリで確かめる
- Release を作らずタグだけ打つ action は、新しいバージョンでも待ち期間がほぼ効かないと考える
- 本命の対策は、ワークフローの `permissions` とシークレットを絞ること

詳細とこのリポジトリの方針は [Renovate のオートマージ](../docs/GitHub/41_Renovate/オートマージ.md)。
