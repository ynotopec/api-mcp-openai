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
PORT="${2:-${MCPO_PORT:-}}"

MCPO_API_KEY="${MCPO_API_KEY:-}"
LOCAL_TIMEZONE="${LOCAL_TIMEZONE:-Europe/Lisbon}"

fail() {
    echo "[ERROR] $*" >&2
    return 1 2>/dev/null || exit 1
}

[[ -x "$VENV_DIR/bin/mcpo" ]] || fail "Run ./install.sh first."
[[ -n "$MCPO_API_KEY" ]] || fail "MCPO_API_KEY is empty. Configure $ENV_FILE"

# With no CLI or environment override, ask the kernel for an available port.
# Supplying a port is recommended for long-running services, whose address must
# remain stable across restarts.
if [[ -z "$PORT" ]]; then
    PORT="$("$VENV_DIR/bin/python" - <<'PY'
import socket

with socket.socket() as sock:
    sock.bind(("", 0))
    print(sock.getsockname()[1])
PY
)"
fi

[[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT >= 1 && PORT <= 65535 )) \
    || fail "PORT must be an integer between 1 and 65535 (got: $PORT)."

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
