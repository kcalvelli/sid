#!/usr/bin/env bash
# Test different models/API versions to isolate 400 error cause
set -euo pipefail

TOKEN_FILE="/run/agenix/sid-anthropic-oauth-token"
TOKEN="$(cat "$TOKEN_FILE")"

test_api() {
    local label="$1" model="$2" version="$3"
    echo "=== $label ==="
    echo "  model=$model  anthropic-version=$version"
    curl -s -w "\n  HTTP status: %{http_code}\n" \
        https://api.anthropic.com/v1/messages \
        -H "Authorization: Bearer $TOKEN" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "anthropic-version: $version" \
        -H "content-type: application/json" \
        -d "{\"model\":\"$model\",\"max_tokens\":64,\"messages\":[{\"role\":\"user\",\"content\":\"Say hello\"}]}"
    echo ""
}

# Known-good older model with old API version
test_api "Test 1: Older Sonnet (known-good model ID)" \
    "claude-3-5-sonnet-20241022" "2023-06-01"

# Sonnet 4 with old API version
test_api "Test 2: Sonnet 4 (latest stable)" \
    "claude-sonnet-4-5-20250514" "2023-06-01"

# Opus 4.6 with old API version (current config)
test_api "Test 3: Opus 4.6 with 2023-06-01 (current config)" \
    "claude-opus-4-6" "2023-06-01"

# Opus 4.6 with 2024-10-22 API version
test_api "Test 4: Opus 4.6 with 2024-10-22" \
    "claude-opus-4-6" "2024-10-22"
