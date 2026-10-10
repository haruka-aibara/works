# マージ前後の plan の比較

**この文書を読むとき:** merge 後の run を Confirm する前。plan-diff が ❌ になったとき。`TFC_TOKEN` を入れ直すとき。

**3行:**

- PR を merge すると、`.github/workflows/plan-diff.yml` が「PR で見た plan」と「merge 後の plan」を比べる
- `works` は `auto_apply = false` なので、merge 後の run は Confirm 待ちで止まる
- **merge した PR の Checks で plan-diff が ✅ になってから Confirm する**

---

## 1. 結果の読み方

| 結果 | 意味 | やること |
|---|---|---|
| ✅ | merge 後の plan は、PR で見た plan と同じ | Confirm する |
| ❌（「2つの plan を比べる」で失敗） | plan に差分がある | HCP Terraform で2つの run の plan を見比べ、納得できたら Confirm する |
| ❌（それより前のステップで失敗） | 比較できなかった（run が見つからない、plan が5分で終わらなかった、トークン切れなど） | ログで原因を見る。比較の代わりに、自分で plan を見て判断する |

公開リポジトリなので、ワークフローは差分の中身をログに出さない。中身は HCP Terraform の画面で見る。

## 2. 差分が出る主な理由

PR は main に追いついた状態で merge しているので、コードは PR と同じ。
それでも差分が出るのは、コードの外が変わったとき。

- 誰かが AWS や GitHub を手で変えた（ドリフト）
- ワークスペース変数を変えた
- data source の読み取り結果が変わった
- TFE_TOKEN のローテーションの周期をまたいだ（[TFE_TOKEN 自動ローテーション](tfe-token-rotation.md)）

## 3. `TFC_TOKEN` を用意する

Free プランでは team を作れないので、read 専用のトークンは作れない。
**owners team のトークンを、有効期限を付けて発行する。**

1. Organization Settings → API Tokens → Team Tokens → Create a team token
2. Team は `owners`、description は `github-actions plan-diff exp <失効日>`、Expiration を付ける
3. リポジトリの Settings → Secrets and variables → Actions に `TFC_TOKEN` として保存する

`works blue ...` / `works green ...` のトークンは使わない。
あれは Terraform が自動で作り直すので、Secrets に写した値はいずれ無効になる。

期限が切れると plan-diff は最初のステップで失敗する。そうなったら同じ手順で入れ直す。
