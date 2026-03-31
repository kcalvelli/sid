## ADDED Requirements

### Requirement: XMPP channel connects via STARTTLS

The XMPP channel SHALL connect to the configured XMPP server using STARTTLS on port 5222 (not direct TLS on 5223). The channel SHALL authenticate using the configured JID and password. When `ssl_verify` is false, the channel SHALL accept self-signed or invalid TLS certificates. The channel SHALL connect to the address specified in `server` config (not derived from JID domain) to support Tailscale/localhost setups where server hostname differs from XMPP domain.

#### Scenario: Successful STARTTLS connection
- **WHEN** the XMPP channel starts with a valid JID, password, and server address
- **THEN** it SHALL establish a STARTTLS connection on port 5222 and authenticate successfully

#### Scenario: Self-signed certificate with ssl_verify disabled
- **WHEN** `ssl_verify = false` and the server presents a self-signed certificate
- **THEN** the channel SHALL accept the certificate and connect successfully

#### Scenario: Self-signed certificate with ssl_verify enabled
- **WHEN** `ssl_verify = true` and the server presents a self-signed certificate
- **THEN** the channel SHALL reject the connection and log an error

#### Scenario: Server address differs from JID domain
- **WHEN** JID is `sid@example.com` but `server = "edge.tailnet.ts.net"`
- **THEN** the channel SHALL connect to `edge.tailnet.ts.net:5222` and authenticate as `sid@example.com`

### Requirement: XMPP channel handles direct messages

The XMPP channel SHALL receive and process direct messages (type="chat") from any XMPP user. The sender JID (bare JID, without resource) SHALL be used as the `sender` and `reply_target` fields of the `ChannelMessage`. All direct messages SHALL be passed to the agent loop without filtering.

#### Scenario: Receive a direct message
- **WHEN** user `keith@example.com/phone` sends a chat message "What's the server load?"
- **THEN** a `ChannelMessage` SHALL be created with sender `keith@example.com`, reply_target `keith@example.com`, content "What's the server load?", and channel "xmpp"

#### Scenario: Reply to a direct message
- **WHEN** the agent generates a response to a direct message from `keith@example.com`
- **THEN** the channel SHALL send a type="chat" message to `keith@example.com`

### Requirement: XMPP channel handles MUC groupchat messages with mention detection

The XMPP channel SHALL join configured MUC rooms on startup using the configured `muc_nick`. In MUC rooms, the channel SHALL only process messages that mention the bot. Mention detection SHALL match: `@nick`, `nick:`, or bare `nick` at a word boundary (case-insensitive). The mention SHALL be stripped from the message content before passing to the agent. MUC responses SHALL be prefixed with `sender_nick: `.

#### Scenario: MUC message with @mention
- **WHEN** user "keith" sends "hey @Sid what's the weather?" in MUC room `lounge@conference.example.com`
- **THEN** a `ChannelMessage` SHALL be created with sender "keith", content "hey what's the weather?", and the mention "@Sid" stripped

#### Scenario: MUC message with nick-colon mention
- **WHEN** user "keith" sends "Sid: check the logs" in a MUC room
- **THEN** a `ChannelMessage` SHALL be created with content "check the logs" (mention "Sid:" stripped)

#### Scenario: MUC message with bare nick mention
- **WHEN** user "keith" sends "hey sid how are you" in a MUC room
- **THEN** a `ChannelMessage` SHALL be created with content "hey how are you" (mention "sid" stripped)

#### Scenario: MUC message without mention is ignored
- **WHEN** user "keith" sends "anyone seen the new release?" in a MUC room (no bot mention)
- **THEN** the channel SHALL NOT create a `ChannelMessage` or invoke the agent loop

#### Scenario: MUC response is prefixed with sender nick
- **WHEN** the agent responds to a MUC message from "keith"
- **THEN** the sent message content SHALL be prefixed with "keith: "

#### Scenario: Bot's own messages are ignored
- **WHEN** the bot's own MUC messages are reflected back (same nick as `muc_nick`)
- **THEN** the channel SHALL NOT process them

### Requirement: XMPP channel sends chat state notifications

The channel SHALL send XEP-0085 chat state notifications. When `start_typing()` is called, the channel SHALL send a "composing" chat state to the recipient. When `stop_typing()` is called, the channel SHALL send an "active" chat state. Chat states SHALL work for both direct messages and MUC rooms.

#### Scenario: Typing indicator in direct message
- **WHEN** `start_typing("keith@example.com")` is called
- **THEN** the channel SHALL send a "composing" chat state notification to `keith@example.com`

#### Scenario: Stop typing in direct message
- **WHEN** `stop_typing("keith@example.com")` is called
- **THEN** the channel SHALL send an "active" chat state notification to `keith@example.com`

