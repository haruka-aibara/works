tags: terraform, ci

# plan を毎回走らせるなら、terraform validate はいらない

`terraform plan` は、実行の前に validate と同じ検証（構文・型・参照）をする。
だから validate で落ちるものは plan でも落ちる。
PR ごとに plan が走って、それが必須チェックになっているなら、validate を別に入れても重複になる。

## validate が意味を持つのは plan が走らないとき

validate は認証情報も state もいらず、コードだけで走る。
活きるのは次のような場面。

- plan の仕組みがないリポジトリで、最低限の検証をしたい
- fork からの PR など、認証情報を渡せず plan を走らせられない
- push 前に手元や pre-commit でさっと確かめたい

plan より速く、コード以外の理由（認証切れ・API エラー・ロック待ち）で落ちないので、原因の切り分けはしやすい。
ただ、plan があるならそれだけのために CI に足すほどではない。
