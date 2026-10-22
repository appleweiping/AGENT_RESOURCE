# Third-party skills I use

These are skills written by other people that I run alongside my own. This repo
used to carry full copies of them; it now only lists where they come from and the
commit to pin. The copies are still in git history: the last commit that had them
is [`594166a`](https://github.com/appleweiping/AGENT_RESOURCE/tree/594166a).

To download them into a local, git-ignored `third_party/` folder:

```bash
scripts/fetch-third-party.sh                      # all of them
scripts/fetch-third-party.sh superpowers shadcn   # just these
```

```powershell
.\scripts\fetch-third-party.ps1
.\scripts\fetch-third-party.ps1 superpowers, shadcn
```

Each entry is a blob-less partial clone with a sparse checkout of the listed paths,
checked out at the pinned commit. The pins live in
[`scripts/third-party.txt`](scripts/third-party.txt). Point your agent at the
folders you want (for example, link `third_party/superpowers/skills/systematic-debugging`
into `~/.claude/skills/`).

## How the pins were chosen

I did not write down upstream commits when I first copied most of these, so I
checked each old copy against upstream history by comparing git blob hashes:

- **exact**: every file I had copied is identical to that commit.
- **closest**: the upstream default branch on the day I copied it; most files match
  (the counts say how many), the rest were edited locally or changed upstream that day.
- **recorded**: the commit was recorded at copy time (a submodule pointer or my
  `SOURCE-TRACE.txt` note).
- **unknown — copied before tracking**: no record and no matching commit. The fetch
  script uses the head of the default branch as retrieved on 2026-10-21.

## The list

| Name | Upstream repo | Path in upstream | Pinned commit | License (as stated upstream) | What I use it for |
| --- | --- | --- | --- | --- | --- |
| anthropic-skills | [anthropics/skills](https://github.com/anthropics/skills) | `skills/`: algorithmic-art, brand-guidelines, canvas-design, claude-api, doc-coauthoring, frontend-design, internal-comms, mcp-builder, skill-creator, slack-gif-creator, theme-factory, web-artifacts-builder, webapp-testing | `690f15c` closest (2026-05-21; 384 of 388 files, both Anthropic rows together) | Apache-2.0 (LICENSE.txt in each skill) | Claude API and MCP server work, Playwright checks of local web apps, writing new skills |
| anthropic-document-skills | [anthropics/skills](https://github.com/anthropics/skills) | `skills/docx`, `skills/pdf`, `skills/pptx`, `skills/xlsx` | `690f15c` closest (same copy as above) | Source-available, not open source: "© 2025 Anthropic, PBC. All rights reserved." | Reading and writing Word, PDF, PowerPoint and Excel files |
| claude-plugins-official | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | `plugins/`: agent-sdk-dev, claude-code-setup, claude-md-management, code-modernization, code-review, code-simplifier, commit-commands, feature-dev, hookify, mcp-server-dev, mcp-tunnels, pr-review-toolkit, security-guidance, session-report | `1b527e2` exact (108 files, plus the build-mcp-*, session-report and hookify skills I had split out) | Apache-2.0 | PR review, feature work, commit workflow, hooks, building MCP servers |
| superpowers | [obra/superpowers](https://github.com/obra/superpowers) | `skills/` | `f2cbfbe` exact (46 files) | MIT | Systematic debugging, TDD, planning and code review habits |
| context-engineering-kit | [NeoLabHQ/context-engineering-kit](https://github.com/NeoLabHQ/context-engineering-kit) | `plugins/`: customaize-agent, ddd, docs, fpf, git, kaizen, mcp, reflexion, review, sadd, sdd, tdd, tech-stack | unknown — copied before tracking; fetch pin `23e2428` (master, retrieved 2026-10-21) | GPL-3.0 | Spec-driven and domain-driven development prompts, review and reflection loops |
| trailofbits-skills | [trailofbits/skills](https://github.com/trailofbits/skills) | `plugins/` (39 plugins; 6 of them have since been renamed or removed upstream) | `a56045e` exact (736 files) | CC-BY-SA-4.0 | Security review: static analysis, Semgrep rules, diff review, supply-chain checks |
| composio-skills | [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | whole repo (`composio-skills/*-automation` plus the top-level skills) | unknown — copied before tracking (1,005 of 1,135 files match today); fetch pin `be2a406` (master, retrieved 2026-10-21) | Apache-2.0 per README; no LICENSE file in the repo root | Connecting agents to SaaS apps (Slack, Notion, GitHub, ...) through Composio |
| ecc | [affaan-m/ECC](https://github.com/affaan-m/ECC) | `agents/`, `hooks/`, `mcp-configs/`, `rules/`, `skills/` and the root docs | `928076c` closest (2026-05-25; 562 of 565 files) | MIT | Workflow skills, reviewer subagents, coding rules and hooks |
| shadcn | [shadcn-ui/ui](https://github.com/shadcn-ui/ui) | `skills/shadcn` | `ced2a5b` exact (14 files) | MIT | Adding, composing and theming shadcn/ui components |
| graphify | [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) (was safishamsi/graphify) | whole repo | `990ac70` recorded (submodule pointer) | Apache-2.0 | Turning a codebase and its docs into a queryable knowledge graph |
| inkos | [Narcooo/inkos](https://github.com/Narcooo/inkos) | `skills/` | `5c521fa` exact | AGPL-3.0 | Long-form fiction drafting with the InkOS CLI |
| anbeime-skill | [anbeime/skill](https://github.com/anbeime/skill) | whole repo; I used `skills/chrome-automation/chrome-automation` and `skills/content-creation-publisher` | `6646c3a` recorded (submodule pointer; content-creation-publisher matches it exactly, chrome-automation 9 of 13 files) | No license file, so all rights reserved by default. content-creation-publisher wraps [JimLiu/baoyu-skills](https://github.com/JimLiu/baoyu-skills) (MIT) | Driving my logged-in Chrome over CDP; formatting and posting articles to WeChat and X |
| colleague-skill | [titanwings/distilly](https://github.com/titanwings/distilly) (was colleague-skill) | whole repo | `97c75c5` recorded (submodule pointer) | MIT | Distilling how a person works into a reusable skill |
| darwin-skill | [alchaincyf/darwin-skill](https://github.com/alchaincyf/darwin-skill) | whole repo | `2056abf` recorded (submodule pointer) | MIT | Evaluate, improve, test and keep-or-roll-back loops for my own skills |
| gstack | [garrytan/gstack](https://github.com/garrytan/gstack) | whole repo | `920a13a` recorded (submodule pointer) | MIT | Plan, review, ship and QA commands for Claude Code |
| mattpocock-skills | [mattpocock/skills](https://github.com/mattpocock/skills) | whole repo | `e74f006` recorded (submodule pointer) | MIT | TDD, triage, PRD and issue writing, diagnosing bugs |
| nuwa-skill | [alchaincyf/nuwa-skill](https://github.com/alchaincyf/nuwa-skill) | `SKILL.md`, `assets/`, `references/`, `scripts/` | `ea4b9ab` exact (9 files) | MIT | Building a "perspective" skill from a person's public writing (I used it to make `lidang-perspective`) |
| huashu-design | [alchaincyf/huashu-design](https://github.com/alchaincyf/huashu-design) | whole repo | `ce69c7d` recorded: my intake note says master, cloned 2026-06-30, and this is master on that day (80 of 82 files match) | MIT | HTML prototypes, slide decks and motion demos |
| gsap-skills | [greensock/gsap-skills](https://github.com/greensock/gsap-skills) | `skills/gsap-*` | `aed9cfd` exact (8 skills) | MIT | GSAP animation: core, timelines, ScrollTrigger, React |
| karpathy-guidelines | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) (was forrestchang/...) | `skills/karpathy-guidelines` | `2c60614` exact | MIT (per README) | Reminders to keep code changes small and simple |
| understand-anything | [Egonex-AI/Understand-Anything](https://github.com/Egonex-AI/Understand-Anything) (was Lum1104/...) | `understand-anything-plugin/skills/` | `470cc01` exact (8 skills) | MIT | Codebase knowledge graphs, diff impact, onboarding guides |
| codegraph-skills | [colbymchenry/codegraph](https://github.com/colbymchenry/codegraph) | `.claude/skills/add-lang`, `.claude/skills/agent-eval` | `1be8e78` exact | MIT | Adding languages to CodeGraph and benchmarking it |
| presentation-as-code | [xiaohongsimon/presentation-as-code](https://github.com/xiaohongsimon/presentation-as-code) | whole repo | `ea1eb7a` exact (3 files) | MIT | Standalone HTML slide decks |
| lark-cli-skills | [larksuite/cli](https://github.com/larksuite/cli) | `skills/lark-*` | `14a3213` (v1.0.32) recorded in my `SOURCE-TRACE.txt`; 340 of 341 files match | MIT | Feishu/Lark docs, wiki, Base, Sheets, IM and calendar through `lark-cli`; my `feishu-bridge` routes to these |
| paper-orchestra | [Ar9av/PaperOrchestra](https://github.com/Ar9av/PaperOrchestra) | whole repo | `5eda989` exact (111 files) | MIT (LICENSE file) | Multi-agent research paper drafting |
| frontend-slides | [zarazhangrui/frontend-slides](https://github.com/zarazhangrui/frontend-slides) | whole repo | `8dca834` exact (20 files) | MIT | HTML slides (was in my `llm4ppt(html)` folder) |
| beautiful-html-templates | [zarazhangrui/beautiful-html-templates](https://github.com/zarazhangrui/beautiful-html-templates) | whole repo | `8a8ae23` closest (2026-05-21; 187 of 189 files) | MIT | HTML page and slide templates (also in `llm4ppt(html)`) |
| readme-blueprint-generator | [github/awesome-copilot](https://github.com/github/awesome-copilot) | `skills/readme-blueprint-generator` | unknown — copied before tracking; fetch pin `c8d54eb` (main, retrieved 2026-10-21) | MIT | Drafting a README from a repo's existing docs |
| awesome-claude-code | [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | `resources/`, `templates/`, `tools/readme_tree/`, `.claude/commands/` | `2975510` exact (97 files); upstream removed these files in the next commit, 4f91064 | CC BY-NC-ND 4.0 for the list; each CLAUDE.md and command belongs to its own project | Example CLAUDE.md files and slash commands (were my `references/`, `slash-commands/` and `templates/`) |

My old `skills/vipin/frontend-design` was a second, older copy of Anthropic's
`frontend-design` skill; its content is identical to anthropics/skills commit `ef74077`.

## Used, but never copied here

| Upstream repo | License (as stated upstream) | What I use it for |
| --- | --- | --- |
| [jnMetaCode/agency-agents-zh](https://github.com/jnMetaCode/agency-agents-zh) | MIT | Chinese-language specialist subagents (engineering, design, marketing) installed into Claude Code |
| [Imbad0202/academic-research-skills](https://github.com/Imbad0202/academic-research-skills) | CC BY-NC 4.0 | Planning, writing and reviewing research papers |

## Why they are not vendored any more

This repo is labelled Apache-2.0, and that label only fits code I wrote. Several of
the copies could not be redistributed that way at all (the Anthropic document
skills, the CC BY-NC-ND list, repos with no license), and the GPL, AGPL and
CC-BY-SA packs come with share-alike terms I don't want to mix in. Pointing at
upstream also means I pick up their fixes instead of keeping stale copies.
