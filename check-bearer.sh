#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$PROJECT_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
fi

MCPO_API_KEY="${MCPO_API_KEY:-}"
MCPO_HOST="${MCPO_HOST:-127.0.0.1}"
MCPO_PORT="${MCPO_PORT:-8000}"
BASE_URL="${MCPO_BASE_URL:-http://${MCPO_HOST}:${MCPO_PORT}}"

fail() {
    echo "[ERROR] $*" >&2
    exit 1
}

[[ -n "$MCPO_API_KEY" ]] || fail "MCPO_API_KEY is empty. Configure $ENV_FILE"
command -v curl >/dev/null 2>&1 || fail "curl is required."
command -v python3 >/dev/null 2>&1 || fail "python3 is required."

request_status() {
    curl --silent --show-error --output /dev/null --write-out '%{http_code}' "$@"
}

assert_rejected() {
    local description="$1"
    local status="$2"

    case "$status" in
        401|403) echo "[OK] $description rejected (HTTP $status)." ;;
        *) fail "$description was not rejected (HTTP $status); bearer authentication is not active." ;;
    esac
}

assert_accepted() {
    local status="$1"

    case "$status" in
        401|403) fail "Configured bearer token was rejected (HTTP $status)." ;;
        000) fail "Could not connect to $BASE_URL." ;;
        *) echo "[OK] Configured bearer token accepted (HTTP $status)." ;;
    esac
}

echo "[INFO] Reading the OpenAPI schema with the configured token."
schema="$(curl --silent --show-error --fail \
    -H "Authorization: Bearer $MCPO_API_KEY" \
    "$BASE_URL/openapi.json")" || fail "Could not read $BASE_URL/openapi.json with the configured token."

tool_path="$(python3 -c '
import json, sys
paths = json.load(sys.stdin).get("paths", {})
print(next((path for path, operations in paths.items() if "post" in operations), ""))
' <<<"$schema")"
[[ -n "$tool_path" ]] || fail "The OpenAPI schema does not contain a POST tool endpoint."

tool_url="${BASE_URL%/}${tool_path}"
echo "[INFO] Checking bearer authentication on tool endpoint $tool_path"

# An empty body may produce 400/422 for an authenticated request. That is fine:
# it proves authentication passed and request validation handled the request.
without_token="$(request_status -X POST -H 'Content-Type: application/json' -d '{}' "$tool_url")"
wrong_token="$(request_status -X POST -H 'Content-Type: application/json' -d '{}' \
    -H 'Authorization: Bearer deliberately-wrong-token' "$tool_url")"
valid_token="$(request_status -X POST -H 'Content-Type: application/json' -d '{}' \
    -H "Authorization: Bearer $MCPO_API_KEY" "$tool_url")"

assert_rejected "Request without a token" "$without_token"
assert_rejected "Request with an invalid token" "$wrong_token"
assert_accepted "$valid_token"

echo "[OK] Bearer authentication is active."
