tags: aws, cloudwatch-logs, monitoring

# ログが届いているかの確認は Filter と Logs Insights の両方を試してもいい

`FilterLogEvents` で、あるはずのログが取れないことがあった。
原因は確かめていない（[til](../til/2026-10-17-CloudWatch_Logsで取れないときはLogs_Insightsも試す.md)）。

届いているかを API で確かめるなら、`FilterLogEvents` で取れなかったときに Logs Insights でも同じ範囲を見て、どちらかで取れれば届いているとする、というやり方もできる。
取れないほうに外れる話なので、両方試しても困ることは少なそう。

Logs Insights はスキャン量で課金されるので、`FilterLogEvents` を先にするのがよさそう。

Logs Insights なら取れるのか、そもそも何が原因なのかは未確認。
