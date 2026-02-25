# Sid Secrets - Public keys for encrypting secrets
# These secrets are encrypted to the edge system key ONLY (not user keys)
# This allows the sid service user to access them without keith's involvement
let
  # Host key for edge system (system-level secrets)
  edge = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGvQUtoVPpz55MpZD0UtGTnKnCoYNGt6FALef35Fuqpn root@edge";
  # User key for keith (allows editing secrets locally)
  keith = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEInNA9NVvfOCjJVO4KwwcqjTk2lwdXgZqKvQJ1N1ntH keith@edge";
in
{
  # Telegram bot token for messaging channel
  "telegram-bot-token.age".publicKeys = [ edge ];

  # Email password for genxbot@calvelli.us
  "genxbot-email-password.age".publicKeys = [ edge ];

  # Anthropic OAuth setup token (Claude subscription auth)
  "anthropic-oauth-token.age".publicKeys = [ edge ];

  # XMPP password for sid@chat.taile0fb4.ts.net (Prosody)
  "xmpp-password.age".publicKeys = [ edge keith ];
}
