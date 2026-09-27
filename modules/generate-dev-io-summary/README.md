# generate-dev-io-summary

DevelopersIO に前日投稿された記事を要約して、毎朝 Slack へ通知するモジュール。

![image](https://github.com/user-attachments/assets/1aa0052e-ce90-41da-be98-f320f598cadb)

旧リポジトリ `generate-dev-io-summary` を履歴ごと取り込んだもの。
過去の経緯は `git log -- modules/generate-dev-io-summary` で辿れる。

参考記事: https://dev.classmethod.jp/articles/generate-dev-io-summary/

## コードの外にある前提

- Slack ワークスペースは、事前に AWS Chatbot のコンソールで認可しておく。

## 気をつけること

- **Lambda Layer の中身はコミットしない。**
  plan のたびに `build_layer.py` が `requirements.txt` から作るので、バージョンを変えるときは `requirements.txt` だけを直す。
