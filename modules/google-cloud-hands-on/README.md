# google-cloud-hands-on

Google Cloud のハンズオン用プロジェクトで、使いすぎに気づけるように予算アラートを張るモジュール。

旧リポジトリ `google-cloud-hands-on` を履歴ごと取り込んだもの。
過去の経緯は `git log -- modules/google-cloud-hands-on` で辿れる。

## コードの外にある前提

- 呼び出し側に `google` プロバイダーが要る。
- 認証情報は、ワークスペースの環境変数 `GOOGLE_CREDENTIALS` から読ませる。
