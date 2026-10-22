# Skill Index

One entry per skill in this repo: what it does, when to use it, and where it lives.
Agents should pick a skill from the request itself, not only when the skill is named,
then read that skill's `SKILL.md` before starting.

Third-party skills I use (debugging, TDD, code review, security review, documents,
Lark, frontend design, ...) are not in this repo. They are listed with pinned upstream
commits in [THIRD_PARTY_SKILLS.md](THIRD_PARTY_SKILLS.md) and download into
`third_party/` with `scripts/fetch-third-party.sh` or `.ps1`.

## workstation-maintenance
- What: Inventory local drives, plan file moves in type-grouped batches (30-day age gate, 100 items per batch), move a drive's top-level folders behind junctions, write rollback manifests. Protected folders come from a local `config.json`.
- When: "clean up / organize my drives", "tidy my Downloads", preparing or approving a move batch, undoing a move.
- Path: [skills/vipin/workstation-maintenance](skills/vipin/workstation-maintenance)

## project-hardness
- What: Build a `.agent/` model of a project (architecture, constraints, modules, blast radius) and turn a vague requirement into a task spec with edit paths, risks and test commands. Engine: `scripts/wiki.py hardness` in [WEIPING_WIKI](https://github.com/appleweiping/WEIPING_WIKI).
- When: Starting on an unfamiliar or large project, checking what a change could break, or before acting on an unclear request.
- Path: [skills/vipin/project-hardness](skills/vipin/project-hardness)

## literature-to-manga
- What: Rank candidate books, then produce an adaptation brief, manga bible, chapter/page/panel scripts and a JSONL image-prompt pack.
- When: Adapting a novel, biography or history text into manga or comics, or picking which book in a folder to adapt.
- Path: [skills/vipin/literature-to-manga](skills/vipin/literature-to-manga)

## communication-assistant
- What: Triage, summarize (in Chinese) and draft replies across WeChat, WhatsApp, QQ, Feishu/Lark and email; keeps a local outbox; prefill, never send without approval.
- When: "what did I miss", "draft a reply to ...", "prefill this message", anything spanning several chat apps.
- Path: [skills/vipin/communication-assistant](skills/vipin/communication-assistant)

## email-assistant
- What: Gmail API scripts to search, read, summarize, translate and draft mail for several accounts; sending needs `--confirm-send YES_SEND`.
- When: Reading or answering Gmail / Google Workspace mail without opening a browser.
- Path: [skills/vipin/email-assistant](skills/vipin/email-assistant)

## feishu-bridge
- What: Routing rules for Feishu/Lark: official `lark-cli` API first, browser automation only for web-only pages and forms.
- When: Any Feishu/Lark link, doc, wiki, Base, Sheets, message or form (飞书文档、知识库、多维表格、表单).
- Path: [skills/vipin/feishu-bridge](skills/vipin/feishu-bridge)

## wechat-video-channel-publish
- What: Playwright CLI for WeChat Channels (微信视频号): QR login, cookie check, upload, schedule, draft, cover, description.
- When: Publishing or scheduling a video on 视频号.
- Path: [skills/vipin/wechat-video-channel-publish](skills/vipin/wechat-video-channel-publish)

## lidang-perspective
- What: Persona skill built with nuwa-skill from 立党 (Li Dang)'s public writing; mental models and decision heuristics for career, tech, immigration and education paths.
- When: "用立党的视角", "立党会怎么看", or a request for his angle on a path decision.
- Path: [skills/standalone/lidang-perspective](skills/standalone/lidang-perspective)

## deepseek-mcp
- What: Small MCP server with one tool, `deepseek_chat`, so Codex can hand cheap summarizing or rewriting to DeepSeek.
- When: Setting up or using DeepSeek as a side model inside Codex.
- Path: [skills/standalone/deepseek-mcp](skills/standalone/deepseek-mcp)
