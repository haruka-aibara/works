tags: aws, cloudwatch-logs, monitoring

# CloudWatch Logs で取れないときは Logs Insights も試す

`GetLogEvents` や `FilterLogEvents` で、指定した範囲にあるはずのログが返ってこないことがあった。
原因は確かめていない。

似た報告は re:Post にいくつかある。

- 範囲を 1 ms 広げたら、返っていたイベントが返らなくなった
- Logs Insights（`StartQuery`）で同じ範囲を検索したら出てきた

取れないときは、Logs Insights で同じ範囲を見てみるのも手。
届いているかの確認に使う話は [ideas](../ideas/2026-10-17-ログが届いているかの確認はFilterとLogs_Insightsの両方を試してもいい.md) に書いた。

バグなのか結果整合性なのか、Logs Insights なら取れるのかは未確認。

参考：[re:Post の報告](https://repost.aws/questions/QUGnuCHe_tTkSFQEM7UJKy9w/response-from-filterlogevents-call-drops-some-events-that-exist-in-loggroup)
