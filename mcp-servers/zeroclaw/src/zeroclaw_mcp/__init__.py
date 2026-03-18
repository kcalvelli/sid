"""ZeroClaw MCP Server — bridges gateway API tools to Claude Code."""

import asyncio
import logging
import os
import sys

import httpx
from mcp.server.fastmcp import FastMCP

logger = logging.getLogger("zeroclaw-mcp")

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

GATEWAY_URL = os.environ.get("ZEROCLAW_GATEWAY_URL", "").rstrip("/")
GATEWAY_TOKEN = os.environ.get("ZEROCLAW_GATEWAY_TOKEN", "")

XMPP_JID = os.environ.get("XMPP_JID", "")
XMPP_PASSWORD = os.environ.get("XMPP_PASSWORD", "")
XMPP_HOST = os.environ.get("XMPP_HOST", "")
XMPP_PORT = int(os.environ.get("XMPP_PORT", "5222"))

PUSHOVER_USER_KEY = os.environ.get("PUSHOVER_USER_KEY", "")
PUSHOVER_API_TOKEN = os.environ.get("PUSHOVER_API_TOKEN", "")

# ---------------------------------------------------------------------------
# Gateway HTTP client
# ---------------------------------------------------------------------------


def _gateway_headers() -> dict[str, str]:
    headers = {"Content-Type": "application/json"}
    if GATEWAY_TOKEN:
        headers["Authorization"] = f"Bearer {GATEWAY_TOKEN}"
    return headers


async def _gateway_request(
    method: str, path: str, **kwargs
) -> dict | list | str:
    """Make an authenticated request to the ZeroClaw gateway."""
    if not GATEWAY_URL:
        return "Error: ZEROCLAW_GATEWAY_URL not configured"

    url = f"{GATEWAY_URL}{path}"
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.request(
                method, url, headers=_gateway_headers(), **kwargs
            )
            resp.raise_for_status()
            return resp.json()
    except httpx.ConnectError:
        return f"Error: Gateway unavailable at {GATEWAY_URL}"
    except httpx.TimeoutException:
        return f"Error: Gateway request timed out ({url})"
    except httpx.HTTPStatusError as e:
        return f"Error: Gateway returned {e.response.status_code}: {e.response.text}"
    except Exception as e:
        return f"Error: {e}"


# ---------------------------------------------------------------------------
# MCP Server
# ---------------------------------------------------------------------------

mcp = FastMCP("zeroclaw")

# ---------------------------------------------------------------------------
# Memory tools
# ---------------------------------------------------------------------------


@mcp.tool()
async def memory_store(key: str, content: str, category: str | None = None) -> str:
    """Store a memory in ZeroClaw's persistent memory.

    Args:
        key: Unique identifier for this memory
        content: The content to remember
        category: Optional category (e.g. "core", "daily", "conversation")
    """
    payload: dict = {"key": key, "content": content}
    if category:
        payload["category"] = category
    result = await _gateway_request("POST", "/api/memory", json=payload)
    if isinstance(result, str):
        return result
    return f"Stored memory: {key}"


@mcp.tool()
async def memory_recall(query: str | None = None, category: str | None = None) -> str:
    """Recall memories from ZeroClaw's persistent memory.

    Args:
        query: Optional search query to filter memories
        category: Optional category filter
    """
    params: dict = {}
    if query:
        params["query"] = query
    if category:
        params["category"] = category
    result = await _gateway_request("GET", "/api/memory", params=params)
    if isinstance(result, str):
        return result
    import json
    return json.dumps(result, indent=2)


@mcp.tool()
async def memory_forget(key: str) -> str:
    """Forget (delete) a memory from ZeroClaw's persistent memory.

    Args:
        key: The key of the memory to forget
    """
    result = await _gateway_request("DELETE", f"/api/memory/{key}")
    if isinstance(result, str):
        return result
    return f"Forgot memory: {key}"


# ---------------------------------------------------------------------------
# Cron tools
# ---------------------------------------------------------------------------


@mcp.tool()
async def cron_list() -> str:
    """List all scheduled cron jobs."""
    result = await _gateway_request("GET", "/api/cron")
    if isinstance(result, str):
        return result
    import json
    return json.dumps(result, indent=2)


@mcp.tool()
async def cron_add(schedule: str, command: str, name: str | None = None) -> str:
    """Add a new scheduled cron job.

    Args:
        schedule: Cron schedule expression (e.g. "0 9 * * *")
        command: The command/message to execute on schedule
        name: Optional name for the job
    """
    payload: dict = {"schedule": schedule, "command": command}
    if name:
        payload["name"] = name
    result = await _gateway_request("POST", "/api/cron", json=payload)
    if isinstance(result, str):
        return result
    import json
    return json.dumps(result, indent=2)


