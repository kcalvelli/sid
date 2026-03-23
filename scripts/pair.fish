#!/usr/bin/env fish
# ZeroClaw pairing helper
# Usage:
#   pair.fish              — print numeric code (for dashboard)
#   pair.fish --token      — print bearer token (for API calls)
#   pair.fish --token mini — remote host

set -l host "127.0.0.1:18789"
set -l mode "code"

for arg in $argv
    switch $arg
        case --token -t
            set mode token
        case '*'
            set host $arg
    end
end

if test $mode = code
    curl -s -X POST http://$host/admin/paircode/new | jq -r '.pairing_code'
else
    set -l code (curl -s -X POST http://$host/admin/paircode/new | jq -r '.pairing_code')
    curl -s -X POST http://$host/api/pair \
        -H "Content-Type: application/json" \
        -d "{\"code\": \"$code\"}" | jq -r '.token'
end
