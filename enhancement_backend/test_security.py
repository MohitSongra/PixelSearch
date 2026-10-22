"""Adversarial requests use synthetic data and never contact the provider."""
import asyncio
import hashlib
import json

import httpx
import pytest

import app as service
import starlette.formparsers
from test_app import client  # noqa: F401 - shared pytest fixture


async def request_asgi(body=b"", *, token="fixture-token", length=None, receive=None):
    messages = []
    reads = 0
    headers = [(b"content-type", b"application/json")]
    if token is not None:
        headers.append((b"authorization", f"Bearer {token}".encode()))
    if length is not None:
        headers.append((b"content-length", str(length).encode()))

    async def read():
        nonlocal reads
        reads += 1
        if receive is not None:
            return await receive()
        return {"type": "http.request", "body": body, "more_body": False}

    async def send(message):
        messages.append(message)

    scope = {"type": "http", "asgi": {"version": "3.0"}, "http_version": "1.1",
             "method": "POST", "scheme": "https", "path": "/rewrite",
             "raw_path": b"/rewrite", "query_string": b"", "headers": headers,
             "server": ("test", 443), "client": ("127.0.0.1", 1234)}
    await service.app(scope, read, send)
    start = next(m for m in messages if m["type"] == "http.response.start")
    return start, reads


@pytest.fixture
def raw_auth(monkeypatch):
    monkeypatch.setenv("PIXELSEARCH_TOKEN_HASHES", hashlib.sha256(b"fixture-token").hexdigest())
    service._requests.clear()


def test_authentication_happens_before_reading_invalid_body(raw_auth):
    start, reads = asyncio.run(request_asgi(b"not-json", token="wrong", length=8))
    assert start["status"] == 401
    assert reads == 0
    assert (b"cache-control", b"no-store") in start["headers"]


def test_received_bytes_not_declared_length_enforce_upload_limit(raw_auth):
    body = json.dumps({"text": "x" * (6 * 1024 * 1024), "style": "concise"}).encode()
    start, _ = asyncio.run(request_asgi(body, length=1))
    assert start["status"] == 413


def test_authentication_precedes_multipart_parser(client, monkeypatch):
    async def forbidden(*args, **kwargs):
        pytest.fail("Unauthenticated multipart must never be parsed or spooled")
    monkeypatch.setattr(starlette.formparsers.MultiPartParser, "parse", forbidden)
    response = client.post("/caption", headers={"Authorization": "Bearer wrong"},
                           files={"file": ("synthetic.jpg", b"synthetic-image")})
    assert response.status_code == 401


def test_body_limit_accumulates_across_chunks(raw_auth):
    async def scenario():
        chunks = iter([b" " * (4 * 1024 * 1024), b" " * (3 * 1024 * 1024)])
        async def read():
            return {"type": "http.request", "body": next(chunks), "more_body": True}
        start, reads = await request_asgi(length=1, receive=read)
        assert start["status"] == 413
        assert reads == 2
    asyncio.run(scenario())


def test_validation_errors_do_not_echo_submitted_content(client):
    response = client.post("/rewrite", json={"text": "private fixture", "style": "unsupported"})
    assert response.status_code == 422
    assert "private fixture" not in response.text
    assert "unsupported" not in response.text


@pytest.mark.parametrize("length,status", [(None, 411), ("bad", 400), (-1, 413), (7 * 1024 * 1024, 413)])
def test_header_rejections_are_not_cached_and_do_not_read_body(raw_auth, length, status):
    start, reads = asyncio.run(request_asgi(length=length))
    assert start["status"] == status
    assert reads == 0
    assert (b"cache-control", b"no-store") in start["headers"]


@pytest.mark.parametrize("result", [None, [], {"choices": [None]}, {"choices": [[]]},
                                    {"choices": [{"finish_reason": "stop", "message": None}]}])
def test_malformed_completion_envelopes_fail_cleanly(client, monkeypatch, result):
    async def fake(*args, **kwargs):
        return result
    monkeypatch.setattr(service, "groq", fake)
    assert client.post("/rewrite", json={"text": "tree", "style": "concise"}).status_code == 502


