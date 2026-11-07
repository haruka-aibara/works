tags: aws, inspector, sbom, vulnerability, nvd, security

# Inspector の検出は脆弱性 DB への反映を待つ

Inspector の finding は、スキャンで見えたパッケージと Inspector の脆弱性 DB が突き合わさって初めて出る。
公表済みの脆弱性でも、DB に載るまでは finding にならない。

## 反映が遅れやすい

- NVD の分析（CVSS や影響バージョン範囲）が追いつかず積み残しが続いている
- AI でバグを探すようになり、報告数がさらに増えている

公表から DB に載るまでの空白が長くなりがちで、重大な脆弱性ほどその間に「うちは影響ある？」と聞かれる。

## SBOM で空白を埋める

Inspector は、スキャンした EC2・ECR イメージ・Lambda のパッケージ一覧を SBOM（CycloneDX / SPDX）として S3 にエクスポートできる。
委任管理者からなら全アカウント分を出せる。
中身を脆弱性 DB から切り離して持てるので、GHSA や OSV と自分で突き合わせられる。

エクスポートは 1 回ずつのスナップショットで、スキャンできたパッケージしか載らない。

使い方は [ideas](../ideas/2026-11-07-重大な脆弱性のどこで使ってるをInspectorを待たずに引く.md)。

SBOM エクスポートが無料かは未確認。
