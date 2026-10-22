# Google Cloud OAuth Setup

The scripts talk to Gmail through your own Google Cloud OAuth client. Keep its files in
the local auth folder, never in git.

## Auth folder

- `$EMAIL_ASSISTANT_AUTH_DIR`, if set;
- otherwise `.wiki-tmp/email-assistant/auth/` inside the skill folder (git-ignored).

It holds two files:

- `credentials.json`: the OAuth client you download in the steps below;
- `tokens.json`: written by `npm run setup`, one entry per account.

## Google Cloud steps

1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. Create or select a project, for example `Email Assistant`.
3. Enable the Gmail API.
4. Configure the OAuth consent screen.
5. Add the Gmail account as a test user if the app is in testing mode.
6. Add these Gmail scopes:
   - `https://www.googleapis.com/auth/gmail.modify`
   - `https://www.googleapis.com/auth/gmail.compose`
   - `https://www.googleapis.com/auth/gmail.send`
7. Create an OAuth Client ID with application type `Desktop app`.
8. Download the JSON file and save it as `credentials.json` in the auth folder.

## Local setup

From the skill folder:

```powershell
npm install
npm run setup -- --account work --email "<work email address>"
npm run setup -- --account personal --email "<personal email address>"
node scripts/manage-accounts.js --list
```

The setup opens a browser. Pick the account and accept the consent screen yourself.

## Safety notes

- Do not commit `credentials.json`, `tokens.json`, browser profiles, cookies, or email bodies.
- The default workflow creates drafts rather than sending.
- Direct sends require `--confirm-send YES_SEND`.
- If a university or work account blocks Gmail API access, leave that account pending
  and keep the others working.
