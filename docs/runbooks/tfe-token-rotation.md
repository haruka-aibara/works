# TFE_TOKEN 自動ローテーション

**この文書を読むとき:** 初回のブートストラップをやるとき。run が「トークンが無効」で落ちて文鎮化を疑うとき。周期を変えるとき。トークンが漏れて今すぐ回したいとき。

**3行:**

- workspace `works` が自分の次の `TFE_TOKEN` を発行する。人が触るのは**初回だけ**
- トークンは blue / green の 2 本を半周期ずらして持ち、run は**使っていない方**だけを作り直す
- **`TFE_TOKEN` という変数は消えないし、権限も縮んでいない。** Free では専用 team を作れないので owners team のトークンを回している。得ているのは有効期限と自動更新だけ（§7）

---

## 1. しくみ

```
周期が来る
  → time_rotating が作り直される（plan のたびにプロバイダが現在時刻と比較している）
  → 基準時刻が「今」に動く
  → そこから導出した失効時刻が変わる
  → その失効時刻を description に持つ team token が作り直される
  → TFE_TOKEN に新しい値が書き戻される
```

**定期ローテーションではコードが1文字も変わらない。** 差分は時計から出る。やることは Plan & Apply を1回通すだけで、PR は要らない。
`works` は `auto_apply = false` なので、plan のあとに Confirm を押すところまでが1回。

差分が出たことを知らせる仕組みは無い。plan を走らせて初めて分かる。

### なぜ 2 本なのか

apply は**自分が認証に使っているトークンを消せない**。途中で消すと残りの API 呼び出しが 401 になり、変数の書き戻しに失敗して次の run も動けなくなる（＝文鎮化）。だから常に「使っていない方」だけを作り直す。

`tfe_team_token` には `create_before_destroy` を付けてあるので、両方が同時に作り直される変更（周期の変更など）でも、新トークンの発行と `TFE_TOKEN` の書き戻しが終わってから旧トークンが revoke される。保険であって、これに頼る運用はしない。

---

## 2. 値

| 変数 | 既定値 | 意味 |
|---|---|---|
| `rotation_minutes` | `230400`（160日） | 周期。**引き継ぎは半分の 80 日ごと** |
| `buffer_minutes` | `4320`（3日） | 引き継ぎ後にトークンが生き残る時間。**run を回し忘れても許される日数**でもある |

関係式はこれだけ覚えればいい。

```
引き継ぎ     = 周期 ÷ 2
トークン寿命 = 引き継ぎ + 猶予
```

既定値なら寿命は 83 日。**周期を変えれば寿命も自動で追従する**（定数を書いていないので引き直し忘れが起きない）。「認証情報は90日以内に失効させること」のような要件があるなら、許される寿命 L に対して `周期 ≤ (L − 猶予) × 2` で決める。

猶予が半周期以上になる値は validation で弾かれる（トークンが自分を置き換えるローテーションより長生きしてしまうため）。

---

## 3. 初回ブートストラップ

**前提:** いまの `TFE_TOKEN` は手で入れた user token で、これが最後の手作業になる。

`tfe_variable.tfe_token` は変数を**新規作成する**ので、同じ key の workspace 変数が先に存在していると HCP に弾かれる（同一 workspace に同じ key の変数は2つ持てない）。かといって先に消すと、その apply 自身が認証できない。

そこで **Variable Set 経由で1回だけ食わせる**。HCP の変数の優先順位がこれを保証している。

> **8. Workspace-specific variables**
> Workspace-specific variables **always overwrite** variables from variable sets that have the same key.

つまり「varset に置いた値で run を動かしつつ、workspace 変数を新しく作らせる」が成立する。作られた瞬間から workspace 変数のほうが勝つ。

### 3.1 一時的な Variable Set を作る

Organization Settings → **Variable sets** → Create variable set

| | |
|---|---|
| 名前 | `tfe-token-bootstrap`（何でもよい） |
| Apply to | **Apply to specific workspaces** → `works` |
| Priority | **付けない** |
| 変数 | `TFE_TOKEN` = いまの user token / category `env` / **sensitive** |

