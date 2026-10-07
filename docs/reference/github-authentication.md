# GitHub 認証のしくみ

**この文書を読むとき:** HCP Terraform の workspace 変数を見て「この `GITHUB_APP_PEM_FILE` は何だ」となったとき、GitHub の org に見覚えのない App がいて「これ消していいのか」となったとき、急に GitHub API が 401 を返しはじめたとき、あるいは **push しても run が走らなくなった**とき。

**3行:**

- **GitHub API を叩く認証**と、**HCP がリポジトリを見る VCS 連携**は完全に別系統。前者は provider 用の GitHub App、後者は VCS 用の GitHub App を OAuth 方式で繋いだもの。App が 2 つある
- 前者で実際に使われるトークンは**毎 run 発行され、1時間で失効する**
- 恒久的に存在する秘密は **2 つ**。App の秘密鍵 (PEM) と、VCS 連携が持つ OAuth トークン。どちらも HCP Terraform 側にある

---

## 1. 認証の 3 層

GitHub App の認証は 3 段構えになっている。名前が似ていて紛らわしいので、まずここを押さえる。

```
秘密鍵 (PEM)  ── 無期限。UI でしか作れない。これだけが本物の秘密
     │ 署名
     ▼
   JWT        ── 最大10分。ローカル計算で作る。「App 本体」としての認証
     │ POST /app/installations/{id}/access_tokens
     ▼
installation  ── 1時間。ghs_ で始まる
access token     これが実際にリポジトリを操作する
```

`integrations/github` provider が run ごとにこの 3 段を自動で通す。設定ファイルに書くことは何もない。

| 層 | 寿命 | 誰が作るか |
|---|---|---|
| 秘密鍵 (PEM) | **無期限** | 人間が Web UI で生成 |
| JWT | 最大 10 分 | provider が毎 run 生成 |
| installation access token | 1 時間 | provider が毎 run 取得 |

---

## 2. workspace の変数

workspace `works`（リポジトリ `haruka-aibara/works`）に設定されている。

### Environment variables

| 変数 | 正体 | 値の出どころ | 消すとどうなるか |
|---|---|---|---|
| `GITHUB_APP_ID` | App の識別子 | App の General ページ | github provider が認証できなくなる |
| `GITHUB_APP_INSTALLATION_ID` | **GitHub 側の数値 ID** | org の installations URL 末尾 | 同上 |
| `GITHUB_APP_PEM_FILE` | **秘密鍵**。sensitive | ダウンロードした PEM | 同上。かつ再取得不可 |
| `TFE_TOKEN` | HCP Terraform 自身の API トークン | **この構成が自分で発行する team token**（[自動ローテーション](../runbooks/tfe-token-rotation.md)） | tfe provider が動かなくなる |

**なぜ環境変数なのか:** `integrations/github` provider は `app_auth` ブロックが無くても `GITHUB_APP_` prefix の環境変数を読む。そのため `providers.tf` には認証の記述が一切ない。コードを見ても認証方法が分からないのはこのためで、意図的なものではなく provider の仕様にただ乗っている。

### 宣言は Terraform、値は UI

3 つの `GITHUB_APP_*` は `workspace_variables.tf` で `tfe_variable` として宣言されているが、**値はコードに無い**。作成時にプレースホルダ `set-in-ui` が入るだけで、実際の値は UI で設定する。

理由は 2 つある。

1. `tfe_variable` の `value` に代入した値は **state に書かれる**。秘密鍵を state に置きたくない
2. App ID と installation ID は秘密ではないが、public リポジトリに組織の App の識別子を残す理由もない

**この設計が成立する仕組み:** HCP Terraform は sensitive 変数の値を API で返さない。provider はそのため読み取りのたびに state 上の最後の値をそのまま持ち越し、**設定側の `value` が変わらない限り新しい値を書き込まない**。`ignore_changes` は不要である（provider のスキーマドキュメントに明記されている挙動）。

