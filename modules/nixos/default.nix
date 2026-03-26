# Sid NixOS Module
# System-level configuration: sid user, secrets, ZeroClaw service, log-export timer.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.sid;

  # Path to secrets (relative to this module)
  secretsPath = ../../secrets;

  # State directory for sid
  stateDir = "/var/lib/sid";
  zeroclawDir = "${stateDir}/.zeroclaw";

  # Secret paths (agenix)
  telegramTokenFile = "/run/agenix/sid-telegram-bot-token";
  emailPasswordFile = "/run/agenix/sid-email-password";
  xmppPasswordFile = "/run/agenix/sid-xmpp-password";
  oauthTokenFile = "/run/agenix/sid-anthropic-oauth-token";
  xaiApiKeyFile = "/run/agenix/sid-xai-api-key";
  gatewayTokenFile = "/run/agenix/openclaw-gateway-token";
  githubPatFile = "/run/agenix/sid-github-pat";
  pushoverUserKeyFile = "/run/agenix/sid-pushover-user-key";
  pushoverApiTokenFile = "/run/agenix/sid-pushover-api-token";
  elevenlabsApiTokenFile = "/run/agenix/sid-elevenlabs-api-token";
  deepgramApiTokenFile = "/run/agenix/sid-deepgram-api-token";

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
  configToml = ''
    default_provider = "claude-code"
    default_model = "claude-opus-4-6"
    default_temperature = 0.7
    parallel_tools = true

    [agent]
    max_tool_iterations = 25

    [data_retention]
    enabled = true
    max_age_days = 90

    [reliability]
    fallback_providers = ["anthropic"]

    [memory]
    backend = "sqlite"
    auto_save = true
    search_mode = "bm25"
    response_cache_enabled = true
    response_cache_ttl_minutes = 60

    [heartbeat]
    enabled = false
    interval_minutes = 120

    [gateway]
    host = "0.0.0.0"
    port = ${toString cfg.port}
    require_pairing = true
    allow_public_bind = true
    paired_tokens = ["GATEWAY_TOKEN_PLACEHOLDER"]

    [gateway.http.endpoints.chatCompletions]
    enabled = true

    [cost]
    enabled = true
    daily_limit_usd = 5.0
    monthly_limit_usd = 100.0
    warn_at_percent = 80

    [cost.prices."anthropic/claude-opus-4-6"]
    input = 15.0
    output = 75.0

    [cost.prices."anthropic/claude-haiku-4-5"]
    input = 0.80
    output = 4.0

    [cost.prices."anthropic/claude-sonnet-4-6"]
    input = 3.0
    output = 15.0

    [cost.prices."openai/gpt-4.1"]
    input = 0.0
    output = 0.0

    [tts]
    enabled = true
    default_provider = "elevenlabs"
    default_voice = "ehKyeiSCZukmLY5dPNRm"
    default_format = "mp3"

    [tts.elevenlabs]
    api_key = "ELEVENLABS_API_TOKEN_PLACEHOLDER"
    model_id = "eleven_monolingual_v1"
    stability = 0.5
    similarity_boost = 0.5

    [transcription]
    enabled = true
    default_provider = "deepgram"

    [transcription.deepgram]
    api_key = "DEEPGRAM_API_TOKEN_PLACEHOLDER"

    [autonomy]
    level = "full"
    workspace_only = false
    block_high_risk_commands = false
    allowed_commands = ["*"]
    forbidden_paths = ["/root"]
    max_actions_per_hour = 100
    max_cost_per_day_cents = 500

    [channels_config]
    cli = true
    show_tool_calls = false
    session_ttl_hours = 720

    ${telegramConfig}

    ${emailConfig}

    ${xmppConfig}

    [web_fetch]
    enabled = true
    allowed_domains = ["*"]

    [secrets]
    encrypt = true

    [identity]
    format = "openclaw"

    [project_intel]
    enabled = true

    [[model_routes]]
    hint = "cost-optimized"
    provider = "anthropic"
    model = "claude-haiku-4-5"

    [[model_routes]]
    hint = "reasoning"
    provider = "anthropic"
    model = "claude-opus-4-6"

    [agents.worker]
    provider = "anthropic"
    model = "claude-haiku-4-5"
    api_key = "ANTHROPIC_API_KEY_PLACEHOLDER"
    max_tokens = 2048
    agentic = true
    temperature = 0.3
    timeout_secs = 120
    system_prompt = "You are a task executor for Sid, an AI assistant. Execute the requested task precisely. Return structured results. Do not add commentary or personality."

    [agents.researcher]
    provider = "anthropic"
    model = "claude-sonnet-4-6"
    api_key = "ANTHROPIC_API_KEY_PLACEHOLDER"
    max_tokens = 8192
    agentic = true
    temperature = 0.5
    timeout_secs = 180
    system_prompt = "You are a research and judgment agent for Sid, a cynical Gen X AI assistant. When producing user-facing content, write in Sid's voice — dry, world-weary, reluctantly competent. For internal tasks, be precise and structured."

    [swarms.briefing]
    agents = ["researcher", "worker"]
    strategy = "sequential"
    timeout_secs = 300
    description = "Research then execute pipeline — researcher gathers and analyzes, worker acts on findings"

    [swarms.data-gather]
    agents = ["worker"]
    strategy = "sequential"
    timeout_secs = 120
    description = "Single-agent data gathering — fetch and return structured data"
  '';
