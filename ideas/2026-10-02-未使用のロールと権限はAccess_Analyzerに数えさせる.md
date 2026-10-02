tags: aws, iam, access-analyzer, security

# 未使用のロールと権限は Access Analyzer に数えさせる

IAM Access Analyzer の「未使用のアクセス」アナライザーは、使われていないロール・アクセスキー・パスワード・サービス単位とアクション単位の権限を検出する。
最終アクセス情報を自分で集めて突き合わせるスクリプトは書かなくて済む。

## 自作との比較

- 最終アクセス情報（`GenerateServiceLastAccessedDetails`）は無料だが、全ロールを回して集計し、閾値を決めて、通知まで作るのは自分
- アナライザーはロール・ユーザー単位の月額課金。ロールが多い組織ほど効く金額になる
- 判定ロジックを持たないで済むのが差。[Cloud Custodian の話](2026-09-26-Cloud_CustodianでConfigルールを作ってみた.md) と同じ「自作して保守する量」で比べる

## 使い方の案

- まず検出だけ。削るのは、未使用期間が長いロールから人間が判断する
- 検出結果は Security Hub CSPM にも流れるので、通知の経路は既存のものに乗せる
- 料金と、Security Hub CSPM 連携の有無は公式ドキュメント未確認