**その裏返し:** Terraform はこれらの値を一切認識できない。**UI で鍵が消されても破損しても検知せず、plan はクリーンなまま通る。** 「Terraform 管理下にある」と言っても、値については実質ノータッチである。

### `vcs_repo.oauth_token_id` は別系統

`main.tf` の `tfe_workspace` にも GitHub との接続が出てくるが、**上の `GITHUB_APP_*` とは無関係**である。層が違う。

| | 何と何を繋ぐか | 実体 |
|---|---|---|
| `GITHUB_APP_*`（環境変数） | github provider → GitHub API | 自前の **GitHub App** の秘密鍵 |
| `vcs_repo.oauth_token_id` | HCP Terraform → リポジトリ（コード取得・webhook） | VCS 用の **GitHub App** を authorize したユーザーのトークン（user-to-server token） |

前者が壊れると `github_repository` などが落ち、後者が壊れると **push しても run が走らなくなる**。症状が全く違うので切り分けはしやすい。

後者は手入力していない。データソースから引いている。

```hcl
data "tfe_oauth_client" "this" {
  organization     = local.tfe_organization
  service_provider = "github"
}
```

`vcs_repo` が要求するのは OAuth **トークン**の id（`ot-...`）で、これは OAuth client（`oc-...`）にぶら下がっている。接続を authorize し直すとトークン id が変わるため、値を書き込まずに毎回引いている。

**VCS 用の App は「User-to-server token expiration」を Opt-out にしてある。**
GitHub App のユーザートークンは、既定では 8 時間で失効する。
HCP Terraform は refresh token で更新しないため、既定のままだと半日ほどで VCS 連携が外れ、毎回 reauth が必要になる。
設定場所は App の設定 → Optional features。

期限を外すと、OAuth App のトークンと同じく無期限になる。
その代わり、トークンでできることは App の permission とインストール先の範囲に絞られる。
OAuth App の `repo` スコープより狭い。

---

## 3. GitHub App

org `haruka-aibara` の Settings → Developer settings → GitHub Apps にある。**消すと Terraform が GitHub を操作できなくなる。**

GitHub Apps タブには自前の App が **2 つ**並んでいる。
provider 認証用（このセクションの主題）と、HCP Terraform の VCS 連携用（§2 の `vcs_repo`）である。
VCS 用は OAuth 方式で HCP Terraform に登録しているが、実体は OAuth App ではなく GitHub App である。
用途が全く違うので消し間違えないこと。

HashiCorp が提供する VCS 連携用の App は**使っていない**。理由は §4 を参照。

### permissions と、それが必要な理由

| Permission | Level | これが無いと落ちるもの |
|---|---|---|
| Administration | Read and write | `github_repository`、`topics`、`github_branch_protection`、`github_repository_vulnerability_alerts`、**org への新規リポジトリ作成** |
| Contents | Read and write | `github_repository_file` |
| Workflows | Read and write | `.github/workflows/*.yml` の書き込み。**Contents だけでは 403 になる** |
| Metadata | Read | 自動付与 |

Organization permissions は全て No access でよい。`POST /orgs/{org}/repos` に必要なのは Repository permissions の Administration (write) である（GitHub 公式の OpenAPI 仕様で確認済み）。

インストール先は **All repositories**。Terraform が新規作成したリポジトリを自動的に含めるため。

### コミットの作者

`github_repository_file` が作るコミットは App の bot 名義になる。`main.tf` の CI 配布リソースの

```hcl
lifecycle {
  ignore_changes = [commit_author, commit_email]
}
```

はこれを差分にしないためのもの。

---

## 4. なぜこうなっているのか

同じ検討を繰り返さないための記録。詳細な根拠は [移行手順書](../runbooks/github-org-migration-and-app-auth.md) にある。

### なぜ PAT をやめたのか

PAT は**最長 1 年で必ず失効**し、**GitHub に発行 API が存在しない**ため更新は必ず手作業になる。つまり「自動化できない作業が毎年強制される」状態だった。

