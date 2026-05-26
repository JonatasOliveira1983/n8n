FROM docker.n8n.io/n8nio/n8n

# CACHEBUST: altere este valor para forçar um rebuild completo no Railway
ARG CACHEBUST=5
RUN echo "[BUILD] Cache bust: $CACHEBUST"

USER root

# Remove nginx e o wrapper antigo (se existirem de builds anteriores)
RUN apk del nginx 2>/dev/null; rm -f /start.sh /usr/local/bin/n8n.real; true

# ==============================================================
# CONFIGURAÇÃO SIMPLIFICADA
#
# Railway tem "Custom Start Command = n8n" (não podemos mudar),
# então o binário n8n ORIGINAL precisa ficar intacto.
#
# Usamos env vars do próprio n8n para:
#   - N8N_PORT=8080          → n8n escuta na porta que o Railway espera
#   - N8N_DISABLE_X_FRAME_OPTIONS=true  → permite iframe no cockpit.html
#
# SEM nginx, SEM wrapper, SEM start.sh → apenas n8n puro.
# ==============================================================

# Volta para o usuário padrão do N8N
USER node

# Configura n8n para escutar na porta 8080 (Railway)
ENV N8N_PORT=8080
# Remove o bloqueio de iframe (para embed no cockpit.html)
ENV N8N_DISABLE_X_FRAME_OPTIONS=true
# Mantém as configs existentes
ENV N8N_HOST=0.0.0.0
ENV WEBHOOK_URL=https://n8n-production-8e2d4.up.railway.app

# Railway usará esta porta para roteamento HTTP
EXPOSE 8080
