# email-assistant

Small Gmail API scripts an agent can call to search, read, summarize and draft email
for my two Gmail accounts, without driving a browser. Drafting is the default; sending
needs an explicit `--confirm-send YES_SEND`. The scripts are an edited copy of someone
else's MIT-licensed `gmail-skill`; see [Where this came from](#where-this-came-from).

Needs: Node.js 18+, `pnpm install` (or `npm install`) in this folder, and your own
Google Cloud OAuth desktop client. [docs/google-cloud-setup.md](docs/google-cloud-setup.md)
walks through creating it. Tokens are stored in `$EMAIL_ASSISTANT_AUTH_DIR`, never in git.
The account names `umn` and `vipinapple` in `SKILL.md` are mine; any name works with
`--account`, and `scripts/manage-accounts.js --list` shows what is set up.

## Example

```bash
node scripts/auth/setup-oauth.js --account work --email you@example.com
node scripts/gmail-search.js --account work --query "is:unread newer_than:7d" --limit 10
node scripts/gmail-drafts.js --account work --action create --to "person@example.com" --subject "Re: meeting" --body "Thursday works for me."
```

## Where this came from

This skill started as a copy of `gmail-skill`, a set of Gmail CLI scripts for Claude Code
published under the MIT license. Its `package.json` names no author, I kept no note of
where I got it, and I have not found an original repository. The same files are public
in [benchflow-ai/skillsbench](https://github.com/benchflow-ai/skillsbench/tree/main/tasks-extra/scheduling-email-assistant/environment/skills/gmail-skill),
where they were added in January 2026 as a skill bundled with one benchmark task; I
don't know whether that is where they were first published. If you know who wrote it,
please open an issue and I will credit them by name.

Compared with that copy:

- `scripts/gmail-search.js` and `scripts/gmail-read.js` are unchanged.
- `scripts/gmail-labels.js`, `scripts/gmail-send.js` and `scripts/gmail-drafts.js` are
  small edits: they refuse to change labels, send or delete without
  `--confirm-modify YES_MODIFY`, `--confirm-send YES_SEND` or `--confirm-delete YES_DELETE`,
  and the message builder moved into `scripts/email-message.js`.
- `scripts/auth/*.js`, `scripts/manage-accounts.js` and `scripts/action-logger.js` are
  edited versions: token and log folders come from `scripts/auth/paths.js` (environment
  variables), the old single-account token migration is gone, and the action log also
  leaves out message bodies.
- `SKILL.md` and `docs/google-cloud-setup.md` are rewritten for how I use it.
- `gmail-filters.js`, `gmail-forward.js`, `gmail-every-paywall-cleanup.js` and
  `migrate-tokens.js` from that copy are not included.

Because of that, this folder is under the MIT license in [LICENSE](LICENSE), not the
repository's Apache-2.0.
