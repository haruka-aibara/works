tags: github, github-actions, supply-chain, security

# GitHub Actions は推移的な依存までロックファイルでハッシュ固定する

`uses: owner/action@<SHA>` で固まるのは、そのアクションの `action.yml` の中身まで。
中で呼ぶアクションを作者が SHA で書いていれば推移的にも固まるが、`@v1` のようなタグなら動いたままで、利用者からは上書きできない。
これまでは fork して中の `uses:` を書き換えるか、composite アクションを避けるしかなかった。

GitHub のワークフロー依存のロックファイル（workflow dependency lockfiles）は、作者の書き方に関係なく、推移的な依存まで利用者側で全部 SHA 固定できる。
これを入れたい。

## やること

- 今のうちにロックファイルを生成して、推移的な依存にタグ指定のものがないかだけ見る
- 本格導入は GA と Renovate の対応を待つ。Renovate がロックファイルを更新できないと、ワークフローの SHA 固定と二重管理になる
- ロックファイルがあればワークフロー内の SHA 固定は不要とドキュメントにあるが、外すのは Renovate の対応後

先行ツール（gh-actions-lockfile、ghasum）は取得後に照合する。ネイティブ機能は取得時点で固定される。

public preview（2026-10 時点）で、ロックファイルの形式と Renovate の対応状況は未確認。
