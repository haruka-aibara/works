import logging

import boto3

logger = logging.getLogger()
translate = boto3.client("translate")


def lambda_handler(event, context):
    # SourceLanguageCode を auto にすると、言語の判定に Comprehend が呼ばれる。
    response = translate.translate_text(
        Text=event["text"],
        SourceLanguageCode=event.get("source", "auto"),
        TargetLanguageCode=event.get("target", "en"),
    )
    # 本文は機密を含みうるのでログに出さない。
    logger.info(
        "translated",
        extra={
            "source": response["SourceLanguageCode"],
            "target": response["TargetLanguageCode"],
        },
    )
    return {"text": response["TranslatedText"]}
