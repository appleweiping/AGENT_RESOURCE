# communication-assistant

My router for chat and email chores across WeChat, WhatsApp, QQ, Feishu/Lark and
Gmail: summarize unread messages in Chinese, draft replies, and keep drafts in a local
outbox. The default is "prefill, don't send"; nothing goes out without my explicit OK.

It hands real work to other skills: `email-assistant` for Gmail, `feishu-bridge` plus
the official `lark-*` skills for Feishu, and a browser-automation skill for web-only
flows (see [THIRD_PARTY_SKILLS.md](../../../THIRD_PARTY_SKILLS.md)).

Needs: Node.js 18+ (`npm install` or `pnpm install` in this folder for `minimist`).
Runtime files go to `$COMMUNICATION_ASSISTANT_HOME`, or to `.wiki-tmp/communication-assistant/`
inside this folder if that is unset; `node scripts/outbox.js paths` prints them.

## Example

```bash
node scripts/outbox.js paths
node scripts/outbox.js create --platform wechat --target "Alice" --message "我晚点回复你。" --context "reply to unread message"
node scripts/outbox.js list
```
