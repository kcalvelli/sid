"""Sid Dashboard — lightweight web UI for ZeroClaw gateway."""

import asyncio
import json
import os
import sys
from http import HTTPStatus
from pathlib import Path
from urllib.parse import urlparse

import httpx

STATIC_DIR = Path(__file__).parent / "static"
GATEWAY_URL = os.environ.get("ZEROCLAW_GATEWAY_URL", "http://127.0.0.1:18789")
GATEWAY_TOKEN = os.environ.get("ZEROCLAW_GATEWAY_TOKEN", "")
DASHBOARD_PORT = int(os.environ.get("SID_DASHBOARD_PORT", "8080"))
DASHBOARD_HOST = os.environ.get("SID_DASHBOARD_HOST", "0.0.0.0")

MIME_TYPES = {
    ".html": "text/html; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".js": "application/javascript; charset=utf-8",
    ".json": "application/json",
    ".png": "image/png",
    ".svg": "image/svg+xml",
    ".ico": "image/x-icon",
}


async def handle_request(reader, writer):
    """Handle a single HTTP request."""
    try:
        request_line = await asyncio.wait_for(reader.readline(), timeout=30)
        if not request_line:
            writer.close()
            return

        request_str = request_line.decode("utf-8", errors="replace").strip()
        parts = request_str.split(" ")
        if len(parts) < 2:
            writer.close()
            return

        method = parts[0]
        path = parts[1]

        # Read headers
        headers = {}
        content_length = 0
        while True:
            line = await asyncio.wait_for(reader.readline(), timeout=10)
            line_str = line.decode("utf-8", errors="replace").strip()
            if not line_str:
                break
            if ":" in line_str:
                key, value = line_str.split(":", 1)
                headers[key.strip().lower()] = value.strip()
                if key.strip().lower() == "content-length":
                    content_length = int(value.strip())

        # Read body if present
        body = b""
        if content_length > 0:
            body = await asyncio.wait_for(reader.readexactly(content_length), timeout=30)

        # Route request
        if path.startswith("/api/"):
            await proxy_to_gateway(writer, method, path, headers, body)
        elif path.startswith("/webhook"):
            await proxy_to_gateway(writer, method, path, headers, body)
        else:
            await serve_static(writer, path)

    except (asyncio.TimeoutError, ConnectionError, asyncio.IncompleteReadError):
        pass
    except Exception as e:
        try:
            send_response(writer, 500, "text/plain", f"Internal error: {e}".encode())
        except Exception:
            pass
    finally:
        try:
            writer.close()
            await writer.wait_closed()
        except Exception:
            pass


async def proxy_to_gateway(writer, method, path, headers, body):
    """Proxy request to ZeroClaw gateway."""
    gateway_headers = {"authorization": f"Bearer {GATEWAY_TOKEN}"}
    if "content-type" in headers:
        gateway_headers["content-type"] = headers["content-type"]

    url = f"{GATEWAY_URL}{path}"

    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.request(
            method=method,
            url=url,
            headers=gateway_headers,
            content=body if body else None,
        )

    send_response(writer, response.status_code,
                  response.headers.get("content-type", "application/json"),
                  response.content)


async def serve_static(writer, path):
    """Serve static files."""
    if path == "/" or path == "":
        path = "/index.html"

    # Sanitize path
    clean = Path(path.lstrip("/"))
    if ".." in clean.parts:
        send_response(writer, 403, "text/plain", b"Forbidden")
        return

    file_path = STATIC_DIR / clean
    if not file_path.is_file():
        # SPA fallback
        file_path = STATIC_DIR / "index.html"
        if not file_path.is_file():
            send_response(writer, 404, "text/plain", b"Not found")
            return

    content_type = MIME_TYPES.get(file_path.suffix, "application/octet-stream")
    content = file_path.read_bytes()
    send_response(writer, 200, content_type, content)


def send_response(writer, status_code, content_type, body):
    """Write HTTP response."""
    reason = HTTPStatus(status_code).phrase
    writer.write(f"HTTP/1.1 {status_code} {reason}\r\n".encode())
    writer.write(f"Content-Type: {content_type}\r\n".encode())
    writer.write(f"Content-Length: {len(body)}\r\n".encode())
    writer.write(b"Connection: close\r\n")
    writer.write(b"\r\n")
    writer.write(body)


async def run_server():
    """Start the dashboard server."""
    server = await asyncio.start_server(handle_request, DASHBOARD_HOST, DASHBOARD_PORT)
    print(f"Sid Dashboard running at http://{DASHBOARD_HOST}:{DASHBOARD_PORT}")
    print(f"Proxying to ZeroClaw gateway at {GATEWAY_URL}")
    async with server:
        await server.serve_forever()


def main():
    try:
        asyncio.run(run_server())
    except KeyboardInterrupt:
        print("\nShutting down.")
        sys.exit(0)