@pytest.mark.parametrize("result", [None, [], "wrong", 1])
def test_malformed_transcription_envelopes_fail_cleanly(client, monkeypatch, result):
    async def fake(*args, **kwargs):
        return result
    monkeypatch.setattr(service, "groq", fake)
    assert client.post("/transcribe", files={"file": ("speech.m4a", b"fixture")}).status_code == 502


def test_busy_requests_are_rejected_before_body_read_and_slots_recover(raw_auth, monkeypatch):
    async def scenario():
        entered = asyncio.Event()
        finish = asyncio.Event()
        active = 0
        async def blocked_receive():
            nonlocal active
            active += 1
            if active == 2:
                entered.set()
            await finish.wait()
            return {"type": "http.request", "body": b"{}", "more_body": False}
        tasks = [asyncio.create_task(request_asgi(length=2, receive=blocked_receive)) for _ in range(2)]
        try:
            await asyncio.wait_for(entered.wait(), 1)
            start, reads = await request_asgi(b"{}", length=2)
            assert start["status"] == 429
            assert reads == 0
            assert (b"retry-after", b"5") in start["headers"]
        finally:
            finish.set()
            await asyncio.gather(*tasks)
        start, _ = await request_asgi(b"{}", length=2)
        assert start["status"] == 422
    asyncio.run(scenario())


def test_slow_upload_times_out_and_releases_capacity(raw_auth, monkeypatch):
    monkeypatch.setattr(service, "REQUEST_TIMEOUT", 0.02)
    async def scenario():
        async def stalled():
            await asyncio.sleep(1)
            return {"type": "http.request", "body": b"{}", "more_body": False}
        start, _ = await request_asgi(length=2, receive=stalled)
        assert start["status"] == 408
        start, _ = await request_asgi(b"{}", length=2)
        assert start["status"] == 422
    asyncio.run(scenario())


def test_cancelled_requests_release_capacity(raw_auth):
    async def scenario():
        entered = asyncio.Event()
        async def stalled():
            entered.set()
            await asyncio.Event().wait()
        for _ in range(3):
            entered.clear()
            task = asyncio.create_task(request_asgi(length=2, receive=stalled))
            await asyncio.wait_for(entered.wait(), 1)
            task.cancel()
            with pytest.raises(asyncio.CancelledError):
                await task
        start, _ = await request_asgi(b"{}", length=2)
        assert start["status"] == 422
    asyncio.run(scenario())


def provider_transport(monkeypatch, response):
    original = httpx.AsyncClient
    monkeypatch.setenv("GROQ_API_KEY", "synthetic-provider-key")
    monkeypatch.setenv("GROQ_ZDR_CONFIRMED", "true")
    monkeypatch.setattr(service.httpx, "AsyncClient", lambda **kwargs: original(
        **kwargs, transport=httpx.MockTransport(lambda request: response)))


def test_oversized_provider_body_is_rejected(client, monkeypatch):
    provider_transport(monkeypatch, httpx.Response(200, content=b" " * (65536 + 1) + b"{}"))
    assert client.post("/rewrite", json={"text": "tree", "style": "concise"}).status_code == 502


def test_valid_provider_stream_still_succeeds(client, monkeypatch):
    provider_transport(monkeypatch, httpx.Response(200, json={"choices": [{
        "finish_reason": "stop", "message": {"content": '{"text":"A tree."}'}}]}))
    response = client.post("/rewrite", json={"text": "tree", "style": "concise"})
    assert response.status_code == 200
    assert response.json()["text"] == "A tree."


def test_provider_stream_has_total_deadline(client, monkeypatch):
    monkeypatch.setattr(service, "PROVIDER_TIMEOUT", 0.02)
    class StalledBody(httpx.AsyncByteStream):
        async def __aiter__(self):
            yield b" "
            await asyncio.sleep(1)
            yield b"{}"
    provider_transport(monkeypatch, httpx.Response(200, stream=StalledBody()))
    assert client.post("/rewrite", json={"text": "tree", "style": "concise"}).status_code == 503
