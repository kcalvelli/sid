#!/usr/bin/env bash
# Quick test: validate Anthropic OAuth token and model access from mini
# Usage: sudo bash scripts/test-anthropic-auth.sh

set -euo pipefail

TOKEN_FILE="/run/agenix/sid-anthropic-oauth-token"

if [ ! -f "$TOKEN_FILE" ]; then
    echo "ERROR: Token file not found at $TOKEN_FILE"
    exit 1
fi

TOKEN="$(cat "$TOKEN_FILE")"

if [ -z "$TOKEN" ]; then
    echo "ERROR: Token file is empty"
    exit 1
fi

echo "Token prefix: ${TOKEN:0:20}..."
echo "Token length: ${#TOKEN} chars"
echo ""
echo "Testing API with model claude-opus-4-6..."
echo ""

curl -s -w "\nHTTP status: %{http_code}\n" \
    https://api.anthropic.com/v1/messages \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d '{"model":"claude-opus-4-6","max_tokens":64,"messages":[{"role":"user","content":"Say hello in exactly three words."}]}'

echo ""
