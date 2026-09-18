import base64
import hashlib
import io
import json

import pytest
from fastapi.testclient import TestClient
from PIL import Image
import app as service


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("PIXELSEARCH_TOKEN_HASHES", hashlib.sha256(b"fixture-token").hexdigest())
    monkeypatch.delenv("GROQ_API_KEY", raising=False)
    monkeypatch.delenv("GROQ_ZDR_CONFIRMED", raising=False)
    service._requests.clear()
    with TestClient(service.app) as client:
        client.headers["Authorization"] = "Bearer fixture-token"
        yield client


def test_health_does_not_claim_live_model_verification(client):
    data = client.get("/health").json()
    assert not data["configured"] and not data["availability_verified"]
    assert data["max_completion_tokens"] == 512


def test_unauthorized_requests_do_not_reach_provider(client, monkeypatch):
    async def forbidden(*args, **kwargs):
        pytest.fail("No provider call should occur")
    monkeypatch.setattr(service, "completion", forbidden)
    response = client.post("/rewrite", headers={"Authorization": "Bearer wrong"},
                           json={"text": "a tree", "style": "concise"})
    assert response.status_code == 401


def test_unconfigured_provider_is_explicitly_unavailable(client):
    assert client.post("/rewrite", json={"text": "a tree", "style": "concise"}).status_code == 503


def test_rewrite_is_text_only_and_validated(client, monkeypatch):
    async def fake(system, content):
        data = json.loads(content)
        assert set(data) == {"text", "style"}
        return {"text": "A tree."}
    monkeypatch.setattr(service, "completion", fake)
    assert client.post("/rewrite", json={"text": "a tree", "style": "concise"}).json()["text"] == "A tree."
    assert client.post("/rewrite", json={"text": "a tree", "style": "concise", "image": "forbidden"}).status_code == 422


def test_invalid_model_response_does_not_become_success(client, monkeypatch):
    async def fake(*args):
        return {"caption": "wrong schema"}
    monkeypatch.setattr(service, "completion", fake)
    assert client.post("/rewrite", json={"text": "a tree", "style": "formal"}).status_code == 502


def test_caption_upload_is_decoded_sanitized_and_bounded(client, monkeypatch):
    source = Image.new("RGB", (1600, 900), "green")
    exif = source.getexif()
    exif[270] = "private metadata"
    data = io.BytesIO()
    source.save(data, "JPEG", exif=exif)
    async def fake(system, content):
        encoded = content[1]["image_url"]["url"].split(",", 1)[1]
        with Image.open(io.BytesIO(base64.b64decode(encoded))) as image:
            assert image.width <= 1280 and image.height <= 1280
            assert not image.getexif()
        return {"text": "A green field."}
    monkeypatch.setattr(service, "completion", fake)
    response = client.post("/caption", files={"file": ("private.jpg", data.getvalue(), "image/jpeg")})
    assert response.status_code == 200
    assert response.json()["caption"] == "A green field."


def test_bad_image_is_not_uploaded(client, monkeypatch):
    async def forbidden(*args):
        pytest.fail("Bad image must not reach provider")
    monkeypatch.setattr(service, "completion", forbidden)
    assert client.post("/caption", files={"file": ("bad.jpg", b"not an image")}).status_code == 400


def test_assistant_only_returns_valid_query_filters(client, monkeypatch):
    async def fake(system, content):
        submitted = json.loads(content)
        assert not {"photos", "embeddings", "filenames"} & submitted.keys()
        return {"query": "friends on a beach", "filters": {"from": "2025-01-01", "until": "2026-01-01"}, "clarification": None}
    monkeypatch.setattr(service, "completion", fake)
    response = client.post("/assistant", json={"message": "only last year", "query": "friends on a beach", "today": "2026-09-09"})
    assert response.status_code == 200
    assert response.json()["filters"]["until"] == "2026-01-01"


@pytest.mark.parametrize("filters", [{"sql": "anything"}, {"from": "2026-02-31"}, {"from": "2026-01-02", "until": "2026-01-01"}])
def test_assistant_rejects_unsupported_or_invalid_filters(client, monkeypatch, filters):
    async def fake(*args):
        return {"query": "scene", "filters": filters}
    monkeypatch.setattr(service, "completion", fake)
    assert client.post("/assistant", json={"message": "last year", "today": "2026-09-09"}).status_code == 502


