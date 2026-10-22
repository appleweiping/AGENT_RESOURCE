# email-assistant

Small Gmail API scripts an agent can call to search, read, summarize and draft email
for my two Gmail accounts, without driving a browser. Drafting is the default; sending
needs an explicit `--confirm-send YES_SEND`.

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
