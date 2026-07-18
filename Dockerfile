FROM nousresearch/hermes-agent:latest

# --- አዲስ የጨመርነው ክፍል (የብሮውዘር ብልሽትን ይፈታል) ---
# Chromium የሚፈልጋቸውን የሲስተም ላይብረሪዎች ይጫኑ
RUN apt-get update && apt-get install -y \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*
# ----------------------------------------------------

# --- ኦሪጅናል ፋይሎችህ (ከዚህ በታች ያለው አይቀየርም) ---
COPY hermes_cli/web_server.py /opt/hermes/hermes_cli/web_server.py

COPY web /tmp/web-build
RUN cd /tmp/web-build \
    && npm install \
    && npm run build \
    && rm -rf /opt/hermes/hermes_cli/web_dist \
    && mv /tmp/hermes_cli/web_dist /opt/hermes/hermes_cli/web_dist \
    && rm -rf /tmp/web-build /tmp/hermes_cli

COPY index.html /opt/hermes/index.html
COPY cont-init.d/011-gateway-env-setup /etc/cont-init.d/011-gateway-env-setup
RUN chmod +x /etc/cont-init.d/011-gateway-env-setup

COPY entrypoint.sh /opt/hermes/entrypoint.sh
RUN chmod +x /opt/hermes/entrypoint.sh

ENV HERMES_HOME=/opt/data
EXPOSE 9119

CMD ["/opt/hermes/entrypoint.sh"]
