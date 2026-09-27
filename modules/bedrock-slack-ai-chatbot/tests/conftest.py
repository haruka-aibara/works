"""
tests/conftest.py
Shared fixtures for loading the two Lambda handlers under test.

Both Lambda directories contain a module literally named ``lambda_function`` (and a
duplicated ``boto3_utils``), so they cannot both be imported by name in one pytest
session. Each handler is therefore loaded from its file path under a unique module
name, with its own directory placed on ``sys.path`` so the sibling ``boto3_utils``
import resolves against the right copy.

Both handlers also build their AWS/Slack clients at import time, so the fakes are in
place *before* the module body runs. AWS is emulated by moto: SQS and DynamoDB are
real boto3 clients talking to an in-memory backend, so tests assert on what actually
landed in the queue or table rather than on call arguments. Bedrock Runtime is the
exception — moto does not emulate the Converse API — so its client is swapped for a
mock after loading. Slack is always mocked. Each test gets a freshly loaded module and
a fresh moto backend, which keeps state isolated between tests.
"""

import importlib.util
import json
import sys
from collections.abc import Iterator
from pathlib import Path
from types import ModuleType
from typing import Any
from unittest import mock

import boto3
import pytest
from moto import mock_aws

# Importing the handlers must not litter the Lambda source directories with
# __pycache__ entries: those directories are zipped by `data.archive_file`, and stray
# files there change `source_code_hash` and cause spurious redeploys.
sys.dont_write_bytecode = True

REPO_ROOT = Path(__file__).resolve().parent.parent
FRONTEND_DIR = REPO_ROOT / "lambda_function_slack_ai_chatbot"
BACKEND_DIR = REPO_ROOT / "lambda_function_bedrock_backend"

AWS_REGION = "ap-northeast-1"
QUEUE_NAME = "test-queue"
TABLE_NAME = "test-idempotency"
BOT_TOKEN_PARAMETER = "/test/slack-bot-token"
SIGNING_SECRET_PARAMETER = "/test/slack-signing-secret"
BOT_TOKEN = "xoxb-test-token"
SIGNING_SECRET = "test-signing-secret"

FRONTEND_ENV = {
    "SLACK_BOT_TOKEN_PARAMETER": BOT_TOKEN_PARAMETER,
    "SLACK_SIGNING_SECRET_PARAMETER": SIGNING_SECRET_PARAMETER,
    # The URL moto hands back for QUEUE_NAME in its default account.
    "BACKEND_QUEUE_URL": f"https://sqs.{AWS_REGION}.amazonaws.com/123456789012/{QUEUE_NAME}",
}

BACKEND_ENV = {
    "SLACK_BOT_TOKEN_PARAMETER": BOT_TOKEN_PARAMETER,
    "BEDROCK_MODEL_ID": "arn:aws:bedrock:ap-northeast-1:123456789012:inference-profile/test",
    "BEDROCK_MAX_TOKENS": "1000",
    "DYNAMODB_TABLE_NAME": TABLE_NAME,
}


def load_lambda_module(module_name: str, directory: Path) -> ModuleType:
    """Execute ``<directory>/lambda_function.py`` as a module named ``module_name``."""
    sys.path.insert(0, str(directory))
    sys.modules.pop("boto3_utils", None)
    try:
        spec = importlib.util.spec_from_file_location(module_name, directory / "lambda_function.py")
        if spec is None or spec.loader is None:  # pragma: no cover - defensive
            raise ImportError(f"cannot load lambda_function.py from {directory}")
        module = importlib.util.module_from_spec(spec)
        sys.modules[module_name] = module
        spec.loader.exec_module(module)
        return module
    finally:
        sys.path.remove(str(directory))
        sys.modules.pop("boto3_utils", None)
        sys.modules.pop(module_name, None)


def sqs_event(body: dict[str, Any]) -> dict[str, Any]:
    """Build the SQS-triggered Lambda event envelope around a message body."""
    return {"Records": [{"body": json.dumps(body)}]}


