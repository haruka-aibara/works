# google-cloud-hands-on

Google Cloud のハンズオン用プロジェクトで、使いすぎに気づけるように予算アラートを張るモジュール。

## コードの外にある前提

- 呼び出し側に `google` プロバイダーが要る。
- 認証情報は、ワークスペースの環境変数 `GOOGLE_CREDENTIALS` から読ませる。