App に変えても鍵の生成は手作業のままだが、**鍵に有効期限が無いので放置しても壊れない**。強制される作業が任意の作業になった、というのが実際の利得である。

副次的に、権限が細かくなり（スコープ単位 → permission 単位）、個人アカウントに依存しなくなった。

### なぜ OIDC でトークンを無くさないのか

**GitHub が対応していない。** GitHub の OIDC は発行側専用で、Actions が発行したトークンを AWS や GCP に渡す方向にしか使えない。外部 IdP が発行した OIDC トークンを GitHub API が受理する機能は存在しない。

HCP Terraform の dynamic provider credentials も AWS / GCP / Azure / Vault / Kubernetes / HCP のみが対象で、GitHub provider は対象外である。

### なぜ VCS 連携だけ OAuth なのか

HCP Terraform の VCS 連携には GitHub App 方式と OAuth 方式があり、**この構成は後者を選んでいる**。§4 の他の判断と逆方向（人に紐づく側）に見えるので、理由を残す。

App 方式は「workspace とリポジトリを結び付けてよいか」の判定を、**呼び出した HCP ユーザーの GitHub アカウント**に対して行う。installation は All repositories で入っている＝HCP から見れば org 全部の鍵束なので、呼び出し元を絞る壁がそこしかない、という設計である（公式ドキュメントいわく、App 連携は HCP の組織にすら閉じていない）。

この壁は、**人でない認証情報では原理的に越えられない**。team token も organization token も GitHub アカウントを持たない合成アカウントとして認証されるため、`vcs_repo` を含む workspace の作成・更新が 422 で落ちる。そして tfe provider には user token を発行する手段が無い（`tfe_team_token` はあるが `tfe_user_token` は存在しない）。

つまり App 方式のままでは、**`TFE_TOKEN` の自動ローテーションと、Terraform による workspace 作成が両立しない**。UI で workspace を作る運用に落とすなら App 方式でよいが、この repo はそれを採らない。

OAuth 方式は「組織が特定の 1 ユーザーとして振る舞う」方式で、identity が呼び出し元ではなく**接続オブジェクト側**に載る。だから team token で通る。

代償は正直に書いておく。

- 無期限シークレットが 1 個増える（VCS 用 App の client secret と、authorize したユーザーのトークン。どちらも HCP 内。トークンは期限を Opt-out して無期限にしている。§2 参照）
- 権限は、VCS 用 App の permission と authorize したユーザーの権限が重なる範囲になる。OAuth App で繋ぐ場合の `repo` スコープよりは狭い
- **authorize したユーザーに依存し続ける**。App 方式では「繋ぐときだけ」人が要ったが、OAuth では「動き続けるのに」人が要る。revoke されたり org を抜けると全 workspace の VCS 連携が止まる

### なぜ Vault を挟まないのか

Vault には **GitHub の secrets engine が標準で存在しない**。あるのは GitHub auth method で、これは「GitHub の PAT で Vault にログインする」逆方向の機能である。

必要になるのは community 製の external plugin だが、**HCP Vault Dedicated はユーザー提供の external plugin を登録できない**。self-hosted Vault なら可能だが、PEM 1 個を守るために Vault サーバを常時運用することになる。

---

## 5. 自動化できないこと

**GitHub が API を提供していないため、どう工夫しても手作業が残る。**

### PEM のローテーション

App の秘密鍵は**生成も削除も Web UI でしかできない**。REST にも GraphQL にもエンドポイントが無く、GitHub Support も「そのような API は存在しない」と回答している。鍵の生成・削除は **Audit Log にも記録されない**。

自動化できるのは配布側（UI で生成した後に変数へ入れる処理）だけで、**半自動が上限**である。

### App そのものの管理

GitHub 公式の OpenAPI 仕様において、App に対する書き込み系エンドポイントは webhook 設定・インストールの削除/停止・トークン発行のみ。**作成・permissions 変更・秘密鍵生成・インストールに対応する API が無い。**