**Priority を付けてはいけない。** 付けると varset が workspace 変数を上書きし続け、ローテーションした値が永久に使われない。

### 3.2 workspace 変数の `TFE_TOKEN` を消す

`works` → Variables から、**workspace 変数のほう**の `TFE_TOKEN` を削除する。varset 側が効くので run は動き続ける。

短周期で検証するなら、ここで Terraform 変数として `rotation_minutes = 60` / `buffer_minutes = 20` も置く（§4）。

### 3.3 マージする

merge すると plan が走るので、Confirm を押して apply する。1回の apply で

1. owners team に blue / green のトークンを発行する
2. **workspace 変数として `TFE_TOKEN` を作り、green のトークンを入れる**

まで終わる。この apply 自身は run 開始時に読み込まれた varset の値で最後まで動くので、途中で自分の認証を失うことはない。

### 3.4 通ることと、2本あることを確認する

まず Organization Settings → API Tokens → **Team Tokens** を開き、**`works blue ...` と `works green ...` が2本とも有効な状態で並んでいること**を確認する。

ここが1本しか無い場合、このワークスペースは**破綻している**。description の無いトークンは「新しく作ると古いものが無効になる」レガシー挙動で、それが起きていると blue/green が成立しない。その場合は §6 A の手順で user token に戻し、ローテーションを外すこと。

2本あれば、Actions → Start new run（Plan only）。これが通れば **team token で動いている**（workspace 変数が varset に勝つため）。落ちたら §6 へ。

### 3.5 Variable Set を片付ける

varset をデタッチして削除し、元の user token を revoke する。

**消し忘れても動作は変わらない**（workspace 変数が常に勝つ）が、使われないまま有効な user token が残るので必ず消す。ここを飛ばすと「ローテーションしているのに、強いトークンが1本放置されている」という一番間抜けな状態になる。

### 3.6 半周期後にズラす

blue と green は同時に作られるので、放っておくと**同じ日に両方が作り直される**。そうなると使用中のトークンごと巻き込まれる。初回 apply から半周期後（既定値なら 80 日後、検証中なら 30 分後）に、**`blue_serial` を `2` に上げる PR を1本出す**（ルートの `main.tf` の `module "tfe_team_token_rotation"` の引数）。

同値のとき `timecmp` は green を選ぶので、**初回に使っていないのは blue のほう**。上げるのは必ず blue。

これで blue の基準時刻だけが半周期ずれ、以降は各色が自分の基準時刻から回るのでズレは自動で維持される。

---

## 4. 短周期で検証する

`rotation_minutes = 60` / `buffer_minutes = 20` を置いた場合のタイムライン。引き継ぎ 30 分、寿命 50 分、猶予 20 分。

| 時刻 | 起きること | やること |
|---|---|---|
| `t0` | 初回 apply。blue/green 発行、`TFE_TOKEN` = green | — |
| `t0+30` | — | **`blue_serial` を上げる PR を merge**。blue が作り直され `TFE_TOKEN` = blue に |
| `t0+50` | green が自動失効（引き継ぎの 20 分後） | — |
| `t0+60` | green の周期到来 | **Plan & Apply**。green が作り直され `TFE_TOKEN` = green に戻る |
| `t0+90` | blue の周期到来 | **Plan & Apply**。以降 30 分ごと |

見るべきものは3つ。

- **コードを変えていないのに plan に差分が出る**こと（`time_rotating` が remove + create として現れる）
- Organization Settings → API Tokens → Team Tokens で、トークンが 2 本あり、**片方だけが入れ替わる**こと
- 各トークンの Expires が、引き継ぎの 20 分後になっていること

**`t0+60` を過ぎても run を回さないと文鎮化する。** 猶予 20 分は「回し忘れても許される時間」そのもので、人が思い出して押す運用と組み合わせてはいけない値。検証が終わったら `rotation_minutes` / `buffer_minutes` を UI から削除して本番値に戻す（トークンは作り直されるが、`create_before_destroy` があるので安全）。

---

## 5. 予定外のローテーション（漏洩時）

