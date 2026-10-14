tags: github, github-actions, supply-chain, security

# GitHub Actions は推移的な依存までロックファイルでハッシュ固定する

`uses: owner/action@<SHA>` のハッシュ固定は、ワークフローに直接書いたアクションにしか効かない。
composite アクションが中で呼ぶアクションや reusable workflow の先がタグ指定なら、タグの付け替えで中身が差し替わる。

GitHub のワークフロー依存のロックファイル（workflow dependency lockfiles）は、推移的な依存まで全部コミット SHA で固定する。
これを入れたい。

## やること

- ロックファイルを生成してコミットし、推移的な依存に何がぶら下がっているかをまず見る
- Renovate がロックファイルを更新できるか確かめる。できないと、ワークフローの SHA 固定と二重管理になる
- ロックファイルがあればワークフロー内の SHA 固定は不要とドキュメントにある。外すかは Renovate の対応しだい

gh-actions-lockfile や ghasum のような先行ツールは、検証をステップで走らせるので取得後の照合になる。
ネイティブ機能は取得時点で固定される。

public preview（2026-10 時点）で、ロックファイルの形式と Renovate の対応状況は未確認。
