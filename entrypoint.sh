#!/bin/sh
# =============================================================================
# entrypoint.sh - launches the custom Hermes dashboard / mini-app web server.
#
# NOTE: the Groq provider setup and API_SERVER_ENABLED handling used to live
# here, but that ran too late (after the base image's "main-hermes" gateway
# service had already started and read .env once). That logic now lives in
# /etc/cont-init.d/011-gateway-env-setup, which runs before main-hermes
# starts. This file now only launches the web server itself.
# =============================================================================
set -eu

# --- Diagnostic: confirm whether the internal gateway (port 8642) actually
# came up. This doesn't fix anything by itself -- it just prints the real
# answer to the logs instead of us having to guess from ConnectErrors.
echo "[entrypoint] Checking internal gateway on 127.0.0.1:8642 ..."
for i in 1 2 3 4 5; do
  if command -v curl >/dev/null 2>&1; then
    HEALTH_OUT="$(curl -s -m 3 -o /dev/null -w '%{http_code}' http://127.0.0.1:8642/health 2>&1 || true)"
  else
    HEALTH_OUT="curl not available"
  fi
  echo "[entrypoint] gateway /health attempt $i -> ${HEALTH_OUT}"
  if [ "${HEALTH_OUT}" = "200" ]; then
    echo "[entrypoint] Gateway is UP."
    break
  fi
  sleep 2
done

echo "[entrypoint] --- /opt/data/.env (secrets masked) ---"
sed -E 's/=(.{4}).*/=\1********/' "${HERMES_HOME:-/opt/data}/.env" 2>/dev/null || echo "[entrypoint] (no .env file found)"
echo "[entrypoint] --------------------------------------"

exec python -B -c "from hermes_cli.web_server import start_server; start_server('0.0.0.0', int(__import__('os').environ.get('PORT', '9119')), False)"
