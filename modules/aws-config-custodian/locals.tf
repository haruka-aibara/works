locals {
  # policies/ の YAML 1 ファイルが Config ルール 1 本になる。ファイル名（拡張子なし）がポリシー名。
  policies = {
    for f in fileset("${path.module}/policies", "*.yml") :
    trimsuffix(f, ".yml") => yamldecode(file("${path.module}/policies/${f}"))
  }

  # Lambda の config.json。c7n がデプロイ時に zip へ焼き込むものと同じ形式で、
  # ポリシー YAML に name と mode を足しただけのもの。mode は全ポリシー共通なのでここで固定する。
  policy_configs = {
    for name, policy in local.policies : name => jsonencode({
      "execution-options" = {}
      policies = [merge(policy, {
        name = name
        mode = {
          type     = "config-poll-rule"
          schedule = var.schedule
          # Config が記録しているリソースでも、関連情報（最終使用日時など）で判定するために定期評価で動かす
          "ignore-support-check" = true
        }
      })]
    })
  }

  c7n_version = "0.9.52"
  c7n_wheel   = "${path.module}/vendor/c7n-${local.c7n_version}-py3-none-any.whl"
  runtime     = "python3.13"
}
