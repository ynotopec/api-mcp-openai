#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

VENV_ROOT="${VENV_ROOT:-$HOME/venv}"
VENV_DIR="${VENV_ROOT}/${PROJECT_NAME}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12}"

export PATH="$HOME/.local/bin:$PATH"

echo "[INFO] Project     : $PROJECT_NAME"
echo "[INFO] Project dir : $PROJECT_DIR"
echo "[INFO] Venv        : $VENV_DIR"

if ! command -v uv >/dev/null 2>&1; then
    echo "[INFO] Installing uv..."
    if command -v curl >/dev/null 2>&1; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://astral.sh/uv/install.sh | sh
    else
        echo "[ERROR] curl or wget is required." >&2
        exit 1
    fi
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "[INFO] uv: $(uv --version)"

uv python install "$PYTHON_VERSION"

mkdir -p "$VENV_ROOT"

if [[ ! -x "$VENV_DIR/bin/python" ]]; then
    echo "[INFO] Creating venv: $VENV_DIR"
    uv venv --python "$PYTHON_VERSION" "$VENV_DIR"
else
    echo "[INFO] Existing venv reused: $VENV_DIR"
fi

echo "[INFO] Installing/upgrading dependencies..."
uv pip install \
    --python "$VENV_DIR/bin/python" \
    --upgrade \
    mcpo \
    "mcp<2" \
    mcp-server-time

if [[ ! -f "$PROJECT_DIR/.env" ]]; then
    cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
    echo "[INFO] Created $PROJECT_DIR/.env"
    echo "[WARNING] Change MCPO_API_KEY before exposing the service."
fi

chmod +x "$PROJECT_DIR/install.sh" "$PROJECT_DIR/run.sh" "$PROJECT_DIR/check-bearer.sh"

echo
echo "[OK] Installation complete."
echo "Run:"
echo "  source \"$PROJECT_DIR/run.sh\""
echo "or:"
echo "  source \"$PROJECT_DIR/run.sh\" 0.0.0.0 8000"