def test_transcription_returns_validated_text(client, monkeypatch):
    async def fake(path, **kwargs):
        assert path == "audio/transcriptions"
        assert kwargs["data"]["model"] == service.SPEECH_MODEL
        assert kwargs["data"]["response_format"] == "json"
        assert kwargs["files"] == {"file": ("speech.m4a", b"fixture", "audio/mp4")}
        return {"text": "friends at the beach"}
    monkeypatch.setattr(service, "groq", fake)
    assert client.post("/transcribe", files={"file": ("speech.m4a", b"fixture")}).json()["text"] == "friends at the beach"


@pytest.mark.parametrize("text", [None, "", "   ", ["not a transcript"], "x" * 4001],
                         ids=["missing", "empty", "whitespace", "list", "too-long"])
def test_transcription_rejects_invalid_text(client, monkeypatch, text):
    calls = []
    async def fake(path, **kwargs):
        calls.append(path)
        return {"text": text}
    monkeypatch.setattr(service, "groq", fake)
    response = client.post("/transcribe", files={"file": ("speech.m4a", b"fixture")})
    assert response.status_code == 502
    assert calls == ["audio/transcriptions"]


@pytest.mark.parametrize("data", [b"", b"x" * (service.MAX_FILE + 1)], ids=["empty", "oversized"])
def test_transcription_bounds_upload_before_provider(client, monkeypatch, data):
    async def forbidden(*args, **kwargs):
        pytest.fail("Invalid upload must not reach the provider")
    monkeypatch.setattr(service, "groq", forbidden)
    assert client.post("/transcribe", files={"file": ("speech.m4a", data)}).status_code == 413


def test_transcription_requires_installation_token(client, monkeypatch):
    async def forbidden(*args, **kwargs):
        pytest.fail("Unauthenticated audio must not reach the provider")
    monkeypatch.setattr(service, "groq", forbidden)
    response = client.post("/transcribe", headers={"Authorization": "Bearer wrong"},
                           files={"file": ("speech.m4a", b"fixture")})
    assert response.status_code == 401


def test_installation_rate_limit(client, monkeypatch):
    async def fake(*args):
        return {"text": "Tree"}
    monkeypatch.setattr(service, "completion", fake)
    for _ in range(10):
        assert client.post("/rewrite", json={"text": "tree", "style": "concise"}).status_code == 200
    assert client.post("/rewrite", json={"text": "tree", "style": "concise"}).status_code == 429


def test_completion_pins_model_and_requests_final_json(client, monkeypatch):
    async def fake(path, **kwargs):
        assert path == "chat/completions"
        payload = kwargs["json"]
        assert payload["model"] == "qwen/qwen3.6-27b"
        assert payload["reasoning_effort"] == "none"
        assert payload["response_format"] == {"type": "json_object"}
        assert payload["max_completion_tokens"] == 512
        assert payload["max_completion_tokens"] < 1000
        return {"choices": [{"finish_reason": "stop", "message": {"content": '{"text":"A tree."}'}}]}
    monkeypatch.setattr(service, "groq", fake)
    response = client.post("/rewrite", json={"text": "a tree", "style": "concise"})
    assert response.status_code == 200
    assert response.json()["text"] == "A tree."


@pytest.mark.parametrize("finish_reason", ["length", "content_filter", None])
def test_incomplete_completion_is_rejected_without_retry(client, monkeypatch, finish_reason):
    calls = []
    async def fake(path, **kwargs):
        calls.append(path)
        return {"choices": [{"finish_reason": finish_reason,
                             "message": {"content": '{"text":"Plausible but incomplete."}'}}]}
    monkeypatch.setattr(service, "groq", fake)
    response = client.post("/rewrite", json={"text": "a tree", "style": "concise"})
    assert response.status_code == 502
    assert "text" not in response.json()
    assert calls == ["chat/completions"]


@pytest.mark.parametrize("endpoint,body", [
    ("/rewrite", {"text": "Two people sitting indoors.", "style": "concise"}),
    ("/assistant", {"message": "only last year", "query": "two people sitting together indoors",
                    "today": "2026-09-09"}),
])
def test_text_endpoints_fit_observed_output_budget(client, monkeypatch, endpoint, body):
    async def fake(path, **kwargs):
        assert kwargs["json"]["max_completion_tokens"] == 512
        content = {"text": "Two people sitting indoors."} if endpoint == "/rewrite" else {
            "query": body["query"], "filters": {"from": "2025-01-01", "until": "2026-01-01"}}
        return {"choices": [{"finish_reason": "stop", "message": {"content": json.dumps(content)}}]}
    monkeypatch.setattr(service, "groq", fake)
    assert client.post(endpoint, json=body).status_code == 200
