tags: terraform, tflint, ci

# tflint-ruleset-terraform を preset = "all" で入れる

[tflint-ruleset-terraform](https://github.com/terraform-linters/tflint-ruleset-terraform) は TFLint に同梱されていて、
`.tflint.hcl` がなくても `recommended` のルールだけは動いている。

`.tflint.hcl` で明示して `preset = "all"` にすると、`recommended` に入っていないルールも効く。

```hcl
plugin "terraform" {
  enabled = true
  preset  = "all"
}
```

## 増えるもの（例）

- 変数・出力に `description` と `type` があるか
- リソース名などの命名規則
- モジュールの標準構成（`main.tf` / `variables.tf` / `outputs.tf`）になっているか
- 使っていない `required_providers` がないか

## 気をつけること

- 一気に入れると既存コードで大量に落ちる。最初は `all` で一度回して件数を見て、合わないルールだけ `rule "..." { enabled = false }` で外す
- 同梱版とプラグイン版でバージョンがずれることがある。明示するなら `version` と `source` も書いて固定する

`recommended` と `all` の差分と、同梱版の扱いは公式ドキュメント未確認。
