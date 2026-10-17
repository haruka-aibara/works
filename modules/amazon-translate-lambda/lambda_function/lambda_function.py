import logging
import re

import boto3

# ログの出力形式（JSON）とレベルは Lambda の logging_config で決める。
logger = logging.getLogger()

translate = boto3.client("translate")

# TranslateText の上限は 10,000 バイト。
MAX_TEXT_BYTES = 10_000
LANGUAGE_CODE = re.compile(r"^[a-z]{2,3}(-[A-Za-z]{2,4})?$")


def lambda_handler(event, context):
    text, source, target = _parse(event)

    # 本文は個人情報や機密を含みうるのでログに出さない。長さと言語だけ残す。
    logger.info(
        "translate start",
        extra={"source": source, "target": target, "bytes": len(text.encode())},
    )

    response = translate.translate_text(
        Text=text,
        # auto にすると、言語の判定に Comprehend が呼ばれる。
        SourceLanguageCode=source,
        TargetLanguageCode=target,
    )

    logger.info(
        "translate done",
        extra={
            "source": response["SourceLanguageCode"],
            "target": response["TargetLanguageCode"],
        },
    )
    return {
        "source": response["SourceLanguageCode"],
        "target": response["TargetLanguageCode"],
        "text": response["TranslatedText"],
    }


def _parse(event):
    if not isinstance(event, dict):
        raise TypeError("event must be an object")

    text = event.get("text")
    if not isinstance(text, str) or not text.strip():
        raise ValueError("text must be a non-empty string")
    if len(text.encode()) > MAX_TEXT_BYTES:
        raise ValueError(f"text must be at most {MAX_TEXT_BYTES} bytes")

    source = event.get("source", "auto")
    target = event.get("target", "en")
    if source != "auto" and not _is_language_code(source):
        raise ValueError("source must be 'auto' or a language code")
    if not _is_language_code(target):
        raise ValueError("target must be a language code")

    return text, source, target


def _is_language_code(value):
    return isinstance(value, str) and LANGUAGE_CODE.fullmatch(value) is not None
