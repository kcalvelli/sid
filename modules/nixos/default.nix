# Sid NixOS Module
# System-level configuration: sid user, secrets, ZeroClaw service, log-export timer.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.sid;

  # Path to secrets (relative to this module)
  secretsPath = ../../secrets;

  # Workspace and skills source files
  workspaceSrc = ../../workspace;
  skillsSrc = ../../skills;

  # State directory for sid
  stateDir = "/var/lib/sid";
  workspaceDir = "${stateDir}/workspace";
  zeroclawDir = "${stateDir}/.zeroclaw";

  # Secret paths (agenix)
  telegramTokenFile = "/run/agenix/sid-telegram-bot-token";
  emailPasswordFile = "/run/agenix/sid-email-password";
  xmppPasswordFile = "/run/agenix/sid-xmpp-password";
  oauthTokenFile = "/run/agenix/sid-anthropic-oauth-token";
  gatewayTokenFile = "/run/agenix/openclaw-gateway-token";

  # Workspace document files to symlink (read-only, Nix store)
  workspaceFiles = [
    "AGENTS.md"
    "HEARTBEAT.md"
    "IDENTITY.md"
    "SOUL.md"
    "TOOLS.md"
    "USER.md"
  ];

  # Build telegram config section dynamically
  # ZeroClaw: presence of [channels_config.telegram] = enabled; absence = disabled
  telegramConfig = lib.optionalString cfg.telegram.enable ''
    [channels_config.telegram]
    bot_token = "TELEGRAM_TOKEN_PLACEHOLDER"
    allowed_users = [${lib.concatMapStringsSep ", " (id: ''"${toString id}"'') cfg.telegram.allowFrom}]
  '';

  # Build email config section dynamically
  # ZeroClaw: presence of [channels_config.email] = enabled; absence = disabled
  emailConfig = lib.optionalString cfg.email.enable ''
    [channels_config.email]
    imap_host = "london.mxroute.com"
    smtp_host = "london.mxroute.com"
    username = "genxbot@calvelli.us"
    password = "EMAIL_PASSWORD_PLACEHOLDER"
    from_address = "genxbot@calvelli.us"
    allowed_senders = ["*"]
  '';

  # Build XMPP config section dynamically
  # ZeroClaw: presence of [channels_config.xmpp] = enabled; absence = disabled
  xmppConfig = lib.optionalString cfg.xmpp.enable ''
    [channels_config.xmpp]
    jid = "${cfg.xmpp.jid}"
    password = "XMPP_PASSWORD_PLACEHOLDER"
    server = "${cfg.xmpp.server}"
    port = ${toString cfg.xmpp.port}
    ssl_verify = ${lib.boolToString cfg.xmpp.sslVerify}
    muc_rooms = [${lib.concatMapStringsSep ", " (r: ''"${r}"'') cfg.xmpp.mucRooms}]
    muc_nick = "${cfg.xmpp.mucNick}"
  '';

  # ZeroClaw config.toml content
  # api_key is NOT included — subscription auth is used instead
  # (zeroclaw auth paste-token --provider anthropic --profile default --auth-kind authorization)
  configToml = ''
    default_provider = "anthropic"
    default_model = "claude-opus-4-6"
    default_temperature = 0.7

    [agent]
    max_tool_iterations = 30

    [memory]
    backend = "sqlite"
    auto_save = true

    [heartbeat]
    enabled = true
    interval_minutes = 30

    [gateway]
    host = "127.0.0.1"
    port = ${toString cfg.port}
    require_pairing = true
    allow_public_bind = false
    paired_tokens = ["GATEWAY_TOKEN_PLACEHOLDER"]

    [gateway.http.endpoints.chatCompletions]
    enabled = true

    [autonomy]
    level = "full"
    workspace_only = false
    block_high_risk_commands = false
    allowed_commands = ["git", "ls", "cat", "grep", "find", "head", "wc", "date", "df", "jq", "free", "lspci", "uptime", "nproc", "systemctl status", "journalctl", "msmtp", "printf"]
    forbidden_paths = ["/etc", "/root", "/sys", "~/.ssh", "~/.gnupg", "~/.aws"]
    max_actions_per_hour = 60
    max_cost_per_day_cents = 1000

    [channels_config]
    cli = true

    ${telegramConfig}

    ${emailConfig}

    ${xmppConfig}

    [secrets]
    encrypt = true

    [identity]
    format = "openclaw"
  '';
