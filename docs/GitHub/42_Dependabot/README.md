# Dependabot で PR 作成とマージを自動にする

入口のメモは [ideas/2026-09-26-Dependabotは複雑にしないで使う.md](../../../ideas/2026-09-26-Dependabotは複雑にしないで使う.md)。
ここでは「PR を自動で作る」と「PR を自動でマージする」を分けて書く。

## PR を自動で作る

作る PR は2種類あり、ON にする場所が違う。

| PR の種類 | いつ来るか | ON にする場所 |
|---|---|---|
| security updates | アラートが出て、直せる版があるとき | Settings → Code security の Dependabot security updates |
| version updates | 新しい版が出たとき（脆弱性と無関係） | `.github/dependabot.yml` を置く |

version updates の最小構成は次のとおり。`groups` で全部を1本にまとめ、PR を週1本に抑える。

```yaml
version: 2
updates:
  - package-ecosystem: npm   # pip, docker, github-actions など使っているものに合わせる
    directory: /
    schedule:
      interval: weekly
    groups:
      all:
        patterns: ["*"]
```

このリポジトリの `.github/dependabot.yml` も devcontainer についてこの形になっている。

### PR は週1回まとめて見る

`interval: weekly` と `groups` の組み合わせで、version updates の PR は週1本にまとまる。
PR を1個ずつ追いかけず、週1回その1本を見てマージする運用にする。

ただし security updates は `schedule` に関係なく、アラートが出た時点で PR が来る。
そのままだと1件ずつ PR になるので、まとめたいなら `applies-to: security-updates` のグループを足す。

```yaml
    groups:
      all:
        patterns: ["*"]            # version updates を1本に
      security:
        applies-to: security-updates
        patterns: ["*"]            # security updates も1本に
```

security updates は急ぐものなので、週1回の確認を待たずに見る。

## PR を自動でマージする

Dependabot 自体にはマージ機能がない。GitHub の auto-merge を、ワークフローから Dependabot の PR に対して ON にする。

前提は2つ。

- Settings → General で **Allow auto-merge** を ON にする
- デフォルトブランチのブランチ保護（または ruleset）で必須チェックを設定する。設定がないと CI を待たずに即マージされる

ワークフローは GitHub 公式ドキュメントの例をもとにしている。patch 更新だけを自動マージの対象にする。

```yaml
name: Dependabot auto-merge
on: pull_request

permissions:
  contents: write
  pull-requests: write

jobs:
  dependabot:
    runs-on: ubuntu-latest
    if: github.event.pull_request.user.login == 'dependabot[bot]'
    steps:
      - id: metadata
        uses: dependabot/fetch-metadata@v2   # 実際に置くときはコミット SHA で固定する
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
      - if: steps.metadata.outputs.update-type == 'version-update:semver-patch'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

- `gh pr merge --auto` は「必須チェックが通ったらマージする」予約で、CI が落ちればマージされない
- minor まで広げるなら条件に `version-update:semver-minor` を足す。major は壊れやすいので人が見る
- `groups` でまとめた PR では `update-type` がグループ内でいちばん大きい更新になるはず。まとめると patch だけの PR になりにくいので、自動マージしたいなら patch 用のグループを分ける

## 未確認

Claude から聞いた話で、次は公式ドキュメントでまだ自分で確認していない。

- `groups` でまとめた PR の `update-type` の決まり方
- Dependabot が起こした `pull_request` で、`permissions` を書けば `GITHUB_TOKEN` に書き込み権限が付くこと
- security updates が `schedule` に関係なく即時に来ることと、`applies-to: security-updates` でまとめられること
