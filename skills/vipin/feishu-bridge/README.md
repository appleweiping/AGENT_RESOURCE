# feishu-bridge

A routing note for agents doing Feishu/Lark work: use the official `lark-cli` API
commands for docs, wiki, Drive, Base, Sheets and messages, and fall back to browser
automation only for web-only pages and forms. It also covers login, bot-vs-user identity
and when to dry-run.

It has no code of its own. It expects:

- `lark-cli` from [larksuite/cli](https://github.com/larksuite/cli) (I use v1.0.32);
- the official `lark-*` skills from the same repo. `scripts/fetch-third-party.sh lark-cli-skills`
  downloads the pinned version (see [THIRD_PARTY_SKILLS.md](../../../THIRD_PARTY_SKILLS.md)).

Put `lark-cli` on `PATH`, or set `LARK_CLI` to the full path of the binary.

## Example

```powershell
$LARK_CLI = "lark-cli"
& $LARK_CLI auth status
& $LARK_CLI docs +fetch --api-version v2 --help
```

Then ask the agent something like "summarize this Feishu doc: <link>" and it routes to
`lark-doc`.