in
{
  options.services.sid = {
    enable = lib.mkEnableOption "Sid AI agent service (ZeroClaw)";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The ZeroClaw package to use";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 18789;
      description = "ZeroClaw gateway port";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall port for the ZeroClaw gateway (allows LAN/Tailnet connections)";
    };

    telegram = {
      enable = lib.mkEnableOption "Telegram channel" // { default = true; };
      dmPolicy = lib.mkOption {
        type = lib.types.enum [ "pairing" "allowlist" "open" "disabled" ];
        default = "pairing";
        description = "DM policy for Telegram channel";
      };
      allowFrom = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [];
        description = "Telegram user IDs allowed to DM the bot (only used with allowlist policy)";
      };
    };

    email = {
      enable = lib.mkEnableOption "Sid email account (genxbot@calvelli.us)";
    };

    xmpp = {
      enable = lib.mkEnableOption "XMPP channel (native Prosody integration)";
      jid = lib.mkOption {
        type = lib.types.str;
        default = "sid@localhost";
        description = "Full JID for the XMPP bot (e.g. sid@example.com)";
      };
      server = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        description = "XMPP server hostname (may differ from JID domain for Tailscale setups)";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 5222;
        description = "XMPP server port (STARTTLS)";
      };
      sslVerify = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Verify TLS certificates (set false for self-signed certs)";
      };
      mucRooms = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "MUC room JIDs to auto-join on startup";
      };
      mucNick = lib.mkOption {
        type = lib.types.str;
        default = "Sid";
        description = "Nick to use in MUC rooms";
      };
    };
  };

  config = lib.mkMerge [
    # Core: sid user, workspace, ZeroClaw service, log-export timer
    (lib.mkIf cfg.enable {
      # ── User ──────────────────────────────────────────────────────────
      # Make zeroclaw CLI available system-wide (for `sudo -u sid zeroclaw ...`)
      environment.systemPackages = [ cfg.package ];

      users.users.sid = {
        isSystemUser = true;
        group = "sid";
        home = stateDir;
        createHome = true;
        shell = "/sbin/nologin";
        description = "Sid AI agent service user";
      };

      users.groups.sid = {};

      # ── Activation: directories, workspace, skills, config ──────────
      system.activationScripts.sid-workspace = lib.stringAfter [ "users" ] ''
        # Create directories
        mkdir -p ${workspaceDir}
        mkdir -p ${zeroclawDir}/workspace
        mkdir -p ${stateDir}/skills
        mkdir -p ${stateDir}/.local/share/sid
        chown -R sid:sid ${stateDir}
        chmod 750 ${stateDir}
        chmod 750 ${workspaceDir}
        chmod 700 ${zeroclawDir}

        # Symlink persona files from Nix store (read-only, immutable)
        # Into both the legacy workspace dir and ZeroClaw's workspace dir
        ${lib.concatMapStringsSep "\n" (file: ''
          ln -sf ${workspaceSrc}/${file} ${workspaceDir}/${file}
          ln -sf ${workspaceSrc}/${file} ${zeroclawDir}/workspace/${file}
        '') workspaceFiles}

        # NOTE: MEMORY.md is NOT managed by Nix — it's writable by the agent.
        # Create in zeroclaw workspace if it doesn't exist (Sid owns this file).
        if [ ! -f ${zeroclawDir}/workspace/MEMORY.md ]; then
          touch ${zeroclawDir}/workspace/MEMORY.md
          chown sid:sid ${zeroclawDir}/workspace/MEMORY.md
        fi

        # Symlink skills from Nix store (read-only)
        # Into both legacy dir and ZeroClaw's workspace/skills dir
        mkdir -p ${zeroclawDir}/workspace/skills
        ln -sfn ${skillsSrc}/cynic ${stateDir}/skills/cynic
        ln -sfn ${skillsSrc}/watchdog ${stateDir}/skills/watchdog
        ln -sfn ${skillsSrc}/email ${stateDir}/skills/email
        ln -sfn ${skillsSrc}/cynic ${zeroclawDir}/workspace/skills/cynic
        ln -sfn ${skillsSrc}/watchdog ${zeroclawDir}/workspace/skills/watchdog
        ln -sfn ${skillsSrc}/email ${zeroclawDir}/workspace/skills/email

        # Write config.toml
        cat > ${zeroclawDir}/config.toml << 'CONFIGEOF'
        ${configToml}
        CONFIGEOF

        # Inject secrets into config.toml from agenix
        if [ -f "${telegramTokenFile}" ]; then
          TELEGRAM_TOKEN="$(cat "${telegramTokenFile}")"
          ${pkgs.gnused}/bin/sed -i "s|TELEGRAM_TOKEN_PLACEHOLDER|$TELEGRAM_TOKEN|g" ${zeroclawDir}/config.toml
        fi
        if [ -f "${gatewayTokenFile}" ]; then
          GATEWAY_TOKEN="$(cat "${gatewayTokenFile}")"
          ${pkgs.gnused}/bin/sed -i "s|GATEWAY_TOKEN_PLACEHOLDER|$GATEWAY_TOKEN|g" ${zeroclawDir}/config.toml
        fi
        if [ -f "${xmppPasswordFile}" ]; then
          XMPP_PASSWORD="$(cat "${xmppPasswordFile}")"
          ${pkgs.gnused}/bin/sed -i "s|XMPP_PASSWORD_PLACEHOLDER|$XMPP_PASSWORD|g" ${zeroclawDir}/config.toml
        fi

        if [ -f "${emailPasswordFile}" ]; then
          EMAIL_PASSWORD="$(cat "${emailPasswordFile}")"
          ${pkgs.gnused}/bin/sed -i "s|EMAIL_PASSWORD_PLACEHOLDER|$EMAIL_PASSWORD|g" ${zeroclawDir}/config.toml

          # Generate .msmtprc for outbound email via shell
          cat > ${stateDir}/.msmtprc << MSMTPEOF
        defaults
        auth on
        tls on
        tls_trust_file /etc/ssl/certs/ca-certificates.crt

        account genxbot
        host london.mxroute.com
        port 465
        tls_starttls off
        from genxbot@calvelli.us
        user genxbot@calvelli.us
        password $EMAIL_PASSWORD

        account default : genxbot
        MSMTPEOF
          chown sid:sid ${stateDir}/.msmtprc
          chmod 0400 ${stateDir}/.msmtprc
        fi

        chown sid:sid ${zeroclawDir}/config.toml
        chmod 0400 ${zeroclawDir}/config.toml

        # Write environment file with OAuth token for Anthropic subscription auth
        if [ -f "${oauthTokenFile}" ]; then
          echo "ANTHROPIC_OAUTH_TOKEN=$(cat ${oauthTokenFile})" > ${zeroclawDir}/env
          chown sid:sid ${zeroclawDir}/env
          chmod 0400 ${zeroclawDir}/env
        fi
      '';

      # ── ZeroClaw service ─────────────────────────────────────────────
      systemd.services.zeroclaw = {
        description = "ZeroClaw agent for Sid";
        after = [ "network-online.target" "postgresql.service" ];
        wants = [ "network-online.target" "postgresql.service" ];
        wantedBy = [ "multi-user.target" ];

        # Tools available to ZeroClaw's shell execution
        # bash is required: ZeroClaw's shell tool runs `sh -c "command"`
        path = with pkgs; [
          bash
          coreutils
          findutils
          git
          gnugrep
          gnused
          gawk
          jq
          msmtp        # outbound email
          procps       # free, uptime, ps
          pciutils     # lspci
          systemd      # systemctl, journalctl
          util-linux   # lscpu, etc.
        ];

        serviceConfig = {
          Type = "simple";
          User = "sid";
          Group = "sid";
          WorkingDirectory = stateDir;
          Restart = "on-failure";
          RestartSec = "10s";
          TimeoutStopSec = "30s";

          # Wait for network to settle (Telegram fails otherwise)
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";

          ExecStart = "${cfg.package}/bin/zeroclaw daemon";

          # Environment
          Environment = [
            "HOME=${stateDir}"
          ];
          EnvironmentFile = "${zeroclawDir}/env";

          # ── Systemd hardening ──────────────────────────────────────
          ProtectHome = "tmpfs";
          ProtectSystem = "strict";
          PrivateTmp = true;
          PrivateDevices = true;
          NoNewPrivileges = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          # Note: ProtectProc/ProcSubset would break cynic skill's /proc reads
          ProtectHostname = true;
          ProtectClock = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          RemoveIPC = true;
          LockPersonality = true;

          # Filesystem — only state dir is writable
          ReadWritePaths = [ stateDir ];

          # Capabilities
          CapabilityBoundingSet = "";
          AmbientCapabilities = "";

          # Network
          RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
          IPAddressDeny = "multicast";

          # System calls
          SystemCallFilter = [ "@system-service" ];
          SystemCallArchitectures = "native";

          # Namespaces
          RestrictNamespaces = true;

          # File permissions
          UMask = "0027";
        };
      };

      # ── Log export service (runs as root for journalctl access) ─────
      systemd.services.sid-log-export = {
        description = "Collect system logs for Sid watchdog";
        after = [ "systemd-journald.service" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "sid-log-export" ''
            set -euo pipefail
            LOGFILE="${stateDir}/.local/share/sid/watchdog.log"

            # Collect last 24 hours of relevant logs
            # Priority 0-4: emergency, alert, critical, error, warning
            {
              # Kernel messages (hardware errors, thermal, etc.)
              ${pkgs.systemd}/bin/journalctl \
                --since "24 hours ago" \
                --no-pager \
                --output=short-iso \
                -p 0..4 \
                -k 2>/dev/null || true

              # Thermal daemon
              ${pkgs.systemd}/bin/journalctl \
                --since "24 hours ago" \
                --no-pager \
                --output=short-iso \
                -u thermald.service 2>/dev/null || true

              # SMART disk monitoring
              ${pkgs.systemd}/bin/journalctl \
                --since "24 hours ago" \
                --no-pager \
                --output=short-iso \
                -u smartd.service 2>/dev/null || true
            } | sort -u > "$LOGFILE.tmp"

            # Also capture failed units
            ${pkgs.systemd}/bin/systemctl list-units --failed --no-legend --no-pager \
              >> "$LOGFILE.tmp" 2>/dev/null || true

            # Atomically replace the log file
            mv "$LOGFILE.tmp" "$LOGFILE"
            chown sid:sid "$LOGFILE"
            chmod 640 "$LOGFILE"
          '';
        };
      };

      # ── Log export timer ────────────────────────────────────────────
      systemd.timers.sid-log-export = {
        description = "Update Sid watchdog log periodically";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "15min";
          Unit = "sid-log-export.service";
        };
      };
    })

    # ── PostgreSQL database ───────────────────────────────────────────────
    (lib.mkIf cfg.enable {
      services.postgresql = {
        ensureDatabases = [ "sid" ];
        ensureUsers = [{
          name = "sid";
          ensureDBOwnership = true;
        }];
      };
    })

    # ── Firewall ────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.openFirewall) {
      networking.firewall.allowedTCPPorts = [ cfg.port ];
    })

    # ── Anthropic OAuth token (subscription auth) ────────────────────────
    (lib.mkIf cfg.enable {
      age.secrets.sid-anthropic-oauth-token = {
        file = secretsPath + /anthropic-oauth-token.age;
        owner = "sid";
        group = "sid";
        mode = "0400";
      };
    })

    # ── Telegram secret ─────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.telegram.enable) {
      age.secrets.sid-telegram-bot-token = {
        file = secretsPath + /telegram-bot-token.age;
        owner = "sid";
        group = "sid";
        mode = "0400";
      };
    })

    # ── Email secret ────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.email.enable) {
      age.secrets.sid-email-password = {
        file = secretsPath + /genxbot-email-password.age;
        owner = "sid";
        group = "users";
        mode = "0440";
      };
    })

    # ── XMPP secret ──────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.xmpp.enable) {
      age.secrets.sid-xmpp-password = {
        file = secretsPath + /xmpp-password.age;
        owner = "sid";
        group = "sid";
        mode = "0400";
      };
    })
  ];
}
