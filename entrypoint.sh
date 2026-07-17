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

exec python -B -c "from hermes_cli.web_server import start_server; start_server('0.0.0.0', int(__import__('os').environ.get('PORT', '9119')), False)"
