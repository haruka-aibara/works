tags: eventbridge, guardduty, monitoring, alerting

# セキュリティ通知の EventBridge は FailedInvocations にアラームを張る

GuardDuty の finding を EventBridge → Lambda / Slack 連携に流している構成で、
ターゲットが権限エラーやスロットリングで失敗すると、EventBridge はリトライしたあと**黙って捨てる**。
通知が来ないことは、検知がないことと見分けがつかない。

## やること

- ルールのターゲットに **DLQ（SQS）** を付ける。捨てられたイベントがあとから読める
- `AWS/Events` の **`FailedInvocations`** にアラームを張る。DLQ への送信自体が失敗したときの `InvocationsFailedToBeSentToDlq` も見る
- アラームの通知先は、元の Lambda を通らない経路（SNS → メールなど）にする。同じ経路だと、壊れたときに一緒に黙る

## 拾えないもの

EventBridge から Lambda への呼び出しは非同期なので、Lambda が受け付けた時点で EventBridge から見ると成功になる。
Lambda の中で Slack の API が落ちて失敗しても、`FailedInvocations` には出ない。

こちらは Lambda 側で押さえる。

- 非同期呼び出しの on-failure 宛先（または関数の DLQ）を設定する
- Lambda の `Errors` メトリクスにもアラームを張る

リトライの既定値（24 時間・185 回）が今も同じかは未確認。