#### Scenario: Typing indicator in MUC room
- **WHEN** `start_typing("lounge@conference.example.com")` is called
- **THEN** the channel SHALL send a "composing" chat state notification to the MUC room

### Requirement: XMPP channel detects and downloads OOB media

The channel SHALL detect Out-of-Band Data (XEP-0066) URLs in incoming messages. When an OOB URL points to a supported image format (JPEG, PNG, GIF, WebP up to 3.75MB), the channel SHALL download the file and include it in the message content using the `[IMAGE:/path]` marker format so it enters ZeroClaw's multimodal pipeline. When an OOB URL points to a non-image type (PDF up to 32MB), the channel SHALL download and include it as `[Attached file: /path]`. Unsupported file types or oversized files SHALL be noted in the message content but not downloaded.

#### Scenario: Image shared via OOB
- **WHEN** a message includes an OOB URL pointing to a JPEG, PNG, GIF, or WebP image
- **THEN** the channel SHALL download the image to `/tmp/xmpp_media_<timestamp>.<ext>` and the message content includes `[IMAGE:/tmp/xmpp_media_<timestamp>.<ext>]`

#### Scenario: Oversized file via OOB
- **WHEN** a message includes an OOB URL pointing to a 50MB video file
- **THEN** the channel SHALL NOT download the file and SHALL include a note in the message content indicating the file was too large

#### Scenario: PDF shared via OOB
- **WHEN** a message includes an OOB URL pointing to a PDF (10MB)
- **THEN** the channel SHALL download the PDF and include the file path in the `ChannelMessage` content

### Requirement: XMPP channel auto-reconnects with exponential backoff

The channel SHALL automatically reconnect when the XMPP connection drops. Reconnection SHALL use exponential backoff starting at 1 second, doubling each attempt, with a maximum backoff of 5 minutes. On successful reconnection, the channel SHALL rejoin all configured MUC rooms and restore presence.

#### Scenario: Connection lost and recovered
- **WHEN** the TCP connection to the XMPP server drops
- **THEN** the channel SHALL attempt to reconnect with exponential backoff until successful, then rejoin MUC rooms

#### Scenario: Backoff reaches maximum
- **WHEN** reconnection fails 10 consecutive times
- **THEN** the backoff interval SHALL cap at 5 minutes (not grow further)

### Requirement: XMPP channel uses system DNS resolver

The channel SHALL NOT perform XMPP SRV record lookups or use custom DNS resolution. It SHALL connect directly to the `server` address and `port` specified in configuration, using the system's default DNS resolver. This ensures compatibility with Tailscale MagicDNS and split-DNS environments.

#### Scenario: Direct connection without SRV lookup
- **WHEN** config specifies `server = "edge.tailnet.ts.net"` and `port = 5222`
- **THEN** the channel SHALL resolve `edge.tailnet.ts.net` via system DNS and connect to that address on port 5222, without querying `_xmpp-client._tcp.example.com` SRV records

### Requirement: xmpp_send_message tool

The agent SHALL have access to an `xmpp_send_message` tool that sends a message to a JID or MUC room. Parameters: `to` (JID or room JID, required), `body` (message text, required), `type` (optional: "chat" or "groupchat", auto-detected from JID if omitted). The tool SHALL return success/failure status.

#### Scenario: Send direct message via tool
- **WHEN** the agent calls `xmpp_send_message` with `to = "keith@example.com"` and `body = "Server load is normal"`
- **THEN** a type="chat" message SHALL be sent to `keith@example.com`

#### Scenario: Send MUC message via tool
- **WHEN** the agent calls `xmpp_send_message` with `to = "lounge@conference.example.com"` and `body = "Heads up: deploy starting"`
- **THEN** a type="groupchat" message SHALL be sent to the MUC room

### Requirement: xmpp_list_rooms tool

The agent SHALL have access to an `xmpp_list_rooms` tool that queries the MUC service for available rooms via disco#items (XEP-0030). Parameters: `service` (optional, defaults to `conference.<domain>`). Returns a list of room JIDs and names.

#### Scenario: List available rooms
- **WHEN** the agent calls `xmpp_list_rooms`
- **THEN** the tool SHALL send a disco#items query to the MUC service and return the list of rooms with JIDs and names

### Requirement: xmpp_join_room and xmpp_leave_room tools

The agent SHALL have access to `xmpp_join_room` and `xmpp_leave_room` tools. `xmpp_join_room` parameters: `room` (room JID, required), `nick` (optional, defaults to `muc_nick`). `xmpp_leave_room` parameters: `room` (room JID, required). Both SHALL return success/failure status.

#### Scenario: Join a new room
- **WHEN** the agent calls `xmpp_join_room` with `room = "dev@conference.example.com"`
- **THEN** the channel SHALL send MUC presence to join the room with the configured nick

