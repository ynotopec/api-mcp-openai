# OpenWebUI MCP API

A minimal, token-protected OpenAPI gateway for the popular MCP time server.
It uses `mcpo` (FastAPI/OpenAPI) and works on x86_64 and ARM64 Linux systems,
including NVIDIA H100 hosts and DGX Spark.

## Start

```bash
./install.sh                         # safe to rerun; installs/upgrades with uv
nano .env                            # replace MCPO_API_KEY=change-me
source run.sh                        # 127.0.0.1 and a free port
```

The virtual environment is stored outside the checkout at
`~/venv/<project-directory-name>`. To use a stable address:

```bash
source run.sh 0.0.0.0 8000
```

Open `http://SERVER:PORT/docs`, or add `http://SERVER:PORT` to OpenWebUI as an
**OpenAPI Tool Server** using the value of `MCPO_API_KEY` as its Bearer token.
Run `./check-bearer.sh` while using a fixed/configured port to verify auth.

For a user service, copy `openwebui-mcp.service.example` to
`~/.config/systemd/user/openwebui-mcp.service`, adjust its checkout path, then:

```bash
systemctl --user daemon-reload
systemctl --user enable --now openwebui-mcp
```

Important settings are documented in `.env.example`; commented values are
optional defaults. `PYTHON_VERSION`, `VENV_ROOT`, and `ENV_FILE` may also be
exported in the shell when needed.
