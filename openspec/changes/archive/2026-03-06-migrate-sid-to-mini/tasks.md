## Tasks

### Phase 0: Agenix Setup

- [x] Get mini's ed25519 host key
- [x] Add mini host key to `~/.config/nixos_config/secrets/secrets.nix`
- [x] Add mini host key to `/home/keith/Projects/sid/secrets/secrets.nix`
- [x] Add mini host key to axios-chat secrets (uses nixos_config's — no separate file)
- [x] Re-key: nixos_config secrets
- [x] Re-key: sid secrets (required `sudo agenix -r -i /etc/ssh/ssh_host_ed25519_key`)
- [x] Re-key axios-chat secrets (N/A — shares nixos_config)

### Phase 1: Configure mini

- [x] Add `inputs.sid.nixosModules.default` to mini.nix imports
- [x] Add `inputs.axios-chat.nixosModules.default` to mini.nix imports
- [x] Add `services.sid` config block to mini.nix (copy from edge.nix, keep `xmpp.server = "127.0.0.1"`)
- [x] Add `services.axios-chat.prosody` config block to mini.nix (copy from edge.nix, update `http_external_url` to `mini.taile0fb4.ts.net`)
- [x] Declare `openclaw-gateway-token` secret for mini (currently only in edge.nix)
- [x] Declare `xmpp-bot-password` secret for mini
- [x] Verify all sid `age.secrets.sid-*` entries will resolve on mini (the module handles these, but confirm paths)

### Phase 2: Migrate State

- [x] Deploy mini config first (creates `sid` user and directories): `nix flake lock --update-input sid && nixos-rebuild switch --flake .#mini --target-host mini`
- [x] Stop zeroclaw on edge: `systemctl stop zeroclaw`
- [x] Copy Sid state: `rsync -a /var/lib/sid/.zeroclaw/workspace/MEMORY.md mini:/var/lib/sid/.zeroclaw/workspace/`
- [x] Copy Sid brain: `rsync -a /var/lib/sid/.zeroclaw/workspace/memory/ mini:/var/lib/sid/.zeroclaw/workspace/memory/`
- [x] Stop prosody on edge: `systemctl stop prosody`
- [x] Copy Prosody data: `rsync -a /var/lib/prosody/ mini:/var/lib/prosody/`
- [x] Fix ownership on mini: `ssh mini 'chown -R prosody:prosody /var/lib/prosody && chown -R sid:sid /var/lib/sid/.zeroclaw/workspace/MEMORY.md /var/lib/sid/.zeroclaw/workspace/memory/'`

### Phase 3: Cutover (off-hours)

- [x] Disable on edge: set `services.sid.enable = false`, `services.axios-chat.prosody.enable = false`, remove Tailscale Serve XMPP stanzas
- [x] Rebuild edge: `nixos-rebuild switch --flake .#edge`
- [x] Restart services on mini: `ssh mini 'systemctl restart zeroclaw prosody'`
- [x] Verify Tailscale Serve `svc:chat` is now served from mini

### Phase 4: Verify

- [x] Sid responds on Telegram
- [x] Sid receives/sends email (genxbot@calvelli.us)
- [x] XMPP: connect to `chat.taile0fb4.ts.net`, verify Sid is in `xojabo` MUC
- [x] Gateway: `curl http://mini:18789/health` (or equivalent)
- [x] Watchdog: check `/var/lib/sid/.local/share/sid/watchdog.log` reports mini's hardware
- [x] Heartbeat: wait 30 minutes, confirm Sid's heartbeat fires
- [x] Memory: verify Sid can write to MEMORY.md
- [x] Prosody: verify file uploads work via `upload.chat.taile0fb4.ts.net`

### Gotchas Checklist

- [x] Tailscale Serve `svc:chat` — cannot be active on both hosts simultaneously. Disable on edge before enabling on mini.
- [x] HTTP file upload URL — old files referenced as `edge.taile0fb4.ts.net:5281` will 404. New uploads use `mini.taile0fb4.ts.net:5281`. Accept this.
- [x] PostgreSQL will start on mini (sid module unconditionally enables it). Accept for now, fix in separate change.
- [x] Telegram bot token + IMAP IDLE are singletons — brief outage window is expected and acceptable.
