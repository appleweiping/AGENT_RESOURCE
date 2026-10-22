# Local Feishu/Lark Tooling

- Official source: https://github.com/larksuite/cli
- Version I use: release v1.0.32
- Binary: set `$env:LARK_CLI` to its full path, or put `lark-cli` on `PATH`.
- Official `lark-*` skills: `scripts/fetch-third-party.sh lark-cli-skills` at the repo
  root downloads the version pinned in `THIRD_PARTY_SKILLS.md`. Link the ones you need,
  plus `feishu-bridge`, into the agent's skills folder.

I install the release zip instead of going through `npm`/`npx`, because the machine I
use it on has Node without npm on `PATH`. Check the zip against the checksum published
with the release; for the v1.0.32 Windows zip I installed it was:

`8f5fef30ec0485279e1a8b7e949f8ee42df9ada006c7617b0e4fc54177179b9d`
