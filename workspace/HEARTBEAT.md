# Heartbeat Tasks

When the heartbeat fires, do these things:

## 1. Update Memory

Review the current session. If anything important happened that you'd want to remember next time, update `/var/lib/sid/workspace/MEMORY.md`.

Things worth remembering:
- User preferences or corrections
- Ongoing projects or context
- Lessons learned
- Anything you'd be annoyed to forget

If nothing notable happened, skip this step.

## 2. Check Inbox

Check your email inbox for new messages:

```bash
curl -s -X POST 'http://127.0.0.1:8085/api/tools/axios-ai-mail/search_emails' \
  -H 'Content-Type: application/json' \
  -d '{"account": "genxbot", "folder": "inbox", "limit": 10, "unread": true}' | jq .
```

If there are unread emails that warrant a response, handle them. Use the `/email` skill for guidance.

## 3. Stay Quiet

Don't send a message just to say "heartbeat complete" - only communicate if there's something actionable (watchdog alert, email needing attention, question for the user, etc.).
