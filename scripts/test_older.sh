#!/usr/bin/env bash
# Test different models/API versions to isolate 400 error cause
set -euo pipefail

TOKEN_FILE="/run/agenix/sid-anthropic-oauth-token"
TOKEN="$(cat "$TOKEN_FILE")"

echo "=== Test 1: Older model (claude-sonnet-4-5-20241022) ==="
curl -s -w "\nHTTP status: %{http_code}\n" \
    https://api.anthropic.com/v1/messages \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d '{"model":"claude-sonnet-4-5-20241022","max_tokens":64,"messages":[{"role":"user","content":"Say hello"}]}'

echo ""
echo "=== Test 2: claude-opus-4-6 with newer API version ==="
curl -s -w "\nHTTP status: %{http_code}\n" \
    https://api.anthropic.com/v1/messages \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "anthropic-version: 2025-01-01" \
    -H "content-type: application/json" \
    -d '{"model":"claude-opus-4-6","max_tokens":64,"messages":[{"role":"user","content":"Say hello"}]}'

echo ""