周期を待たずに今すぐ回す。**使っていない側の serial を上げる PR** を出す。merge → apply で切替まで終わる。

使用中がどちらかは、Team Tokens の description（`works blue r1 exp ...` / `works green r1 exp ...`）のうち **Expires が遠いほう**が現役。

**使用中の側を上げてはいけない。** その apply が自分の認証を消す。使用中のトークンが漏れた場合の順序は「**先に切替、後に失効**」で、

1. 未使用側の serial を上げた PR を merge（切替が終わる）
2. そのあと漏れたトークンを UI か API で revoke

先に revoke すると、`TFE_TOKEN` が死んだトークンを指したまま次の run が動けなくなる。

---

## 6. 文鎮化からの復旧

症状は「run が HCP API の認証で落ちる」。原因は2つしかない。

**A. トークンが全部失効した**（run を長期間回していなかった）

変数はもう Terraform の管理下にあるので、§3 の varset は要らない。値を差し替えるだけでよい。

1. UI で workspace 変数 `TFE_TOKEN` の**値を**自分の user token に差し替える
2. Plan & Apply を1回通す（周期はとっくに過ぎているので `time_rotating` が作り直され、新しいトークンが発行されて `TFE_TOKEN` が上書きされる）
3. user token を revoke する

**B. トークンの権限が足りない**

いまは owners team のトークンなので、権限不足は起きない。起きるとすれば、専用 team に移したあと（下記）に足りない権限があるときで、A と同じ手順で復旧する。

### なぜ owners team なのか

本来は「この構成が管理するものだけ」を持つ専用 team を作るべきで、必要な権限は3つだけ。

| 権限 | 何のため |
|---|---|
| `manage_workspaces` | workspace とその変数 |
| `manage_vcs_settings` | `data.tfe_oauth_client` と `vcs_repo` |
| `manage_teams` | **自分のトークンを作り直すため**（ループの要） |

だが **team の作成には entitlement が要る**（team 管理は Essentials 以上）。Free organization で `tfe_team` を作ろうとすると

```
Error: missing entitlements to create teams
```

で落ちる。既存の owners team にトークンを発行するのは Free でもできるので、そちらに逃がしている。

**有料エディションに上げたら、専用 team を作って `team_id` をそこに向け直すこと。** それをするまで、このトークンは owner 相当の権限を持つ。

---

## 7. 前提と、消えないもの

**run が定期的に回っていること**がこの仕組みの前提。周期の半分（既定値なら 80 日）より短い間隔で run が走らないと、引き継ぎが起きないまま全トークンが失効する。この repo は VCS 連携で merge のたびに run が走るので自然に満たされるが、**80 日間 1 度も merge しなかったら壊れる**。検知すべき異常として扱う。

そして正直に書いておくと、これで**静的シークレットは 1 本も減らない**。

| | 前 | 後 |
|---|---|---|
| 権限 | owner 相当（全 workspace、全 state） | **owner 相当のまま**（§6 のとおり、Free では専用 team を作れない） |
| 期限 | 実質無期限 | 83 日 |
| 紐づき | 個人アカウント | owners team（人に紐づかない） |
| 更新 | 手動（やらなければ永久に同じ値） | 自動 |
| 置き場所 | workspace 変数 | workspace 変数 + **state** |

**権限は縮んでいない。** いま得ているのは「期限が付く」「人に紐づかない」「勝手に入れ替わる」の3点だけで、漏れたときに何ができるかは前と変わらない。縮めたければ有料エディションで専用 team を作る（§6）。

トークンが state に載るのは避けられない。この構成が発行する値だからで、`GITHUB_APP_*` のように「宣言だけ Terraform、値は UI」にはできない。

---

## 関連

- [GitHub 認証のしくみ](../reference/github-authentication.md) — なぜ VCS 連携が OAuth なのか（team token でローテするための前提）
- [ADR-0001](../decisions/0001-tfe-team-token-rotation.md) — 設計の判断と、採らなかった案
- `modules/tfe-team-token-rotation/` — 実装（ルートの `main.tf` の `module "tfe_team_token_rotation"` から呼ぶ）
