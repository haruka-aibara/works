tags: confluence, atlassian, rest-api, migration

# Confluence の DC 向け XHTML は、そのまま Cloud に投げられる

Data Center に POST していた storage format（XHTML）の本文は、Cloud の REST API にもそのまま渡せる。
手元で ADF（Cloud エディタの JSON 形式）に作り変える必要はない。

変わるのはリクエスト側の 3 つ。

- 認証：PAT から、メールアドレス + API トークンの Basic 認証へ
- エンドポイント：`/wiki` が入る。v1 は廃止が進んでいるので `POST /wiki/api/v2/pages` を使う
- ID：親ページなどの ID は Cloud 側のものに差し替える

ただし Cloud は、受け取った XHTML を保存時に ADF へ変換する。
2026年4月に旧エディタが廃止されたため。
本文に次のものがあれば、その部分は XHTML のまま直す。

- 本文を持つマクロの入れ子（panel の中に code など）は Legacy Content Macro に包まれる
- HTML マクロ・ユーザーマクロ・Cloud 版のないアプリのマクロは壊れる
- `ri:userkey` は `ri:account-id` に置き換える

読み返した本文は ADF から作り直した XHTML で、投げた文字列とは一致しない。
差分を見て更新する作りだと、毎回差分ありになる。

実機では未確認。v2 API で storage を投げたときの細かい変換結果は未確認。
