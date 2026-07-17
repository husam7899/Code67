#!/bin/sh
# =============================================================================
# entrypoint.sh - non-interactive provider setup + launch of the web UI.
#
# Railway can't run the interactive `hermes setup` wizard, so this writes the
# Groq custom-provider config directly into config.yaml on first boot (skips
# it if already present, so it won't clobber changes made later via the UI
# or `hermes config set`).
# =============================================================================
set -eu

CONFIG_FILE="${HERMES_HOME:-/opt/data}/config.yaml"
mkdir -p "$(dirname "$CONFIG_FILE")"
touch "$CONFIG_FILE"

if ! grep -q "name: groq" "$CONFIG_FILE" 2>/dev/null; then
  echo "[entrypoint] Adding Groq as a custom provider to $CONFIG_FILE"
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
  echo "[entrypoint] WARNING: GROQ_API_KEY is not set - the agent will fail to reach Groq." >&2
fi

exec python -B -c "from hermes_cli.web_server import start_server; start_server('0.0.0.0', int(__import__('os').environ.get('PORT', '9119')), False)"