`POST /app-manifests/{code}/conversions` は PEM を返すが、**App の新規作成専用**かつブラウザでのハンドシェイクを要するため、ローテーション手段にはならない。

provider が持つのは `github_app_installation_repository` 系（インストール済み App とリポジトリの紐付け）だけで、All repositories でインストールしている限り出番はない。

---

## 6. よくある操作

### 秘密鍵をローテーションする

**無停止で可能。** App は最大 25 本の鍵を同時に有効化でき、鍵が 1 本しかない場合は新鍵を生成するまで旧鍵を削除できない仕様になっている。

1. App の設定 → Private keys → **Generate a private key**（手作業）
2. workspace 変数 `GITHUB_APP_PEM_FILE` を新しい値に差し替える（**1 行化が必要。§7 参照**）
3. speculative plan で新鍵が機能することを確認する
4. App の設定で旧鍵を削除する（手作業）

鍵に有効期限は無いので、**やらなくても壊れない**。漏洩時か、定期的な衛生管理として実施する。

### App を入れ直した / 別の org に入れた

- `GITHUB_APP_INSTALLATION_ID`（環境変数）を新しい数値 ID に更新する
- `vcs_repo` 側は VCS 連携（OAuth）の話なので**無関係**。App を入れ直しても影響しない

### 新しいリポジトリを Terraform で作る

`main.tf` に module を足すだけでよい。org に対する作成なので installation token で通る。

個人アカウント配下には**作成できない**（`POST /user/repos` が installation token を受け付けない）。org 化した理由のひとつがこれである。

---

## 7. ハマりどころ

### 環境変数に改行を入れられない

PEM をそのまま貼ると保存できない。

```
Error saving variable
Value cannot contain newlines in environment variables
```

改行を `\n` の 2 文字に置換して 1 行にする。provider 側が実際の改行に戻す。

```bash
awk '{printf "%s\\n", $0}' your-app.private-key.pem
```

`-----BEGIN` から `-----END ...-----` まで全体を含めること。

### 資格情報が無いと plan が「失敗せずに返ってこない」

`GITHUB_TOKEN` を消した状態で `GITHUB_APP_PEM_FILE` が未設定だと、provider が匿名リクエストにフォールバックし、60 req/hour の制限に当たってリトライに入る。30 前後のリポジトリを refresh する途中で止まるため、**エラーも出ず延々待つ**という分かりにくい症状になる。

### sensitive 変数は Terraform から見えない

§2 のとおり。plan がクリーンでも、値が正しい保証にはならない。

---

## 8. 症状から原因を引く

| 症状 | 原因 |
|---|---|
| `401` | PEM の 1 行化ミス、または App ID / installation ID の不整合 |
| `403` | permission 不足。特に **Workflows**（`.github/workflows/` への書き込み時） |
| `Resource not accessible by integration` | 個人アカウント配下にリポジトリを作ろうとしている |
| push しても run が走らない | VCS 連携側の問題。webhook が消えたか、VCS 用 App の認可が revoke されている |
| VCS 連携が半日ほどで外れ、reauth を求められる | VCS 用 App の「User-to-server token expiration」が有効に戻っている。§2 参照 |
| webhook 作成で apply が落ちる | VCS 用 App を authorize したユーザーが、その repo に admin 権限を持っていない |
| plan が返ってこない | 資格情報が無効で匿名アクセスになっている |
| `Value for undeclared variable` | 宣言を消した変数が workspace に残っている。UI から削除する |

---

## 関連

- [GitHub Organization 移行 + GitHub App 認証 移行手順書](../runbooks/github-org-migration-and-app-auth.md) — この構成に至った経緯と、各判断の根拠
- `main.tf` の `tfe_variable` — 変数の宣言
- `providers.tf` — provider 設定（認証の記述は無い）
- `main.tf` の HCP Terraform セクション — workspace と VCS 連携
