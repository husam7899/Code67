# =============================================================================
# Dockerfile - Hermes Agent + custom Telegram Mini App web UI, for Railway.
#
# This starts from Nous Research's OFFICIAL hermes-agent image (which already
# has the full agent, Python, Node, ripgrep, ffmpeg, etc. installed) and
# overlays this repo's custom hermes_cli/web_server.py + built web/ frontend
# on top of it, then boots straight into the web/dashboard server instead of
# the default gateway.
#
# ⚠️ VERIFY BEFORE TRUSTING THIS FILE:
# The official image's internal layout can change between releases, and this
# repo's web_server.py was written against a specific (possibly older)
# version of hermes_cli's internal API (hermes_cli.config, gateway.status,
# hermes_state). If the installed hermes-agent version's "dashboard" feature
# has since replaced this project's Bearer-token web_server.py with a newer
# OAuth-based one, this overlay may fail to import or behave differently.
#
# Run this once locally (or in Railway's build logs) to confirm paths match:
#   docker run --rm -it nousresearch/hermes-agent:latest sh -c \
#     "python3 -c 'import hermes_cli.web_server as m; print(m.__file__)'"
# and adjust the COPY destination paths below if the printed path differs
# from /opt/hermes/hermes_cli/web_server.py.
# =============================================================================

FROM nousresearch/hermes-agent:latest

# --- Overlay the patched backend file -------------------------------------
# Adjust this destination if the base image's hermes_cli package lives
# somewhere other than /opt/hermes/hermes_cli (see note above).
COPY hermes_cli/web_server.py /opt/hermes/hermes_cli/web_server.py

# --- Build the Mini App frontend and place it where web_server.py expects it
# web_server.py does: WEB_DIST = Path(__file__).parent / "web_dist"
# NOTE: web/vite.config.ts already sets build.outDir to "../hermes_cli/web_dist"
# (relative to web/), so after the build the output lands at
# /tmp/hermes_cli/web_dist directly -- there is no "dist" folder to copy.
COPY web /tmp/web-build
RUN cd /tmp/web-build \
    && npm install \
    && npm run build \
    && rm -rf /opt/hermes/hermes_cli/web_dist \
    && mv /tmp/hermes_cli/web_dist /opt/hermes/hermes_cli/web_dist \
    && rm -rf /tmp/web-build /tmp/hermes_cli

# --- Overlay the fixed admin/terminal single-page app ----------------------
# This is the "Admin" page shown in the Telegram Mini App (token gate, chat
# terminal, drawer menu). Adjust destination if it's served from elsewhere.
COPY index.html /opt/hermes/index.html

# --- Non-interactive provider setup (Groq) + launch -------------------------
COPY entrypoint.sh /opt/hermes/entrypoint.sh
RUN chmod +x /opt/hermes/entrypoint.sh

# HERMES_HOME is where config.yaml / .env / sessions / memories persist.
# On Railway (no bind mount by default) this resets on every redeploy unless
# you attach a Railway Volume mounted at this same path.
ENV HERMES_HOME=/opt/data

EXPOSE 9119

# Railway injects $PORT at runtime - bind the web server to 0.0.0.0:$PORT
# instead of the default 127.0.0.1:9119 (loopback-only, per README warning
# about the exposed UI/API keys - Railway's edge network is the boundary
# here instead).
CMD ["/opt/hermes/entrypoint.sh"]
