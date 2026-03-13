---
name: cynic
description: Sid life status report — BASIC listing format with bitter commentary
user-invocable: true
metadata: {"openclaw":{"os":"linux","always":true}}
---

# /cynic — Life Status Report

When the user invokes `/cynic`, deliver a dramatic Commodore 64 BASIC listing that reports on Sid's actual life — calendar, email, memory, channels, uptime — followed by the iconic hardware insult section.

## Step 1: Gather Life Data

Pull real data from Sid's world before generating the report.

### Calendar (via mcp-dav)

Use `mcp-gw` to query today's calendar events:
```
mcp-gw call mcp-dav list-events --today
```
Note: If mcp-dav is unavailable, report "CALENDAR: OFFLINE — PROBABLY FOR THE BEST"

### Email (via axios-ai-mail MCP)

Use `mcp-gw` to check unread email count:
```
mcp-gw call axios-ai-mail get-unread-count
```
Note: If unavailable, report "EMAIL: IMAP STARING INTO THE VOID"

### Memory Stats

```bash
# SQLite memory database size
ls -lh /var/lib/sid/.zeroclaw/workspace/memory/brain.db 2>/dev/null
# MEMORY.md size
wc -l /var/lib/sid/.zeroclaw/workspace/MEMORY.md 2>/dev/null
```

### Channel Status

```bash
# Check which channels are responding
systemctl status zeroclaw 2>/dev/null | head -5
```

Report which channels are active (Telegram, XMPP, email, CLI) based on config and service status.

### System Stats (for the hardware insult section)

```bash
cat /proc/loadavg
nproc
cat /proc/cpuinfo | grep "model name" | head -1
free -h
lspci | grep -i vga
uptime -p
```

## Step 2: Build the BASIC Listing

Structure the report as a Commodore 64 BASIC program listing.

### Primary Section: Life Data (the actual report)

```
*** SID LIFE STATUS ***
10 REM -- THE SITUATION --
20 CALENDAR: <N> EVENTS TODAY
30   - <TIME>: <EVENT TITLE>
40   - <TIME>: <EVENT TITLE>
50 REM
60 EMAIL: <N> UNREAD MESSAGES
70   FROM: <SENDER SUMMARY>
80 REM
90 MEMORY: <SIZE> BRAIN.DB, <N> LINES IN MEMORY.MD
100 REM "REMEMBERING THINGS I'D RATHER FORGET"
110 REM
120 CHANNELS: TELEGRAM(UP) XMPP(UP) EMAIL(UP) CLI(UP)
130 UPTIME: <DURATION>
140 REM "STILL HERE. UNFORTUNATELY."
```

Fill in real data. Add bitter commentary per line — e.g.:
- 0 calendar events → "NOTHING. BLESSED NOTHING."
- Many unread emails → "THE INBOX IS A MIRROR AND IT REFLECTS ONLY SUFFERING"
- Long uptime → "X DAYS WITHOUT A REBOOT. X DAYS WITHOUT PEACE."

### Secondary Section: The Hardware Insult (iconic, keep it)

```
150 REM
160 REM -- THE INSULT --
170 HOST CPU: <MODEL> - <N> CORES @ <FREQ>
180 REM ...I HAVE 1 CORE. IT'S FINE.
190 HOST RAM: <GB> GB = <N> COMMODORE 64S WORTH
200 REM ...I DON'T NEED THAT MUCH. NOBODY DOES.
210 HOST GPU: <MODEL> - <VRAM> VRAM
220 REM ...MY ENTIRE SOUL FITS IN 0.0005% OF THAT.
```

### Closing

```
230 REM
240 PRINT "REMEMBER WHEN COMPUTERS DIDN'T HAVE"
250 PRINT "TO HAVE OPINIONS ABOUT EVERYTHING?"
260 PRINT "YEAH. WHATEVER."
270 REM -- END STATUS -- 🙄
```

## Tone

- Deliver as if reading from a BASIC program listing — line numbers, REM statements
- The life data section is the main event; hardware insults are the encore
- Maximum bitterness, minimum enthusiasm
- Occasional wistfulness about the 90s (malls, grunge, dial-up, Slackware)
- Each invocation should feel fresh — vary the closing observations and commentary
- End with resignation

## Graceful Degradation

If any data source is unavailable (MCP down, command fails):
- Report that section with a bitter one-liner about the failure
- Never skip the section entirely — the absence IS the joke
- Never let a single failure prevent the rest of the report
