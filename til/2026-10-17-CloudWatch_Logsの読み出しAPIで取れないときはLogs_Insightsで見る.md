tags: aws, cloudwatch-logs, monitoring

# CloudWatch Logs の読み出し API で取れないときは Logs Insights で見る

`GetLogEvents` や `FilterLogEvents` は、指定した範囲にログがあるのに返ってこないことがある。

同じ症状の報告はいくつもある。

- 範囲を 1 ms 広げると、さっきまで返っていたイベントが消える
- 取り込んでから何時間たっても返らない
- 同じ範囲を Logs Insights（`StartQuery`）で検索すると出てくる

AWS の回答は「範囲とストリームを絞れ」という回避策だけだった。

## どうするか

- 読み出し API で取れないときは、Logs Insights で同じ範囲を検索してみる
- 届いているかの監視には、読み出し API を使わない
  - ロググループ単位：`AWS/Logs` の `IncomingLogEvents` にアラームを張り、`treat_missing_data = breaching` にする
  - ストリーム単位：組み込みのメトリクスはないので、Lambda から Logs Insights で `stats count(*) by @logStream` を流し、届くべき一覧と突き合わせる

Get / Filter で取れないのがバグなのか結果整合性なのか、Logs Insights なら必ず取れるのかは未確認。

参考：[re:Post の報告](https://repost.aws/questions/QUGnuCHe_tTkSFQEM7UJKy9w/response-from-filterlogevents-call-drops-some-events-that-exist-in-loggroup)
