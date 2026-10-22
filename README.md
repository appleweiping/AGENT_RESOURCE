# AGENT_RESOURCE

My own agent skills for Claude Code and Codex, plus pointers to the third-party skills I use.

I use Claude Code and Codex on a Windows machine, and these are the skills I wrote for
my own chores: keeping my drives organized, drafting replies across chat apps and Gmail,
turning books into manga scripts, publishing videos, and making an agent understand a
project before it edits anything. Skills written by other people are not copied here any
more; [THIRD_PARTY_SKILLS.md](THIRD_PARTY_SKILLS.md) lists them with pinned upstream
commits, and a script downloads them for you.

```text
$ python tools/skill_catalog.py validate
Validated with 0 error(s) and 0 warning(s).
$ python tools/skill_catalog.py search "turn a novel into a manga script" --limit 1
 33  literature-to-manga                  skills/vipin/literature-to-manga/SKILL.md
     Convert selected prose, novel, biography, history, or text-archive works into manga adaptation packages. Use when ask...
$ scripts/fetch-third-party.sh superpowers gsap-skills
superpowers -> third_party/superpowers @ f2cbfbe
gsap-skills -> third_party/gsap-skills @ aed9cfd
```

## My skills

| Skill | What it does | Needs |
| --- | --- | --- |
| [workstation-maintenance](skills/vipin/workstation-maintenance) | Inventories my drives, plans file moves in approval batches, moves only approved batches, and can roll them back | Windows, PowerShell 5.1+ |
| [project-hardness](skills/vipin/project-hardness) | Has the agent map a project (architecture, constraints, blast radius) and turn a vague request into a task spec before editing | Python 3 and my [WEIPING_WIKI](https://github.com/appleweiping/WEIPING_WIKI) repo, which holds the engine |
| [literature-to-manga](skills/vipin/literature-to-manga) | Turns a novel or biography into a manga adaptation package: brief, bible, panel scripts, image prompts | Python 3.10+ |
| [communication-assistant](skills/vipin/communication-assistant) | Triage and draft replies for WeChat, WhatsApp, QQ, Feishu and email; keeps a local outbox and never sends on its own | Node.js 18+ |
| [email-assistant](skills/vipin/email-assistant) | Gmail API scripts to search, read, summarize and draft mail; sending needs an explicit confirm flag | Node.js 18+, a Google Cloud OAuth client |
| [feishu-bridge](skills/vipin/feishu-bridge) | Routes Feishu/Lark tasks to `lark-cli` and the official `lark-*` skills | `lark-cli` and the [Lark skills](THIRD_PARTY_SKILLS.md) |
| [wechat-video-channel-publish](skills/vipin/wechat-video-channel-publish) | Playwright CLI that logs into WeChat Channels (视频号) and uploads, schedules or drafts a video | Node.js 20+ |
| [lidang-perspective](skills/standalone/lidang-perspective) | Persona skill built from Li Dang's public writing, for career and tech-path questions (in Chinese) | nothing |
| [deepseek-mcp](skills/standalone/deepseek-mcp) | Tiny MCP server that lets Codex call DeepSeek as a side tool | Node.js 18+ or Python 3, a DeepSeek API key |

Each folder has a README with one usage example. [SKILL-INDEX.md](SKILL-INDEX.md) has
the "use this when..." line for each skill, which is what I point my agents at.

Nothing here hard-codes my own folders. Machine-specific settings come from a
git-ignored config file (`workstation-maintenance/config.json`, copied from
`config.example.json`) or from environment variables that each skill's README names
(`EMAIL_ASSISTANT_AUTH_DIR`, `COMMUNICATION_ASSISTANT_HOME`, `LARK_CLI`,
`LITERATURE_BOOKS_DIR`).

## Install a skill

A skill is just a folder with a `SKILL.md`. Clone the repo and link the folder into your
agent's skills directory (`~/.claude/skills/` for Claude Code, `~/.codex/skills/` for Codex):

```powershell
git clone https://github.com/appleweiping/AGENT_RESOURCE.git
New-Item -ItemType Junction -Path "$HOME\.claude\skills\literature-to-manga" `
  -Target "$PWD\AGENT_RESOURCE\skills\vipin\literature-to-manga"
```

```bash
git clone https://github.com/appleweiping/AGENT_RESOURCE.git
ln -s "$PWD/AGENT_RESOURCE/skills/vipin/literature-to-manga" ~/.claude/skills/literature-to-manga
```

Then start a new session and ask for the task in plain words; the agent picks the skill
from its description. Skills with scripts list their own install step (`npm install`,
`pip install pypdf`, ...) in their README.

## Third-party skills

```bash
scripts/fetch-third-party.sh            # all of them, into ./third_party (git-ignored)
.\scripts\fetch-third-party.ps1 shadcn  # Windows, just one
```

The list, the pinned commits and why each one is pinned to that commit are in
[THIRD_PARTY_SKILLS.md](THIRD_PARTY_SKILLS.md).

## Checks

```bash
python tools/skill_catalog.py validate --strict    # SKILL.md frontmatter rules
python -m unittest discover -s tools/tests -p "test_*.py"
python tools/check_links.py                        # relative Markdown links resolve
```

GitHub Actions runs these plus a secret scan (`tools/Test-PublicSafety.ps1`) on every push.

## License

Apache-2.0 ([LICENSE](LICENSE)) covers my own skills and scripts in this repo only.
Third-party skills keep their upstream licenses and are not redistributed here; see
[THIRD_PARTY_SKILLS.md](THIRD_PARTY_SKILLS.md). One generated file inside
`wechat-video-channel-publish` (`src/stealth.min.js`) comes from puppeteer-extra under
MIT; its copyright and license text are in that skill's
[THIRD_PARTY_NOTICES.md](skills/vipin/wechat-video-channel-publish/THIRD_PARTY_NOTICES.md).
