## Tasks

### Phase 0: Agenix Setup

- [ ] Get mini's ed25519 host key (`cat /etc/ssh/ssh_host_ed25519_key.pub` on mini)
- [ ] Add mini host key to `~/.config/nixos_config/secrets/secrets.nix` — uncomment mini from all secret declarations
- [ ] Add mini host key to `/home/keith/Projects/sid/secrets/secrets.nix` — add to all 4 secret declarations
- [ ] Add mini host key to axios-chat secrets if separate (verify whether axios-chat has its own `secrets.nix` or uses nixos_config's)
- [ ] Re-key: `cd ~/.config/nixos_config/secrets && agenix -r`
- [ ] Re-key: `cd ~/Projects/sid/secrets && agenix -r`
- [ ] Re-key axios-chat secrets if applicable

### Phase 1: Configure mini

- [ ] Add `inputs.sid.nixosModules.default` to mini.nix imports
- [ ] Add `inputs.axios-chat.nixosModules.default` to mini.nix imports
- [ ] Add `services.sid` config block to mini.nix (copy from edge.nix, keep `xmpp.server = "127.0.0.1"`)
- [ ] Add `services.axios-chat.prosody` config block to mini.nix (copy from edge.nix, update `http_external_url` to `mini.taile0fb4.ts.net`)
- [ ] Declare `openclaw-gateway-token` secret for mini (currently only in edge.nix)
- [ ] Declare `xmpp-bot-password` secret for mini
- [ ] Verify all sid `age.secrets.sid-*` entries will resolve on mini (the module handles these, but confirm paths)

### Phase 2: Migrate State

- [ ] Deploy mini config first (creates `sid` user and directories): `nix flake lock --update-input sid && nixos-rebuild switch --flake .#mini --target-host mini`
- [ ] Stop zeroclaw on edge: `systemctl stop zeroclaw`
- [ ] Copy Sid state: `rsync -a /var/lib/sid/.zeroclaw/workspace/MEMORY.md mini:/var/lib/sid/.zeroclaw/workspace/`
- [ ] Copy Sid brain: `rsync -a /var/lib/sid/.zeroclaw/workspace/memory/ mini:/var/lib/sid/.zeroclaw/workspace/memory/`
- [ ] Stop prosody on edge: `systemctl stop prosody`
- [ ] Copy Prosody data: `rsync -a /var/lib/prosody/ mini:/var/lib/prosody/`
- [ ] Fix ownership on mini: `ssh mini 'chown -R prosody:prosody /var/lib/prosody && chown -R sid:sid /var/lib/sid/.zeroclaw/workspace/MEMORY.md /var/lib/sid/.zeroclaw/workspace/memory/'`

### Phase 3: Cutover (off-hours)

- [ ] Disable on edge: set `services.sid.enable = false`, `services.axios-chat.prosody.enable = false`, remove Tailscale Serve XMPP stanzas
- [ ] Rebuild edge: `nixos-rebuild switch --flake .#edge`
- [ ] Restart services on mini: `ssh mini 'systemctl restart zeroclaw prosody'`
- [ ] Verify Tailscale Serve `svc:chat` is now served from mini

### Phase 4: Verify

- [ ] Sid responds on Telegram
- [ ] Sid receives/sends email (genxbot@calvelli.us)
- [ ] XMPP: connect to `chat.taile0fb4.ts.net`, verify Sid is in `xojabo` MUC
- [ ] Gateway: `curl http://mini:18789/health` (or equivalent)
- [ ] Watchdog: check `/var/lib/sid/.local/share/sid/watchdog.log` reports mini's hardware
- [ ] Heartbeat: wait 30 minutes, confirm Sid's heartbeat fires
- [ ] Memory: verify Sid can write to MEMORY.md
- [ ] Prosody: verify file uploads work via `upload.chat.taile0fb4.ts.net`

### Gotchas Checklist

- [ ] Tailscale Serve `svc:chat` — cannot be active on both hosts simultaneously. Disable on edge before enabling on mini.
- [ ] HTTP file upload URL — old files referenced as `edge.taile0fb4.ts.net:5281` will 404. New uploads use `mini.taile0fb4.ts.net:5281`. Accept this.
- [ ] PostgreSQL will start on mini (sid module unconditionally enables it). Accept for now, fix in separate change.
- [ ] Telegram bot token + IMAP IDLE are singletons — brief outage window is expected and acceptable.