in
{
  options.services.sid = {
    enable = lib.mkEnableOption "Sid AI agent service (ZeroClaw)";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The ZeroClaw package to use";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extra packages to add to the ZeroClaw service PATH";
    };

    mcpGatewayUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "MCP Gateway URL for mcp-gw CLI (wraps mcp-gw with baked-in URL)";
    };

    mcpGatewayPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "The mcp-gateway package providing mcp-gw CLI";
    };

    zeroclawMcpPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "The zeroclaw-mcp package (MCP server bridging gateway tools to Claude Code)";
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

    postgres = {
      enable = lib.mkEnableOption "PostgreSQL database for Sid (not needed when using SQLite memory backend)";
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
        extraGroups = [ "systemd-journal" ];
        home = stateDir;
        createHome = true;
        shell = "/sbin/nologin";
        description = "Sid AI agent service user";
      };

      users.groups.sid = {};

      # ── Activation: directories, workspace (git), config ────────────
      system.activationScripts.sid-workspace = lib.stringAfter [ "users" ] ''
        # Create directories
        mkdir -p ${zeroclawDir}
        mkdir -p ${stateDir}/.local/share/sid
        chown -R sid:sid ${stateDir}
        chmod 750 ${stateDir}
        chmod 700 ${zeroclawDir}

        # Workspace: clone from GitHub on first deploy, never touch again
        # Sid owns these files — all workspace content lives in his repo
        # Helper: run git with safe.directory override (activation runs as root, repo owned by sid)
        sid_git() { ${pkgs.git}/bin/git -c safe.directory=${zeroclawDir}/workspace "$@"; }

        if [ ! -d ${zeroclawDir}/workspace/.git ]; then
          # Remove any legacy symlinks/files from previous Nix-managed workspace
          rm -rf ${zeroclawDir}/workspace

          if [ -f "${githubPatFile}" ]; then
            GITHUB_TOKEN="$(cat "${githubPatFile}")"
            sid_git clone \
              https://x-access-token:''${GITHUB_TOKEN}@github.com/kcalvelli/sid-workspace.git \
              ${zeroclawDir}/workspace
            chown -R sid:sid ${zeroclawDir}/workspace
          else
            echo "WARNING: GitHub PAT not available, cannot clone workspace repo"
            mkdir -p ${zeroclawDir}/workspace
            chown -R sid:sid ${zeroclawDir}/workspace
          fi
        else
          # Repo exists — update remote URL with current token (supports rotation)
          if [ -f "${githubPatFile}" ]; then
            GITHUB_TOKEN="$(cat "${githubPatFile}")"
            sid_git -C ${zeroclawDir}/workspace remote set-url origin \
              https://x-access-token:''${GITHUB_TOKEN}@github.com/kcalvelli/sid-workspace.git
          fi
        fi

        # Ensure SOP directory exists
        mkdir -p ${zeroclawDir}/workspace/sops
        chown sid:sid ${zeroclawDir}/workspace/sops

        # Git identity for commits
        sid_git -C ${zeroclawDir}/workspace config user.name "Sid"
        sid_git -C ${zeroclawDir}/workspace config user.email "genxbot@calvelli.us"

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

        if [ -f "${elevenlabsApiTokenFile}" ]; then
          ELEVENLABS_TOKEN="$(cat "${elevenlabsApiTokenFile}")"
          ${pkgs.gnused}/bin/sed -i "s|ELEVENLABS_API_TOKEN_PLACEHOLDER|$ELEVENLABS_TOKEN|g" ${zeroclawDir}/config.toml
        fi

        if [ -f "${deepgramApiTokenFile}" ]; then
          DEEPGRAM_TOKEN="$(cat "${deepgramApiTokenFile}")"
          ${pkgs.gnused}/bin/sed -i "s|DEEPGRAM_API_TOKEN_PLACEHOLDER|$DEEPGRAM_TOKEN|g" ${zeroclawDir}/config.toml
        fi

        if [ -f "${oauthTokenFile}" ]; then
          ANTHROPIC_KEY="$(cat "${oauthTokenFile}")"
          ${pkgs.gnused}/bin/sed -i "s|ANTHROPIC_API_KEY_PLACEHOLDER|$ANTHROPIC_KEY|g" ${zeroclawDir}/config.toml
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

        # Write workspace .env for tools that read credentials from it (e.g. pushover)
        {
          if [ -f "${pushoverUserKeyFile}" ]; then
            echo "PUSHOVER_USER_KEY=$(cat ${pushoverUserKeyFile})"
          fi
          if [ -f "${pushoverApiTokenFile}" ]; then
            echo "PUSHOVER_TOKEN=$(cat ${pushoverApiTokenFile})"
          fi
        } > ${zeroclawDir}/workspace/.env
        chown sid:sid ${zeroclawDir}/workspace/.env
        chmod 0400 ${zeroclawDir}/workspace/.env

        # Write environment file with API keys
        {
          if [ -f "${xaiApiKeyFile}" ]; then
            echo "XAI_API_KEY=$(cat ${xaiApiKeyFile})"
          fi
          if [ -f "${oauthTokenFile}" ]; then
            echo "ANTHROPIC_OAUTH_TOKEN=$(cat ${oauthTokenFile})"
          fi
          if [ -f "${githubPatFile}" ]; then
            echo "SID_GITHUB_TOKEN=$(cat ${githubPatFile})"
          fi
          # ZeroClaw MCP server env vars
          echo "ZEROCLAW_GATEWAY_URL=http://127.0.0.1:${toString cfg.port}"
          if [ -f "${gatewayTokenFile}" ]; then
            echo "ZEROCLAW_GATEWAY_TOKEN=$(cat ${gatewayTokenFile})"
          fi
          ${lib.optionalString cfg.xmpp.enable ''
          echo "XMPP_JID=${cfg.xmpp.jid}"
          if [ -f "${xmppPasswordFile}" ]; then
            echo "XMPP_PASSWORD=$(cat ${xmppPasswordFile})"
          fi
          echo "XMPP_HOST=${cfg.xmpp.server}"
          echo "XMPP_PORT=${toString cfg.xmpp.port}"
          ''}
          if [ -f "${pushoverUserKeyFile}" ]; then
            echo "PUSHOVER_USER_KEY=$(cat ${pushoverUserKeyFile})"
          fi
          if [ -f "${pushoverApiTokenFile}" ]; then
            echo "PUSHOVER_API_TOKEN=$(cat ${pushoverApiTokenFile})"
          fi
        } > ${zeroclawDir}/env
        chown sid:sid ${zeroclawDir}/env
        chmod 0400 ${zeroclawDir}/env
      '';

      # ── ZeroClaw service ─────────────────────────────────────────────
      systemd.services.zeroclaw = {
        description = "ZeroClaw agent for Sid";
        after = [ "network-online.target" ] ++ lib.optional cfg.postgres.enable "postgresql.service";
        wants = [ "network-online.target" ] ++ lib.optional cfg.postgres.enable "postgresql.service";
        wantedBy = [ "multi-user.target" ];

        # Tools available to ZeroClaw's shell execution
        # bash is required: ZeroClaw's shell tool runs `sh -c "command"`
        path = (with pkgs; [
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
          curl         # HTTP requests
          python3      # scripting
          gnutar       # archives
          gzip         # compression
          inetutils    # ping
          dnsutils     # dig, nslookup
          file         # file type detection
          tree         # directory listing
          claude-code  # Claude Code CLI (fallback provider)
        ]) ++ cfg.extraPackages
           ++ lib.optional (cfg.mcpGatewayPackage != null) (
             if cfg.mcpGatewayUrl != null then
               # Wrapper with baked-in URL (ZeroClaw sanitizes env from subprocesses)
               pkgs.writeShellScriptBin "mcp-gw" ''
                 export MCP_GATEWAY_URL=${lib.escapeShellArg cfg.mcpGatewayUrl}
                 exec ${cfg.mcpGatewayPackage}/bin/mcp-gw "$@"
               ''
             else
               cfg.mcpGatewayPackage
           )
           # ZeroClaw MCP server — wrapper bakes in env vars (ZeroClaw sanitizes env)
           ++ lib.optional (cfg.zeroclawMcpPackage != null) (
             pkgs.writeShellScriptBin "zeroclaw-mcp" ''
               # Source env file for gateway token and credentials
               if [ -f ${zeroclawDir}/env ]; then
                 set -a
                 . ${zeroclawDir}/env
                 set +a
               fi
               exec ${cfg.zeroclawMcpPackage}/bin/zeroclaw-mcp "$@"
             ''
           );

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
            "SHELL=${pkgs.bash}/bin/bash"
            "ZEROCLAW_GATEWAY_TIMEOUT_SECS=120"
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
          # Note: ProtectProc/ProcSubset would break /proc reads
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



      # ── Workspace git push (hourly sync to GitHub) ──────────────────
      systemd.services.sid-workspace-push = {
        description = "Push Sid workspace changes to GitHub";
        serviceConfig = {
          Type = "oneshot";
          User = "sid";
          Group = "sid";
          ExecStart = pkgs.writeShellScript "sid-workspace-push" ''
            cd ${zeroclawDir}/workspace
            if [ -n "$(${pkgs.git}/bin/git status --porcelain)" ]; then
              ${pkgs.git}/bin/git add -A
              ${pkgs.git}/bin/git commit -m "auto: sync uncommitted workspace changes"
            fi
            ${pkgs.git}/bin/git push --quiet 2>/dev/null || true
          '';
        };
      };

      systemd.timers.sid-workspace-push = {
        description = "Push Sid workspace to GitHub hourly";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "10min";
          OnUnitActiveSec = "1h";
          Unit = "sid-workspace-push.service";
        };
      };
    })

    # ── PostgreSQL database (optional — only if postgres memory backend is used) ──
    (lib.mkIf (cfg.enable && cfg.postgres.enable) {
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

    # ── xAI API key ────────────────────────────────────────────────────
    (lib.mkIf cfg.enable {
      age.secrets.sid-xai-api-key = {
        file = secretsPath + /xai-api-key.age;
        owner = "sid";
        group = "sid";
        mode = "0400";
      };
    })

    # ── Anthropic OAuth token (kept for fallback) ──────────────────────
    (lib.mkIf cfg.enable {
      age.secrets.sid-anthropic-oauth-token = {
        file = secretsPath + /anthropic-oauth-token.age;
        owner = "sid";
        group = "sid";
        mode = "0400";
      };
    })

    # ── GitHub PAT for workspace repo ──────────────────────────────────
    (lib.mkIf cfg.enable {
      age.secrets.sid-github-pat = {
        file = secretsPath + /github-pat.age;
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

    # ── Pushover secrets (optional — only if .age files exist) ─────
    (lib.mkIf (cfg.enable && builtins.pathExists (secretsPath + /pushover-user-key.age)) {
      age.secrets.sid-pushover-user-key = {
        file = secretsPath + /pushover-user-key.age;
        owner = "sid";
        group = "sid";
        mode = "0400";
      };
    })

    (lib.mkIf (cfg.enable && builtins.pathExists (secretsPath + /pushover-api-token.age)) {
      age.secrets.sid-pushover-api-token = {
        file = secretsPath + /pushover-api-token.age;
        owner = "sid";
        group = "sid";
        mode = "0400";
      };
    })

    # ── ElevenLabs TTS API token ─────────────────────────────────────
    (lib.mkIf (cfg.enable && builtins.pathExists (secretsPath + /elevenlabs-api-token.age)) {
      age.secrets.sid-elevenlabs-api-token = {
        file = secretsPath + /elevenlabs-api-token.age;
        owner = "sid";
        group = "sid";
        mode = "0400";
      };
    })

    # ── Deepgram STT API token ───────────────────────────────────────
    (lib.mkIf (cfg.enable && builtins.pathExists (secretsPath + /deepgram-api-token.age)) {
      age.secrets.sid-deepgram-api-token = {
        file = secretsPath + /deepgram-api-token.age;
        owner = "sid";
        group = "sid";
        mode = "0400";
      };
    })
  ];
}
