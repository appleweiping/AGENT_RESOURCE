# DeepSeek MCP for Codex

This is a small local MCP server that lets Codex call DeepSeek as an optional tool without changing Codex's main model.

## Tool

- `deepseek_chat`: sends a bounded prompt to DeepSeek and returns text.

Good uses:

- summarization
- rewriting
- brainstorming
- classification
- cheap batch drafting

Not recommended:

- autonomous file editing
- security-sensitive reasoning
- tasks requiring Codex tool access

## Environment

The server reads:

- `DEEPSEEK_API_KEY` - required
- `DEEPSEEK_MODEL` - optional, defaults to `deepseek-chat`
- `DEEPSEEK_BASE_URL` - optional, defaults to `https://api.deepseek.com`

Do not put the API key in `config.toml`.

There is also a Python version (`deepseek_mcp.py`, standard library only) with the same tool.

## Test

Needs Node.js 18+ (built-in `fetch`) and `DEEPSEEK_API_KEY` in the environment:

```powershell
node .\deepseek_mcp.mjs --prompt "Say hello in one sentence."
```

## Codex Config

Add this to `~/.codex/config.toml`, with the absolute path to this folder:

```toml
[features]
rmcp_client = true

[mcp_servers.deepseek]
command = "node"
args = ["C:\\path\\to\\AGENT_RESOURCE\\skills\\standalone\\deepseek-mcp\\deepseek_mcp.mjs"]
env_vars = ["DEEPSEEK_API_KEY", "DEEPSEEK_MODEL", "DEEPSEEK_BASE_URL"]
startup_timeout_sec = 10
tool_timeout_sec = 120
```

Restart Codex after editing the config.
