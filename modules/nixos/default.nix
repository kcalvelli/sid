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
  telegramConfig = if cfg.telegram.enable then ''
    [channels_config.telegram]
    enabled = true
    token = "TELEGRAM_TOKEN_PLACEHOLDER"
    dm_policy = "${cfg.telegram.dmPolicy}"
  '' + lib.optionalString (cfg.telegram.dmPolicy == "allowlist" && cfg.telegram.allowFrom != []) ''
    allow_from = [${lib.concatMapStringsSep ", " toString cfg.telegram.allowFrom}]
  ''
  else ''
    [channels_config.telegram]
    enabled = false
  '';

  # ZeroClaw config.toml content
  # api_key is NOT included — subscription auth is used instead
  # (zeroclaw auth paste-token --provider anthropic --profile default --auth-kind authorization)
  configToml = ''
    default_provider = "anthropic"
    default_model = "claude-opus-4-5"

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

    [gateway.http.endpoints.chatCompletions]
    enabled = true

    [autonomy]
    level = "supervised"
    workspace_only = true
    allowed_commands = ["git", "ls", "cat", "grep", "find", "jq", "systemctl status", "journalctl"]
    forbidden_paths = ["/etc", "/root", "/proc", "/sys", "~/.ssh", "~/.gnupg", "~/.aws"]
    max_actions_per_hour = 60
    max_cost_per_day_cents = 1000

    ${telegramConfig}

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
  };

  config = lib.mkMerge [
    # Core: sid user, workspace, ZeroClaw service, log-export timer
    (lib.mkIf cfg.enable {
      # ── User ──────────────────────────────────────────────────────────
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
        mkdir -p ${zeroclawDir}
        mkdir -p ${stateDir}/skills
        mkdir -p ${stateDir}/.local/share/sid
        chown -R sid:sid ${stateDir}
        chmod 750 ${stateDir}
        chmod 750 ${workspaceDir}
        chmod 700 ${zeroclawDir}

        # Symlink persona files from Nix store (read-only, immutable)
        ${lib.concatMapStringsSep "\n" (file: ''
          ln -sf ${workspaceSrc}/${file} ${workspaceDir}/${file}
        '') workspaceFiles}

        # NOTE: MEMORY.md is NOT managed by Nix.
        # It must be copied in manually at deploy time from the live GenX64 instance:
        #   cp /var/lib/genxbot/workspace/MEMORY.md /var/lib/sid/workspace/MEMORY.md
        #   chown sid:sid /var/lib/sid/workspace/MEMORY.md

        # Symlink skills from Nix store (read-only)
        ln -sfn ${skillsSrc}/cynic ${stateDir}/skills/cynic
        ln -sfn ${skillsSrc}/watchdog ${stateDir}/skills/watchdog
        ln -sfn ${skillsSrc}/email ${stateDir}/skills/email

        # Write config.toml
        cat > ${zeroclawDir}/config.toml << 'CONFIGEOF'
        ${configToml}
        CONFIGEOF

        # Inject Telegram bot token from agenix secret
        if [ -f "${telegramTokenFile}" ]; then
          TELEGRAM_TOKEN="$(cat "${telegramTokenFile}")"
          ${pkgs.gnused}/bin/sed -i "s|TELEGRAM_TOKEN_PLACEHOLDER|$TELEGRAM_TOKEN|g" ${zeroclawDir}/config.toml
        fi

        chown sid:sid ${zeroclawDir}/config.toml
        chmod 0400 ${zeroclawDir}/config.toml
      '';

      # ── ZeroClaw service ─────────────────────────────────────────────
      systemd.services.zeroclaw = {
        description = "ZeroClaw agent for Sid";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

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

          ExecStart = "${cfg.package}/bin/zeroclaw agent";

          # Environment
          Environment = [
            "HOME=${stateDir}"
          ];

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

    # ── Firewall ────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.openFirewall) {
      networking.firewall.allowedTCPPorts = [ cfg.port ];
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
        group = "sid";
        mode = "0400";
      };
    })
  ];
}
