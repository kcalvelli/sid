# Sid Secrets - Public keys for encrypting secrets
# These secrets are encrypted to the edge system key ONLY (not user keys)
# This allows the sid service user to access them without keith's involvement
let
  # Host keys (system-level secrets)
  edge = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGvQUtoVPpz55MpZD0UtGTnKnCoYNGt6FALef35Fuqpn root@edge";
  mini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK5NzQ6gGjVFkJFs91CXhauh5fVQ8cP22Kkmda1GOpJ+ root@mini";
  # User key for keith (allows editing secrets locally)
  keith = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEInNA9NVvfOCjJVO4KwwcqjTk2lwdXgZqKvQJ1N1ntH keith@edge";
in
{
  # Telegram bot token for messaging channel
  "telegram-bot-token.age".publicKeys = [
    edge
    mini
  ];

  # Email password for genxbot@calvelli.us
  "genxbot-email-password.age".publicKeys = [
    edge
    mini
  ];

  # Anthropic OAuth setup token (Claude subscription auth)
  "anthropic-oauth-token.age".publicKeys = [
    edge
    mini
    keith
  ];

  # XMPP password for sid@chat.taile0fb4.ts.net (Prosody)
  "xmpp-password.age".publicKeys = [
    edge
    mini
    keith
  ];

  # GitHub PAT for sid-workspace repo (workspace file management)
  "github-pat.age".publicKeys = [
    mini
    keith
  ];

  # Grok API key
  "xai-api-key.age".publicKeys = [
    edge
    mini
    keith
  ];

  # Pushover push notification credentials
  "pushover-user-key.age".publicKeys = [
    edge
    mini
    keith
  ];

  "pushover-api-token.age".publicKeys = [
    edge
    mini
    keith
  ];

  "elevenlabs-api-token.age".publicKeys = [
    edge
    mini
    keith
  ];

  "deepgram-api-token.age".publicKeys = [
    edge
    mini
    keith
  ];

}
