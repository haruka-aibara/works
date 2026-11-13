# Config ルールごとの NON_COMPLIANT リソース数を CloudWatch メトリクスに書く。
# Config 自体はルールごとの非準拠数をメトリクスとして出さないので、定期実行して数えて送る。
# DescribeComplianceByConfigRule の件数は 100 で頭打ちになるため、評価結果を全件たどって数える。
import os

import boto3

config = boto3.client("config")
cloudwatch = boto3.client("cloudwatch")

NAMESPACE = os.environ["METRIC_NAMESPACE"]
RULE_NAMES = [r for r in os.environ["RULE_NAMES"].split(",") if r]


def count_non_compliant(rule_name):
    paginator = config.get_paginator("get_compliance_details_by_config_rule")
    return sum(
        len(page["EvaluationResults"])
        for page in paginator.paginate(
            ConfigRuleName=rule_name, ComplianceTypes=["NON_COMPLIANT"]
        )
    )


def run(event, context):
    counts = {rule: count_non_compliant(rule) for rule in RULE_NAMES}
    metric_data = [
        {
            "MetricName": "NonCompliantResources",
            "Dimensions": [{"Name": "RuleName", "Value": rule}],
            "Value": count,
            "Unit": "Count",
        }
        for rule, count in counts.items()
    ]
    # PutMetricData は 1 回 1000 件まで
    for i in range(0, len(metric_data), 1000):
        cloudwatch.put_metric_data(Namespace=NAMESPACE, MetricData=metric_data[i : i + 1000])
    return counts
