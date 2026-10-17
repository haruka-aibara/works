tags: aws, cloudwatch-logs, monitoring

# ログが届いているかは Filter と Logs Insights のどちらかで取れればよしとする

CloudWatch Logs の読み出し API は、あるログを返さないことがある（[til](../til/2026-10-17-CloudWatch_Logsの読み出しAPIで取れないときはLogs_Insightsで見る.md)）。
ただ、外れ方は「あるのに返らない」だけで、「ないのに返る」はない。
だから、**どれか 1 つで取れたら「届いている」と判定**しても誤りにならない。

## 判定の順番

安いものから試す。

1. `FilterLogEvents` を、範囲とストリームを絞って呼ぶ。取れたら OK
2. 取れなかったときだけ、Logs Insights で同じ範囲を検索する（スキャン量で課金）
3. それでも 0 件なら「届いていない」とする

範囲の終わりは数分前にずらす。取り込みの遅延は、どの API でも同じように受ける。

Logs Insights なら必ず取れるのかは未確認。
