#!/usr/bin/env bash
# Quick test: validate Anthropic token and model access
# Usage: ./test-anthropic-auth.sh [TOKEN]
#   TOKEN  - pass directly, or omit to read from /run/agenix/sid-anthropic-oauth-token

set -euo pipefail

if [ -n "${1:-}" ]; then
    TOKEN="$1"
else
    TOKEN_FILE="/run/agenix/sid-anthropic-oauth-token"
    if [ ! -f "$TOKEN_FILE" ]; then
        echo "ERROR: No token argument and $TOKEN_FILE not found"
        exit 1
    fi
    TOKEN="$(cat "$TOKEN_FILE")"
fi

if [ -z "$TOKEN" ]; then
    echo "ERROR: Token is empty"
    exit 1
fi

echo "Token prefix: ${TOKEN:0:20}..."
echo "Token length: ${#TOKEN} chars"

# Detect auth method from token prefix
if [[ "$TOKEN" == sk-ant-oat01-* ]] || [[ "$TOKEN" == ey* ]]; then
    echo "Auth mode: OAuth (Bearer + beta header)"
    AUTH_HEADER="Authorization: Bearer $TOKEN"
    BETA_HEADER="anthropic-beta: oauth-2025-04-20"
else
    echo "Auth mode: API key (x-api-key)"
    AUTH_HEADER="x-api-key: $TOKEN"
    BETA_HEADER=""
fi

test_model() {
    local model="$1"
    echo "=== $model ==="
    curl -s -w "\nHTTP status: %{http_code}\n" \
        https://api.anthropic.com/v1/messages \
        -H "$AUTH_HEADER" \
        ${BETA_HEADER:+-H "$BETA_HEADER"} \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "{\"model\":\"$model\",\"max_tokens\":64,\"messages\":[{\"role\":\"user\",\"content\":\"Say hello\"}]}"
    echo ""
}

echo ""
test_model "claude-haiku-4-5-20251001"
test_model "claude-sonnet-4-6"
test_model "claude-sonnet-4-6-20250514"
test_model "claude-opus-4-6"
test_model "claude-opus-4-6-20250514"