def bedrock_response(text: str) -> dict[str, Any]:
    """Build a ``converse`` response carrying ``text`` as its single content block."""
    return {
        "output": {"message": {"role": "assistant", "content": [{"text": text}]}},
        "usage": {"inputTokens": 10, "outputTokens": 20},
        "stopReason": "end_turn",
    }


@pytest.fixture(autouse=True)
def aws_credentials(monkeypatch: pytest.MonkeyPatch) -> None:
    """Point boto3 at fake credentials so no test can ever reach a real AWS account."""
    for key in ("AWS_PROFILE", "AWS_SESSION_TOKEN", "AWS_SECURITY_TOKEN"):
        monkeypatch.delenv(key, raising=False)
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_DEFAULT_REGION", AWS_REGION)


@pytest.fixture
def aws() -> Iterator[None]:
    """An in-memory AWS backend, torn down after the test.

    The Slack secrets are put in SSM up front, since both handlers read them at import.
    """
    with mock_aws():
        ssm = boto3.client("ssm")
        ssm.put_parameter(Name=BOT_TOKEN_PARAMETER, Value=BOT_TOKEN, Type="SecureString")
        ssm.put_parameter(Name=SIGNING_SECRET_PARAMETER, Value=SIGNING_SECRET, Type="SecureString")
        yield


@pytest.fixture
def backend_queue_url(aws: None) -> str:
    """Create the SQS queue the frontend enqueues onto."""
    return boto3.client("sqs").create_queue(QueueName=QUEUE_NAME)["QueueUrl"]


@pytest.fixture
def idempotency_table(aws: None) -> Any:
    """Create the idempotency table with the same key schema as main_dynamodb.tf."""
    return boto3.resource("dynamodb").create_table(
        TableName=TABLE_NAME,
        KeySchema=[{"AttributeName": "event_id", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "event_id", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )


@pytest.fixture
def frontend_env(monkeypatch: pytest.MonkeyPatch) -> None:
    """Set the environment variables the Slack frontend Lambda reads at import time."""
    for key, value in FRONTEND_ENV.items():
        monkeypatch.setenv(key, value)


@pytest.fixture
def backend_env(monkeypatch: pytest.MonkeyPatch) -> None:
    """Set the environment variables the Bedrock backend Lambda reads at import time."""
    for key, value in BACKEND_ENV.items():
        monkeypatch.setenv(key, value)


def load_frontend(module_name: str = "frontend_lambda_function") -> ModuleType:
    """Load the Slack frontend handler with the Slack Bolt app mocked out.

    ``slack_bolt.App`` is replaced so no token verification request is made at import,
    and its ``event`` decorator is made a pass-through so the registered handler stays
    a plain function the tests can call directly. SQS is whatever boto3 reaches, which
    under the ``aws`` fixture is moto.
    """
    with mock.patch("slack_bolt.App") as app_cls:
        app_cls.return_value.event.return_value = lambda handler: handler
        return load_lambda_module(module_name, FRONTEND_DIR)


def load_backend(module_name: str = "backend_lambda_function") -> ModuleType:
    """Load the Bedrock backend handler with Slack and Bedrock Runtime mocked out.

    DynamoDB is whatever boto3 reaches, which under the ``aws`` fixture is moto.
    """
    with mock.patch("slack_sdk.WebClient"):
        module = load_lambda_module(module_name, BACKEND_DIR)
    module.bedrock_runtime = mock.MagicMock()
    return module


@pytest.fixture
def frontend(frontend_env: None, backend_queue_url: str) -> ModuleType:
    """The Slack frontend handler, enqueueing onto a moto SQS queue."""
    return load_frontend()


@pytest.fixture
def backend(backend_env: None, idempotency_table: Any) -> ModuleType:
    """The Bedrock backend handler, claiming events in a moto DynamoDB table."""
    return load_backend()
