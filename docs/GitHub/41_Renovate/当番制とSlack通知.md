# Renovate の PR を当番制で回す

依存の更新は大事だが急がないので、誰の仕事でもないまま放置されやすい。
そこで Renovate の PR ごとに当番を 1 人決めて、その人がレビューしてマージする。

このリポジトリは AWS の Terraform が主で、CI で見ているのは `terraform fmt` 程度しかない。
緑になっても動く保証にならないので、自動マージはせず、必ず当番が目視で確かめてからマージする。

## しくみ

| 設定 | 場所 | 役割 |
|---|---|---|
| `assigneesFromCodeOwners: true` | `renovate.json` | 変更したファイルのコードオーナーをアサイン候補にする |
| `assigneesSampleSize: 1` | `renovate.json` | 候補からランダムに 1 人だけアサインする。これが当番 |
| `labels: ["renovate"]` | `renovate.json` | Renovate の PR に `renovate` ラベルを付ける。Slack の購読はこのラベルで絞る |
| `automerge: false` | `renovate.json` | 自動マージしない |
| Terraform のグループ | `renovate.json` | Terraform 本体・Provider・tflint プラグインの更新を 1 本の PR にまとめる |
| `* @メンバー` | `.github/CODEOWNERS` | 当番の母集団 |

`.github/CODEOWNERS` はレビュー必須のためのファイルではない。
ブランチ保護やルールセットの「Require review from Code Owners」はオンにしない。
オンにすると、当番以外の PR も含めて、ここに並べたメンバーの承認がないとマージできなくなる。

CODEOWNERS にはチーム（`@org/team`）ではなく個人を書く。
Renovate はチームをアサインできない。

## Slack のチャンネルに Renovate の PR を流す

Slack 公式の GitHub アプリ（GitHub for Slack）で、`renovate` ラベルの付いた PR だけを購読する。
ワークスペースに GitHub アプリが入っていない場合は、先に Slack の管理者に入れてもらう。

1. 通知を流したいチャンネルで、GitHub アプリをチャンネルに招待する

   ```text
   /invite @GitHub
   ```

   プライベートチャンネルでは、これをしないと購読できない。

2. リポジトリを購読する。初回は GitHub アカウントの連携と、組織への GitHub アプリのインストールを求められるので、画面に従う

   ```text
   /github subscribe haruka-aibara/works
   ```

3. PR 以外の通知（issues・commits・releases・deployments）を外す

   ```text
   /github unsubscribe haruka-aibara/works issues commits releases deployments
   ```

4. `renovate` ラベルの付いたものだけに絞る

   ```text
   /github subscribe haruka-aibara/works +label:"renovate"
   ```

   ラベルの絞り込みは 1 つの購読に 1 つだけ。
   別のラベルを指定すると置き換わる。

5. 設定を確認する

   ```text
   /github subscribe list features
   ```

   `pulls` だけが有効で、ラベルの絞り込みが `renovate` になっていれば完了。

## 当番になるメンバーがやっておくこと

当番になる人は、各自 1 回だけ、Slack の GitHub アプリと自分の GitHub アカウントを連携しておく。
Slack のどこか（GitHub アプリとの DM でもよい）で次を実行し、画面に従って GitHub にサインインする。

```text
/github signin
```

連携しておくと、PR で自分がアサインされたとき、チャンネルの通知が GitHub のユーザー名ではなく Slack の本物のメンションになる。
メンションなので Slack の通知として届き、「自分が当番だ」と気づける。

連携していない人は、チャンネルには GitHub のユーザー名が文字で出るだけで、通知は飛ばない。
当番に入れる人は、CODEOWNERS に足すのと同時に連携も済ませてもらう。

連携できたかは、次で確かめられる。

```text
/github settings
```

## 当番がやること

1. Slack でメンションが来たら PR を開く
2. リリースノートと差分を読む。Terraform の更新なら `terraform plan` の結果も見る
3. 問題なければマージする。直す必要があれば同じブランチに push するか、PR にコメントして対応を決める

アサインされたまま長く放置されている PR は、GitHub の PR 一覧で `label:renovate` で探せる。

## 参考

- [Renovate Docs - assigneesFromCodeOwners](https://docs.renovatebot.com/configuration-options/#assigneesfromcodeowners)
- [Renovate Docs - assigneesSampleSize](https://docs.renovatebot.com/configuration-options/#assigneessamplesize)
- [GitHub Docs - About code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [integrations/slack（GitHub for Slack の README）](https://github.com/integrations/slack)
