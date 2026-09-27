# bedrock-slack-ai-chatbot

Amazon Bedrock を使った Slack の AI チャットボット。
メンションするとスレッドに返信する。
スレッドを読んで文脈にするので、ボットが加わっていなかった会話の途中に「@bot どう思う？」と投げても、それまでの流れを踏まえて答える。

参考: [Amazon BedrockとSlackで生成AIチャットボットアプリを作る (その2：Lambda＋API Gatewayで動かす)](https://dev.classmethod.jp/articles/amazon-bedrock-slack-chat-bot-part2/)

## なぜこの作りか

- **スレッドの発言者は区別しない。**
  区別するには `users:read` と参加者ごとの問い合わせが要り、生の `<@U…>` をプロンプトに入れると、モデルがそれを真似して通知を飛ばす危険がある。

## コードの外にある前提

Slack アプリの設定は Terraform では持てない。

- **Bot Token Scopes に次を足し、Reinstall to Workspace する。**
  `app_mentions:read`・`chat:write`・`channels:history`・`groups:history`。
- **Event Subscriptions を有効にし、Request URL に `{API Gateway のエンドポイント}/slack/events` を入れる。**
  Subscribe to bot events に `app_mention` を足す。
- **ボットをチャンネルに招待する（`/invite @app_name`）。**