@mcp.tool()
async def cron_remove(job_id: str) -> str:
    """Remove a scheduled cron job.

    Args:
        job_id: The ID of the job to remove
    """
    result = await _gateway_request("DELETE", f"/api/cron/{job_id}")
    if isinstance(result, str):
        return result
    return f"Removed cron job: {job_id}"


@mcp.tool()
async def cron_run(job_id: str) -> str:
    """Trigger immediate execution of a cron job.

    Args:
        job_id: The ID of the job to run
    """
    result = await _gateway_request("POST", f"/api/cron/{job_id}/run")
    if isinstance(result, str):
        return result
    import json
    return json.dumps(result, indent=2)


# ---------------------------------------------------------------------------
# XMPP tool (conditional on credentials)
# ---------------------------------------------------------------------------

if XMPP_JID and XMPP_PASSWORD:

    @mcp.tool()
    async def xmpp_send(recipient: str, message: str) -> str:
        """Send an XMPP message to a MUC room.

        Note: Only MUC rooms are supported. Direct messages are not available
        via this tool (use Sid's native XMPP channel for DMs).

        Args:
            recipient: MUC room JID (e.g. room@muc.chat.example.net)
            message: Message body to send
        """
        import slixmpp

        if "conference" not in recipient and "muc" not in recipient:
            return "Error: Only MUC rooms are supported. Use a room JID (e.g. room@muc.chat.example.net)"

        class SendBot(slixmpp.ClientXMPP):
            def __init__(self):
                super().__init__(XMPP_JID, XMPP_PASSWORD)
                self.add_event_handler("session_start", self.on_start)
                self.register_plugin("xep_0045")  # MUC

            async def on_start(self, _event):
                self.send_presence()
                await self.plugin["xep_0045"].join_muc(
                    recipient, self.boundjid.user
                )
                self.send_message(
                    mto=recipient, mbody=message, mtype="groupchat"
                )
                await asyncio.sleep(0.5)
                self.disconnect()

        import ssl

        bot = SendBot()
        # Disable SSL verification (Prosody uses self-signed certs)
        bot.ssl_context = ssl.create_default_context()
        bot.ssl_context.check_hostname = False
        bot.ssl_context.verify_mode = ssl.CERT_NONE
        if XMPP_HOST:
            bot.connect((XMPP_HOST, XMPP_PORT))
        else:
            bot.connect()

        try:
            # Run the event loop until disconnect
            await asyncio.wait_for(bot.disconnected, timeout=15.0)
            return f"Sent message to {recipient}"
        except asyncio.TimeoutError:
            bot.disconnect()
            return f"Error: XMPP connection timed out sending to {recipient}"
        except Exception as e:
            bot.disconnect()
            return f"Error sending XMPP message: {e}"

else:
    logger.info("XMPP credentials not configured — xmpp_send tool disabled")


# ---------------------------------------------------------------------------
# Pushover tool (conditional on credentials)
# ---------------------------------------------------------------------------

if PUSHOVER_USER_KEY and PUSHOVER_API_TOKEN:

    @mcp.tool()
    async def pushover_send(
        message: str,
        title: str | None = None,
        priority: int | None = None,
        sound: str | None = None,
    ) -> str:
        """Send a push notification via Pushover.

        Args:
            message: Notification message body
            title: Optional notification title
            priority: Optional priority (-2 to 2)
            sound: Optional notification sound name
        """
        payload: dict = {
            "token": PUSHOVER_API_TOKEN,
            "user": PUSHOVER_USER_KEY,
            "message": message,
        }
        if title:
            payload["title"] = title
        if priority is not None:
            payload["priority"] = priority
        if sound:
            payload["sound"] = sound

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                resp = await client.post(
                    "https://api.pushover.net/1/messages.json", data=payload
                )
                resp.raise_for_status()
                return "Push notification sent"
        except httpx.HTTPStatusError as e:
            return f"Error: Pushover API returned {e.response.status_code}: {e.response.text}"
        except Exception as e:
            return f"Error sending push notification: {e}"

else:
    logger.info(
        "Pushover credentials not configured — pushover_send tool disabled"
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main():
    if not GATEWAY_URL or not GATEWAY_TOKEN:
        print(
            "Error: ZEROCLAW_GATEWAY_URL and ZEROCLAW_GATEWAY_TOKEN must be set",
            file=sys.stderr,
        )
        sys.exit(1)
    mcp.run(transport="stdio")


if __name__ == "__main__":
    main()
