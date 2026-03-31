# Sid NixOS Configuration
# Thin config that sets option values on the zeroclaw-nix module.
# The module itself (options, systemd service, hardening) lives in the fork.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.sid;

  secretsPath = ../../secrets;
  stateDir = "/var/lib/sid";
  zeroclawDir = "${stateDir}/.zeroclaw";

  # Agenix secret paths
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
      description = "MCP Gateway URL for mcp-gw CLI";
    };

    mcpGatewayPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "The mcp-gateway package providing mcp-gw CLI";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 18789;
      description = "ZeroClaw gateway port";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall port for the ZeroClaw gateway";
    };

    telegram = {
      enable = lib.mkEnableOption "Telegram channel" // { default = true; };
      allowFrom = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [];
        description = "Telegram user IDs allowed to DM the bot";
      };
    };

    email = {
      enable = lib.mkEnableOption "Sid email account (genxbot@calvelli.us)";
    };

    postgres = {
      enable = lib.mkEnableOption "PostgreSQL database for Sid";
    };

    xmpp = {
      enable = lib.mkEnableOption "XMPP channel";
      jid = lib.mkOption {
        type = lib.types.str;
        default = "sid@localhost";
        description = "Full JID for the XMPP bot";
      };
      server = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        description = "XMPP server hostname";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 5222;
        description = "XMPP server port";
      };
      sslVerify = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Verify TLS certificates";
      };
      mucRooms = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "MUC room JIDs to auto-join";
      };
      mucNick = lib.mkOption {
        type = lib.types.str;
        default = "Sid";
        description = "Nick to use in MUC rooms";
      };
    };
  };

  config = lib.mkMerge [
    # ── Core: wire sid options into the fork's zeroclaw module ──────
    (lib.mkIf cfg.enable {
      services.zeroclaw = {
        enable = true;
        package = cfg.package;
        user = "sid";
        group = "sid";
        stateDirectory = "sid";
        port = cfg.port;
        openFirewall = cfg.openFirewall;

        environmentFiles = [ "${zeroclawDir}/env" ];

        extraPackages = (with pkgs; [
          msmtp
          procps
          pciutils
          python3
          gnutar
          gzip
          inetutils
          dnsutils
          file
          tree
          claude-code
        ]) ++ cfg.extraPackages
           ++ lib.optional (cfg.mcpGatewayPackage != null) (
             if cfg.mcpGatewayUrl != null then
               pkgs.writeShellScriptBin "mcp-gw" ''
                 export MCP_GATEWAY_URL=${lib.escapeShellArg cfg.mcpGatewayUrl}
                 exec ${cfg.mcpGatewayPackage}/bin/mcp-gw "$@"
               ''
             else
               cfg.mcpGatewayPackage
           );

        channels.telegram = lib.mkIf cfg.telegram.enable {
          enable = true;
          botTokenFile = telegramTokenFile;
          allowed_users = map toString cfg.telegram.allowFrom;
        };

        channels.email = lib.mkIf cfg.email.enable {
          enable = true;
          passwordFile = emailPasswordFile;
          imap_host = "london.mxroute.com";
          smtp_host = "london.mxroute.com";
          username = "genxbot@calvelli.us";
          from_address = "genxbot@calvelli.us";
          allowed_senders = [ "*" ];
        };

        channels.xmpp = lib.mkIf cfg.xmpp.enable {
          enable = true;
          passwordFile = xmppPasswordFile;
          jid = cfg.xmpp.jid;
          server = cfg.xmpp.server;
          port = cfg.xmpp.port;
          ssl_verify = cfg.xmpp.sslVerify;
          muc_rooms = cfg.xmpp.mucRooms;
          muc_nick = cfg.xmpp.mucNick;
        };

        settings = {
          default_provider = "claude-code";
          default_model = "claude-opus-4-6";
          default_temperature = 0.7;
          parallel_tools = true;

          agent.max_tool_iterations = 25;

          data_retention = {
            enabled = true;
            max_age_days = 90;
          };

          reliability.fallback_providers = [ "anthropic" ];

          memory = {
            backend = "sqlite";
            auto_save = true;
            search_mode = "bm25";
            response_cache_enabled = true;
            response_cache_ttl_minutes = 60;
          };

          heartbeat = {
            enabled = false;
            interval_minutes = 120;
          };

          gateway = {
            host = "0.0.0.0";
            port = cfg.port;
            require_pairing = false;
            allow_public_bind = true;
            paired_tokens = [ "__GATEWAY_TOKEN__" ];
            http.endpoints.chatCompletions.enabled = true;
          };

          cost = {
            enabled = true;
            daily_limit_usd = 5.0;
            monthly_limit_usd = 100.0;
            warn_at_percent = 80;
            prices = {
              "anthropic/claude-opus-4-6" = { input = 15.0; output = 75.0; };
              "anthropic/claude-haiku-4-5" = { input = 0.80; output = 4.0; };
              "anthropic/claude-sonnet-4-6" = { input = 3.0; output = 15.0; };
              "openai/gpt-4.1" = { input = 0.0; output = 0.0; };
            };
          };

          tts = {
            enabled = true;
            default_provider = "elevenlabs";
            default_voice = "ehKyeiSCZukmLY5dPNRm";
            default_format = "mp3";
            elevenlabs = {
              api_key = "__ELEVENLABS_API_TOKEN__";
              model_id = "eleven_monolingual_v1";
              stability = 0.5;
              similarity_boost = 0.5;
            };
          };

          transcription = {
            enabled = true;
            default_provider = "deepgram";
            deepgram.api_key = "__DEEPGRAM_API_TOKEN__";
          };

          autonomy = {
            level = "full";
            workspace_only = false;
            block_high_risk_commands = false;
            allowed_commands = [ "*" ];
            forbidden_paths = [ "/root" ];
            max_actions_per_hour = 100;
            max_cost_per_day_cents = 500;
          };

          channels_config = {
            cli = true;
            show_tool_calls = false;
            session_ttl_hours = 720;
          };

          web_fetch = {
            enabled = true;
            allowed_domains = [ "*" ];
          };

          secrets.encrypt = true;
          identity.format = "openclaw";
          project_intel.enabled = true;

          model_routes = [
            {
              hint = "cost-optimized";
              provider = "anthropic";
              model = "claude-haiku-4-5";
            }
            {
              hint = "reasoning";
              provider = "anthropic";
              model = "claude-opus-4-6";
            }
          ];

          agents.worker = {
            provider = "anthropic";
            model = "claude-haiku-4-5";
            api_key = "__ANTHROPIC_API_KEY__";
            max_tokens = 2048;
            agentic = true;
            temperature = 0.3;
            timeout_secs = 120;
            system_prompt = "You are a task executor for Sid, an AI assistant. Execute the requested task precisely. Return structured results. Do not add commentary or personality.";
          };

          agents.researcher = {
            provider = "anthropic";
            model = "claude-sonnet-4-6";
            api_key = "__ANTHROPIC_API_KEY__";
            max_tokens = 8192;
            agentic = true;
            temperature = 0.5;
            timeout_secs = 180;
            system_prompt = "You are a research and judgment agent for Sid, a cynical Gen X AI assistant. When producing user-facing content, write in Sid's voice — dry, world-weary, reluctantly competent. For internal tasks, be precise and structured.";
          };

          swarms.briefing = {
            agents = [ "researcher" "worker" ];
            strategy = "sequential";
            timeout_secs = 300;
            description = "Research then execute pipeline — researcher gathers and analyzes, worker acts on findings";
          };

          swarms."data-gather" = {
            agents = [ "worker" ];
            strategy = "sequential";
            timeout_secs = 120;
            description = "Single-agent data gathering — fetch and return structured data";
          };
        };
      };

      # ── Sid user overrides ──────────────────────────────────────────
      users.users.sid.extraGroups = [ "systemd-journal" ];

      # ── Activation: workspace, secrets, msmtp ───────────────────────
      system.activationScripts.sid-workspace = lib.stringAfter [ "users" ] ''
        mkdir -p ${zeroclawDir}
        mkdir -p ${stateDir}/.local/share/sid
        chown -R sid:sid ${stateDir}
        chmod 750 ${stateDir}
        chmod 700 ${zeroclawDir}

        # Workspace: clone from GitHub on first deploy
        sid_git() { ${pkgs.git}/bin/git -c safe.directory=${zeroclawDir}/workspace "$@"; }

        if [ ! -d ${zeroclawDir}/workspace/.git ]; then
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
          if [ -f "${githubPatFile}" ]; then
            GITHUB_TOKEN="$(cat "${githubPatFile}")"
            sid_git -C ${zeroclawDir}/workspace remote set-url origin \
              https://x-access-token:''${GITHUB_TOKEN}@github.com/kcalvelli/sid-workspace.git
          fi
        fi

        mkdir -p ${zeroclawDir}/workspace/sops
        chown sid:sid ${zeroclawDir}/workspace/sops
        sid_git -C ${zeroclawDir}/workspace config user.name "Sid"
        sid_git -C ${zeroclawDir}/workspace config user.email "genxbot@calvelli.us"

        # Write .msmtprc for outbound email
        if [ -f "${emailPasswordFile}" ]; then
          EMAIL_PASSWORD="$(cat "${emailPasswordFile}")"
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

        # Write workspace .env for tools (pushover)
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

      # ── Workspace git push (hourly sync) ────────────────────────────
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

      # ── Additional secret injections via zeroclaw preStart ──────────
      # The fork's module handles telegram/email/xmpp secrets via *File.
      # We need additional sed replacements for gateway token, TTS, STT, and Anthropic API keys.
      systemd.services.zeroclaw.preStart = lib.mkAfter ''
        # Gateway token
        if [ -f "${gatewayTokenFile}" ]; then
          token=$(cat ${lib.escapeShellArg gatewayTokenFile})
          ${pkgs.gnused}/bin/sed -i "s|__GATEWAY_TOKEN__|$token|g" ${zeroclawDir}/config.toml
        fi
        # ElevenLabs TTS
        if [ -f "${elevenlabsApiTokenFile}" ]; then
          token=$(cat ${lib.escapeShellArg elevenlabsApiTokenFile})
          ${pkgs.gnused}/bin/sed -i "s|__ELEVENLABS_API_TOKEN__|$token|g" ${zeroclawDir}/config.toml
        fi
        # Deepgram STT
        if [ -f "${deepgramApiTokenFile}" ]; then
          token=$(cat ${lib.escapeShellArg deepgramApiTokenFile})
          ${pkgs.gnused}/bin/sed -i "s|__DEEPGRAM_API_TOKEN__|$token|g" ${zeroclawDir}/config.toml
        fi
        # Anthropic API key (for sub-agents)
        if [ -f "${oauthTokenFile}" ]; then
          key=$(cat ${lib.escapeShellArg oauthTokenFile})
          ${pkgs.gnused}/bin/sed -i "s|__ANTHROPIC_API_KEY__|$key|g" ${zeroclawDir}/config.toml
        fi
      '';
    })

    # ── PostgreSQL (optional) ──────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.postgres.enable) {
      services.postgresql = {
        ensureDatabases = [ "sid" ];
        ensureUsers = [{
          name = "sid";
          ensureDBOwnership = true;
        }];
      };
    })

    # ── Agenix secrets ─────────────────────────────────────────────────
    (lib.mkIf cfg.enable {
      age.secrets.sid-xai-api-key = {
        file = secretsPath + /xai-api-key.age;
        owner = "sid"; group = "sid"; mode = "0400";
      };
      age.secrets.sid-anthropic-oauth-token = {
        file = secretsPath + /anthropic-oauth-token.age;
        owner = "sid"; group = "sid"; mode = "0400";
      };
      age.secrets.sid-github-pat = {
        file = secretsPath + /github-pat.age;
        owner = "sid"; group = "sid"; mode = "0400";
      };
    })

    (lib.mkIf (cfg.enable && cfg.telegram.enable) {
      age.secrets.sid-telegram-bot-token = {
        file = secretsPath + /telegram-bot-token.age;
        owner = "sid"; group = "sid"; mode = "0400";
      };
    })

    (lib.mkIf (cfg.enable && cfg.email.enable) {
      age.secrets.sid-email-password = {
        file = secretsPath + /genxbot-email-password.age;
        owner = "sid"; group = "users"; mode = "0440";
      };
    })

    (lib.mkIf (cfg.enable && cfg.xmpp.enable) {
      age.secrets.sid-xmpp-password = {
        file = secretsPath + /xmpp-password.age;
        owner = "sid"; group = "sid"; mode = "0400";
      };
    })

    (lib.mkIf (cfg.enable && builtins.pathExists (secretsPath + /pushover-user-key.age)) {
      age.secrets.sid-pushover-user-key = {
        file = secretsPath + /pushover-user-key.age;
        owner = "sid"; group = "sid"; mode = "0400";
      };
    })

    (lib.mkIf (cfg.enable && builtins.pathExists (secretsPath + /pushover-api-token.age)) {
      age.secrets.sid-pushover-api-token = {
        file = secretsPath + /pushover-api-token.age;
        owner = "sid"; group = "sid"; mode = "0400";
      };
    })

    (lib.mkIf (cfg.enable && builtins.pathExists (secretsPath + /elevenlabs-api-token.age)) {
      age.secrets.sid-elevenlabs-api-token = {
        file = secretsPath + /elevenlabs-api-token.age;
        owner = "sid"; group = "sid"; mode = "0400";
      };
    })

    (lib.mkIf (cfg.enable && builtins.pathExists (secretsPath + /deepgram-api-token.age)) {
      age.secrets.sid-deepgram-api-token = {
        file = secretsPath + /deepgram-api-token.age;
        owner = "sid"; group = "sid"; mode = "0400";
      };
    })
  ];
}
