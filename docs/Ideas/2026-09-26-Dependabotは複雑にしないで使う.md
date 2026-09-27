tags: github, dependabot, security, operations

# Dependabot は複雑にしないで使う

Settings → Code security で Dependency graph・Dependabot alerts・Dependabot security updates（修正 PR を自動で出す）を ON にするだけ。`dependabot.yml` は最初は書かない。

version updates は PR が増えるので、欲しくなってから `dependabot.yml` を weekly と `groups` で週1本にまとめて足す。
自動マージまでは [Dependabot](../GitHub/42_Dependabot/README.md) に書いた。
このリポジトリの更新は [Renovate](../GitHub/41_Renovate/README.md) 主体で、Dependabot は devcontainer だけ。

## アラートを自分で閉じないといけない問題

デフォルトブランチで依存を直せば、アラートは自動で Fixed になるはず。
手で閉じる羽目になるのは次のどれか。

- security updates の PR を merge せずに閉じた
- 直す版がない、または間接依存が上がっていない
- 実害がない（開発用の依存だけ等）ので直さない → Dismiss するしかない

最後は Dependabot rules（自動トリアージ）で自動 Dismiss できる。
プリセットの「開発用依存の低影響アラートを閉じる」を ON にするだけでも減る。
カスタムルールは private だと GitHub Code Security が要るはず。

Claude から聞いた話で、自動クローズの条件と料金は公式ドキュメント未確認。
