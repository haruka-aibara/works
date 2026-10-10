tags: confluence, atlassian, rest-api, migration

# Confluence の DC 向け XHTML は、そのまま Cloud に投げられる

Data Center に POST していた storage format（XHTML）の本文は、Cloud の REST API にもそのまま渡せる。
手元で ADF（Cloud エディタの JSON 形式）に作り変える必要はない。

変わるのはリクエスト側の 3 つ。

- 認証：PAT（Bearer）から、メールアドレス + API トークンの Basic 認証に変わる
- エンドポイント：`/wiki` が入る。v1 は廃止が進んでいるので `POST /wiki/api/v2/pages` を使う
- ID：親ページなどの ID は DC と Cloud で別物なので、Cloud 側のものに差し替える

ただし、Cloud は受け取った XHTML を保存時に ADF へ変換する。
2026年4月に旧エディタが廃止され、すべてのページが Cloud エディタの形式で保存されるようになったため。
本文に次のものがあると、その部分は XHTML のまま直す必要がある。

- 本文を持つマクロの入れ子（panel の中に code など）は Legacy Content Macro に包まれ、普通には編集しづらくなる
- HTML マクロ・ユーザーマクロ・Cloud 版のないアプリのマクロは表示が壊れる
- `ri:userkey` は解決できないので `ri:account-id` に置き換える

読み返すと、本文は ADF から作り直した XHTML になって返ってくる。投げた文字列とは一致しない。
「前回と差分があれば更新する」作りだと、毎回差分ありと判定される。

実機での確認はしていない。根拠は Atlassian の公式サポートページとコミュニティ投稿で、v2 API で storage を投げたときの細かい変換結果は未確認。
