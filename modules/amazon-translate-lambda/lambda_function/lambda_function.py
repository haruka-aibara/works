import boto3

translate = boto3.client("translate")


def lambda_handler(event, context):
    # SourceLanguageCode を auto にすると、言語の判定に Comprehend が呼ばれる。
    response = translate.translate_text(
        Text=event["text"],
        SourceLanguageCode=event.get("source", "auto"),
        TargetLanguageCode=event.get("target", "en"),
    )
    return {
        "source": response["SourceLanguageCode"],
        "target": response["TargetLanguageCode"],
        "text": response["TranslatedText"],
    }