#### Scenario: Leave a room
- **WHEN** the agent calls `xmpp_leave_room` with `room = "dev@conference.example.com"`
- **THEN** the channel SHALL send unavailable presence to leave the room

### Requirement: xmpp_set_presence tool

The agent SHALL have access to an `xmpp_set_presence` tool that updates the bot's XMPP presence. Parameters: `status` (status text, optional), `show` (optional: "available", "away", "dnd", "xa"). Defaults to show="available" with the configured status text.

#### Scenario: Set presence to away
- **WHEN** the agent calls `xmpp_set_presence` with `show = "away"` and `status = "Thinking..."`
- **THEN** the bot's XMPP presence SHALL update to "away" with status "Thinking..."

#### Scenario: Set presence to available with status
- **WHEN** the agent calls `xmpp_set_presence` with `status = "Sid here - what's up?"`
- **THEN** the bot's XMPP presence SHALL show as available with the given status text

### Requirement: XMPP channel configuration

The channel SHALL be configured via `[channels_config.xmpp]` in config.toml with the following fields:
- `jid` (string, required): Full JID for the bot (e.g., `sid@example.com`)
- `password` (string, required): XMPP account password (injected by the NixOS module's preStart script from the configured `passwordFile`, not by activation-time sed replacement)
- `server` (string, optional): Server hostname to connect to (defaults to JID domain)
- `port` (integer, optional): Server port (defaults to 5222)
- `ssl_verify` (boolean, optional): Whether to verify TLS certificates (defaults to true)
- `muc_rooms` (array of strings, optional): MUC room JIDs to auto-join on startup
- `muc_nick` (string, optional): Nick to use in MUC rooms (defaults to capitalized JID local part)

#### Scenario: Minimal configuration
- **WHEN** config contains only `jid` and `password`
- **THEN** the channel SHALL connect to the JID's domain on port 5222 with TLS verification enabled, use capitalized local part as MUC nick, and join no rooms

#### Scenario: Full configuration
- **WHEN** config contains jid, password, server, port, ssl_verify=false, muc_rooms=["lounge@conference.example.com"], muc_nick="Sid"
- **THEN** the channel SHALL connect to the specified server:port, skip TLS verification, join the listed rooms as "Sid"

#### Scenario: Default muc_nick derivation
- **WHEN** JID is `sid@example.com` and `muc_nick` is not set
- **THEN** the MUC nick SHALL default to "Sid" (local part with first letter capitalized)

### Requirement: NixOS module XMPP options

The NixOS module SHALL provide `services.zeroclaw.channels.xmpp` as a typed submodule. When enabled, the module SHALL:
- Generate `[channels_config.xmpp]` in the base config.toml (without the password)
- Inject the XMPP password from the configured `passwordFile` via the preStart script
- Accept options for `jid`, `server`, `port`, `ssl_verify`, `muc_rooms`, `muc_nick`, and `passwordFile`

#### Scenario: XMPP enabled via module
- **WHEN** `services.zeroclaw.channels.xmpp = { enable = true; jid = "sid@calvelli.dev"; passwordFile = "/run/agenix/xmpp-password"; server = "edge.tailnet.ts.net"; }`
- **THEN** the base config.toml SHALL contain the XMPP section without the password, and the preStart script SHALL inject the password from the file at service start

#### Scenario: XMPP disabled (default)
- **WHEN** `services.zeroclaw.channels.xmpp.enable` is not set or false
- **THEN** no `[channels_config.xmpp]` section SHALL appear in config.toml

### Requirement: XMPP channel feature-gated in Cargo build

The XMPP channel SHALL be gated behind a `channel-xmpp` Cargo feature flag. The feature SHALL be enabled in the fork's `nix/package.nix` build features. When the feature is not enabled, no XMPP-related code SHALL be compiled.

#### Scenario: Build with XMPP feature enabled
- **WHEN** the fork's nix package builds with `channel-xmpp` feature
- **THEN** the XMPP channel code SHALL compile and the channel SHALL be available for configuration

#### Scenario: Build without XMPP feature
- **WHEN** `channel-xmpp` is not in build features
- **THEN** XMPP channel code SHALL not be compiled and `[channels_config.xmpp]` SHALL be ignored

### Requirement: XMPP source lives in fork source tree

The XMPP channel implementation (`xmpp.rs`) SHALL exist as a committed file at `src/channels/xmpp.rs` in the fork's `main` branch. It SHALL NOT be copied from an external location during build. The module declaration and config schema wiring SHALL also be commits on `main`.

#### Scenario: Source file location
- **WHEN** checking out the `main` branch of the fork
- **THEN** `src/channels/xmpp.rs` SHALL exist as a tracked file in the repository
