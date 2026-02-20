# Sid Secrets - Public keys for encrypting secrets
# These secrets are encrypted to the edge system key ONLY (not user keys)
# This allows the sid service user to access them without keith's involvement
let
  # Host key for edge system (system-level secrets)
  edge = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGvQUtoVPpz55MpZD0UtGTnKnCoYNGt6FALef35Fuqpn root@edge";
in
{
  # Telegram bot token for messaging channel
  "telegram-bot-token.age".publicKeys = [ edge ];

  # Email password for genxbot@calvelli.us
  "genxbot-email-password.age".publicKeys = [ edge ];
}
