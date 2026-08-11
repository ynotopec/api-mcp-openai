#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

VENV_ROOT="${VENV_ROOT:-$HOME/venv}"
VENV_DIR="${VENV_ROOT}/${PROJECT_NAME}"
ENV_FILE="${ENV_FILE:-$PROJECT_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
fi

IP="${1:-${MCPO_HOST:-127.0.0.1}}"
PORT="${2:-${MCPO_PORT:-8000}}"

MCPO_API_KEY="${MCPO_API_KEY:-}"
LOCAL_TIMEZONE="${LOCAL_TIMEZONE:-Europe/Lisbon}"

fail() {
    echo "[ERROR] $*" >&2
    return 1 2>/dev/null || exit 1
}

[[ -x "$VENV_DIR/bin/mcpo" ]] || fail "Run ./install.sh first."
[[ -n "$MCPO_API_KEY" ]] || fail "MCPO_API_KEY is empty. Configure $ENV_FILE"

CMD=(
    "$VENV_DIR/bin/mcpo"
    --host "$IP"
    --port "$PORT"
    --api-key "$MCPO_API_KEY"
    --
    "$VENV_DIR/bin/mcp-server-time"
    --local-timezone "$LOCAL_TIMEZONE"
)

echo "[INFO] Project : $PROJECT_NAME"
echo "[INFO] API     : http://${IP}:${PORT}"
echo "[INFO] OpenAPI : http://${IP}:${PORT}/openapi.json"
echo "[INFO] Swagger : http://${IP}:${PORT}/docs"
echo "[INFO] MCP     : mcp-server-time"
echo "[INFO] Auth    : Bearer token enabled (--api-key)"
echo

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    exec "${CMD[@]}"
else
    "${CMD[@]}"
fi
