#!/bin/sh
# =============================================================================
# 011-gateway-env-setup
#
# Runs as a cont-init.d script -- i.e. BEFORE the s6 "main-hermes" service
# (the internal gateway) starts. This is the fix for the bug where
# API_SERVER_ENABLED=true was being written by entrypoint.sh, which only
# runs as "legacy-services" AFTER main-hermes has already started and
# already read .env once -- so the gateway's OpenAI-compatible API server
# (port 8642) never came up, and /v1/chat/completions always failed with
# "All connection attempts failed".
#
# By moving this logic into cont-init.d (numbered between the base image's
# 01-hermes-setup and 015-supervise-perms), it now runs before main-hermes
# starts, so main-hermes sees API_SERVER_ENABLED=true from the very first
# read of .env.
# =============================================================================
set -eu

CONFIG_FILE="${HERMES_HOME:-/opt/data}/config.yaml"
mkdir -p "$(dirname "$CONFIG_FILE")"
touch "$CONFIG_FILE"

if ! grep -q "name: groq" "$CONFIG_FILE" 2>/dev/null; then
  echo "[011-gateway-env-setup] Adding Groq as a custom provider to $CONFIG_FILE"
  cat >> "$CONFIG_FILE" <<'EOF'

custom_providers:
  - name: groq
    base_url: https://api.groq.com/openai/v1
    key_env: GROQ_API_KEY

model:
  default: llama-3.3-70b-versatile
  provider: custom:groq
EOF
fi

if [ -z "${GROQ_API_KEY:-}" ]; then
  echo "[011-gateway-env-setup] WARNING: GROQ_API_KEY is not set - the agent will fail to reach Groq." >&2
fi

# The gateway's OpenAI-compatible API server (port 8642, used by
# /v1/chat/completions) is disabled by default -- it must be explicitly
# enabled via .env, per Hermes docs. This MUST happen before main-hermes
# starts, which is why this lives in cont-init.d and not in entrypoint.sh.
ENV_FILE="${HERMES_HOME:-/opt/data}/.env"
touch "$ENV_FILE"
if ! grep -q "^API_SERVER_ENABLED=" "$ENV_FILE" 2>/dev/null; then
  echo "[011-gateway-env-setup] Enabling the gateway API server (API_SERVER_ENABLED=true) in $ENV_FILE"
  echo "API_SERVER_ENABLED=true" >> "$ENV_FILE"
fi
