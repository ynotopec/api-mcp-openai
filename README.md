# OpenWebUI MCP

Minimal MCP -> OpenAPI gateway for OpenWebUI using MCPO.

The initial MCP server is `mcp-server-time`, used only to validate the full
OpenWebUI -> MCPO -> MCP chain.

## Architecture

```text
OpenWebUI
    |
    | OpenAPI + Bearer token
    v
MCPO
    |
    | MCP stdio
    v
mcp-server-time
```

## Install

```bash
./install.sh
```

The virtual environment is automatically created at:

```text
~/venv/<project-directory-name>
```

Running `install.sh` again upgrades/reconciles the installation.

## Configure

Edit:

```bash
nano .env
```

Generate an API token, for example:

```bash
TOKEN="$(openssl rand -hex 32)"
sed -i "s/^MCPO_API_KEY=.*/MCPO_API_KEY=$TOKEN/" .env
```

## Start

Default:

```bash
source run.sh
```

Explicit listen address:

```bash
source run.sh 0.0.0.0 8000
```

Systemd-compatible execution:

```bash
./run.sh 0.0.0.0 8000
```

## Test MCPO

```bash
TOKEN="$(grep '^MCPO_API_KEY=' .env | cut -d= -f2-)"

curl -s \
  -H "Authorization: Bearer $TOKEN" \
  http://127.0.0.1:8000/openapi.json | jq '.paths | keys'
```

Expected tools:

```text
/convert_time
/get_current_time
```

Swagger UI:

```text
http://SERVER:8000/docs
```

## OpenWebUI

Add MCPO as an **OpenAPI Tool Server** in OpenWebUI.

Example:

```text
URL: http://SERVER:8000
API key / Bearer token: value of MCPO_API_KEY
```

Verify that the connection is reported as OK.

### Enable the tool for a chat

A connected Tool Server is not necessarily enabled in every conversation.

In a chat, open the tool selector and enable the server, for example:

```text
Mcp-Test
```

Then test with:

```text
Use get_current_time for Europe/Lisbon.
Do not use get_current_timestamp.
```

`get_current_timestamp` is an OpenWebUI built-in tool, so it is not a valid
proof that the external MCP server is being used.

### Enable the tool by default for a model

To avoid enabling the Tool Server manually in every new chat, attach it to the
model configuration.

In OpenWebUI:

```text
Admin Panel
  -> Models
  -> select/edit the model
  -> Model Params
  -> Tools
  -> Select Tool
  -> check the MCPO Tool Server (for example: Mcp-Test)
  -> Save
```

In the model editor, the selected server appears checked in the `Tools`
section.

New chats using that model will then have the tool enabled by default.

This setting is **model-specific**: a Tool Server can be globally available in
OpenWebUI without being attached by default to every model.

Once this works, replace the reference `mcp-server-time` command with the
Grist MCP command.
