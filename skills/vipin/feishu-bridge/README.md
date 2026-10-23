# feishu-bridge

A routing note for agents doing Feishu/Lark work: use the official `lark-cli` API
commands for docs, wiki, Drive, Base, Sheets and messages, and fall back to browser
automation only for web-only pages and forms. It also covers login, bot-vs-user identity
and when to dry-run.

It has no code of its own. It expects:

- `lark-cli` from [larksuite/cli](https://github.com/larksuite/cli) (I use v1.0.32);
- the official `lark-*` skills from the same repo. `scripts/fetch-third-party.sh lark-cli-skills`
  downloads the pinned version (see [THIRD_PARTY_SKILLS.md](../../../THIRD_PARTY_SKILLS.md));
- for web-only pages and forms only, a browser-automation skill. `SKILL.md` names
  `chrome-automation` from [anbeime/skill](https://github.com/anbeime/skill), which I use
  (`scripts/fetch-third-party.sh anbeime-skill`, then link
  `third_party/anbeime-skill/skills/chrome-automation/chrome-automation`). That repo has
  no license file, so it is not copied here. Any skill or tool that can drive a
  logged-in browser works instead; without one, the API routes still work.

Put `lark-cli` on `PATH`, or set `LARK_CLI` to the full path of the binary.

## Example

```powershell
$LARK_CLI = "lark-cli"
& $LARK_CLI auth status
& $LARK_CLI docs +fetch --api-version v2 --help
```

Then ask the agent something like "summarize this Feishu doc: <link>" and it routes to
`lark-doc`.
