# CloudTrail を DuckDB で掘るか Athena で掘るか

「このロールは先月何回 AccessDenied を出したか」「root は使われていないか」。
権限の見直しや侵害の疑いが出たとき、知りたいのは1件のイベントではなく「誰が何を何回」の集計になる。

`aws cloudtrail lookup-events` は直近90日の管理イベントだけが対象で、絞り込める属性も1つだけ。
それより先を掘るなら、S3 に出している証跡を SQL で読むことになる。
手段は Athena と DuckDB の2つがある。

前提として、S3 に出している証跡がなければ、どちらでも掘れない。
掘りたくなるのはたいてい何か起きたあとなので、証跡は先に作っておく。

## 正直な比較

| 観点 | Athena | DuckDB（手元） |
|---|---|---|
| 準備 | テーブル定義とパーティション設定が要る | 要らない。ファイルを直接読む |
| 課金 | クエリごと。スキャン量 1TB あたり $5（最低 10MB）＋S3 の GET | ダウンロード時だけ。その後は何回掘っても無料 |
| 試行錯誤 | 1回ごとに少しずつ課金される | 気にしなくていい |
| 規模の上限 | TB 単位でもそのまま掘れる | 手元に落としきれる量まで |
| データの置き場所 | AWS の中から出ない | 手元にコピーができる |
| 証拠としての扱い | S3 の原本を直接読む | 手元のコピーは証拠にならない |

クエリごとに課金されるのは、規模を問わず気になる。
ログが多い組織では、1回のスキャンが重く、調査の試行錯誤がそのまま請求に積み上がる。
個人は金額が小さくても、そもそも払いたくない。

DuckDB にすると、払うのはダウンロードの1回だけになり、そのあとの試行錯誤は無料になる。
準備なしで始められて、手元で速く何度でも試せるのもこちらの良さ。

弱みは、ログが TB 単位になると手元に落としきれないこと。
転送量もかかる（S3 からインターネットへの転送は全サービス合計で毎月 100GB まで無料、それを超えると課金）。
この場合も、Athena で絞る1回だけ課金を受け入れ、掘るのは手元に移せば、クエリごとの課金は1回で済む。

## 線引き

- **全部落とせる規模**：DuckDB だけでいい
- **落としきれない規模**：Athena で対象（期間・ロール）を絞って結果だけ落とし、そこから先を DuckDB で掘る
- **1件のイベントを見たいだけ**：コンソールのイベント履歴で足りる

「どちらか」ではなく、絞るのは Athena（課金は1回）、掘るのは DuckDB（何回でも無料）という分担にすると両方の弱みが消える。

## DuckDB で読む最小例

S3 から直接読むこともできるが、CloudTrail は1リージョンあたり5分ごとくらいにファイルを出すので、1か月で数千ファイルになり遅い。
期間を prefix で絞って一度落とすほうが速く、2回目からは差分だけで済む。

```bash
aws s3 sync s3://<bucket>/AWSLogs/<account-id>/CloudTrail/ap-northeast-1/2026/09/ ./trail/2026/09/
```

`requestParameters` の形はイベントごとに違うので、JSON 型のまま読み、使う列だけビューで取り出す。

```sql
CREATE VIEW trail AS
SELECT
  (r ->> '$.eventTime')::TIMESTAMP                     AS event_time,
  r ->> '$.userIdentity.arn'                           AS arn,
  r ->> '$.userIdentity.sessionContext.sourceIdentity' AS source_identity,
  r ->> '$.eventName'                                  AS event_name,
  r ->> '$.errorCode'                                  AS error_code,
  r                                                    AS raw
FROM (
  SELECT unnest(Records) AS r
  FROM read_json('trail/**/*.json.gz', columns = {Records: 'JSON[]'})
);

-- 権限不足で落ちた操作の多い順
SELECT arn, event_name, count(*) AS n
FROM trail
WHERE error_code = 'AccessDenied'
GROUP BY ALL
ORDER BY n DESC;
```

## 注意

- **手元のコピーは証拠にならない**：改ざん防止が効いているのは S3 側（Object Lock・ログファイル検証）だけ。監査や調査報告では S3 の原本を使う
- **置き場所に気をつける**：アカウント ID や IP アドレスが入っている。公開リポジトリの中に落とさない

## 参考

- [Querying AWS CloudTrail logs - Amazon Athena](https://docs.aws.amazon.com/athena/latest/ug/cloudtrail-logs.html)
- [Amazon Athena pricing](https://aws.amazon.com/athena/pricing/)
- [Amazon S3 pricing](https://aws.amazon.com/s3/pricing/)
- [CloudTrail log file examples](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-log-file-examples.html)
- [DuckDB: Loading JSON](https://duckdb.org/docs/stable/data/json/loading_json)
- [DuckDB: S3 API Support](https://duckdb.org/docs/stable/core_extensions/httpfs/s3api)
