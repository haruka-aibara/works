# bedrock-slack-ai-chatbot

Amazon Bedrock を使った Slack の AI チャットボット。
メンションするとスレッドに返信する。
スレッドを読んで文脈にするので、ボットが加わっていなかった会話の途中に「@bot どう思う？」と投げても、それまでの流れを踏まえて答える。

参考: [Amazon BedrockとSlackで生成AIチャットボットアプリを作る (その2：Lambda＋API Gatewayで動かす)](https://dev.classmethod.jp/articles/amazon-bedrock-slack-chat-bot-part2/)

## なぜこの作りか

### 会話の状態は Slack にしか持たない

文脈は、毎回 `conversations.replies` でスレッドを読み直して作る。
自前のストアには会話を持たない。

履歴を別に保存していた頃は、ボットが加わったやりとりしか記録されず、人同士で話していたスレッドはボットから見えなかった。
保存した履歴と、ユーザーに見えているスレッドが食い違うこともあった。
スレッドを読めば正は 1 つになり、同じスレッドに 2 つのメンションが来たときの競合や、保存と投稿の順番の問題も消える。

DynamoDB は冪等性のための claim だけに使う。

### スレッドを会話に変換するときの決めごと

- `bot_id` のあるメッセージを `assistant`、それ以外を `user` にし、同じ側が続いたら 1 ターンにまとめる。
  Bedrock は user / assistant の交互を求めるが、スレッドは人の発言が何件も続く。
- `<@U…>` のメンションは消す。
  モデルがそれを真似して、会話にいない人に通知を飛ばさないようにするため。
- ボット自身の定型の失敗メッセージは除く。
  過去の失敗を文脈に入れると、失敗を真似しやすくなる。
- 質問より後の投稿は入れない。
  キューで待っている間にスレッドが進んでいることがある。
- 発言者は区別しない。
  区別するには `users:read` と参加者ごとの問い合わせが要り、生の `<@U…>` をプロンプトに入れると通知を飛ばす危険がある。

スレッド全体を Bedrock に送るので、ボット宛てでないメッセージも送られる。

### キューを挟む理由

Slack はイベントへの応答を 3 秒しか待たず、Bedrock の呼び出しはそれより長い。
そのため回答はリクエストの外で作る。

非同期の Lambda 呼び出しではなく SQS を使うのは、Bedrock のクォータが Lambda の同時実行数よりずっと小さいから。
同時にモデルへ届く数を絞り、スロットリングされた要求を再試行し、それでも失敗したものを残すために SQS を使う。

| 設定 | ないと何が起きるか |
|---|---|
| `visibility_timeout_seconds`（関数のタイムアウトより十分長く） | 遅い実行の途中でメッセージが再配信され、スレッドに回答が 2 つ付く |
| `message_retention_seconds`（キュー） | 溜まったときに質問が黙って消える |
| `message_retention_seconds`（DLQ） | 失敗を調べる前に消える |
| `maxReceiveCount` | 失敗し続けたものがハンドラーに届かず、ユーザーに何も伝わらない |
| `maximum_concurrency` | 一気に来たときに全部が同時に呼ばれ、まとめてスロットリングされる |

### 再試行の役割を分ける

キューの再配信は visibility timeout より早くは来ないので、回答には使えない。
戻ってきた頃には回答が遅すぎる。

- **スロットリングの再試行は、1 回の実行の中でやる。**
  Bedrock クライアントの adaptive リトライで数秒単位で待つ。
  回答を返せる再試行はこれだけ。
- **キューの再配信は、回答ではなく知らせるためにある。**
  `ANSWER_DEADLINE_SECONDS` より古い質問には答えず、スレッドに「諦めた」と一度だけ投稿する。

保持期間は長く、回答の期限は短い。
保持期間は「誰にも気づかれずに消えるまで」で、期限は「その回答にまだ価値があるか」を決める。
別のつまみなので、分けて持つ。

配信は 2 か所で at-least-once になるので、どちらもコードで処理する。

- **Slack の再送**：`X-Slack-Retry-Num` ヘッダーを見て、受け付けるだけでキューには積まない。
- **SQS の再配信**：Slack の `event_id` を渡し、処理の前に DynamoDB で期限付きの claim を取る。
  処理に失敗したら claim を外し、再試行を通す。

## コードの外にある前提

Slack アプリの設定は Terraform では持てない。

- **Bot Token Scopes に次を足し、Reinstall to Workspace する。**
  `app_mentions:read`・`chat:write`・`channels:history`・`groups:history`。
  history の scope がないと `conversations.replies` が失敗し、メンション本文だけで答える。
  ボットを止めないための意図的な縮退で、ログに `Could not read thread ...` が出る。
- **Event Subscriptions を有効にし、Request URL に `{API Gateway のエンドポイント}/slack/events` を入れる。**
  Subscribe to bot events に `app_mention` を足す。
  足さないと Slack から何も届かない。
- **ボットをチャンネルに招待する（`/invite @app_name`）。**
  history の scope だけでは、メンバーでないチャンネルは読めない。
- **Lambda Layer は plan のたびに `build_layer.py` が `requirements.txt` から作る。**
  Terraform を動かす環境に、pip の使える `python3` が要る。

## 気をつけること

- **`ANSWER_DEADLINE_SECONDS` は `CLAIM_TTL_SECONDS` より短く、`CLAIM_TTL_SECONDS` はキューの `visibility_timeout_seconds` と同じにする。**
  前者はテストで検査している。
  後者は Python と Terraform に別々に書いてあるので、変えるときは両方直す。
- **テストは Lambda のディレクトリに置かない。**
  `lambda_function_*/` は `data.archive_file` でそのまま zip になるので、混ぜると本番に載り、`source_code_hash` も変わる。
