tags: github, codeowners, review

# 全 PR に特定チームのレビューを必須にするなら CODEOWNERS

リポジトリのすべての PR で、特定の人やチームの承認を必須にしたいとき。

1. CODEOWNERS に `* @org/team` を書く
2. ブランチ保護かルールセットで「Require review from Code Owners」を有効にする

```text
# .github/CODEOWNERS
* @org/security-team
```

## 気をつけること

- **最後に一致した行が勝つ**。`*` の下に `/docs/ @someone` のような行があると、その範囲ではチームの承認が要らなくなる。必ず通したいなら、全行にそのチームを並べる
- **チームに write 権限がないと必須にならない**
- **CODEOWNERS 自体を守る**。書き換えられたら終わりなので、`/.github/CODEOWNERS` のオーナーもそのチームにする
- 承認後に中身を差し替えられないよう、「最新の push のあとに承認が必要」も有効にする

## ほかの手段

ルールセットに、特定チームの承認を必須にするルール（Required reviewers）が足されている。
CODEOWNERS を置かずに済むが、提供状況（ベータか GA か、どのプランか）は未確認。
