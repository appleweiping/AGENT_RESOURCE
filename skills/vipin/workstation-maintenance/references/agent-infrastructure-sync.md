# Agent Infrastructure Sync

## Source Layout

The source of this shared skill is:

```text
D:\agent-resources\skills\vipin\workstation-maintenance
```

Expose it to agents through junctions or symlinks:

```text
D:\devtools\codex\home\skills\workstation-maintenance
D:\devtools\claude\skills\workstation-maintenance
```

Do not keep independent copies under `D:\devtools`; devtools should expose the shared source rather than owning a second version.

## Documentation To Update Together

When changing workstation maintenance behavior, update the relevant files in the same turn:

- `D:\agent-resources\README.md`
- `D:\agent-resources\SKILL-INDEX.md`
- `D:\devtools\README.md`
- `D:\Research\vipin's knowledgebase\AGENTS.md`
- `D:\Research\vipin's knowledgebase\README.md`
- `D:\Research\vipin's knowledgebase\CLAUDE.md`
- `D:\Research\vipin's knowledgebase\.opencode\OPENCODE.md`
- `D:\Research\vipin's knowledgebase\.claude\skills\README-skills-layout.md`
- `vipin-wiki` skill files
- relevant `wiki/` pages, `wiki/index.md`, `wiki/log.md`, and `wiki/catalog.json`

## Commit Boundaries

Commit repositories separately:

- `agent-resources`: shared skill source and index/README.
- `devtools`: junction ignore rules and devtools documentation only.
- `vipinknowledge`: wiki, agent docs, and vipin-wiki skill updates only.

Do not stage unrelated dirty files in `D:\devtools`, especially agent settings, automations, caches, or unrelated skills.
