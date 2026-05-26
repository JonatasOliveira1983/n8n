FROM docker.n8n.io/n8nio/n8n

# CACHEBUST: altere este valor para forçar um rebuild completo no Railway
ARG CACHEBUST=6
RUN echo "[BUILD] Cache bust: $CACHEBUST"

USER root

# Remove nginx e o wrapper antigo (se existirem de builds anteriores)
RUN apk del nginx 2>/dev/null; rm -f /start.sh /usr/local/bin/n8n.real; true

# ==============================================================
# CONFIGURAÇÃO CORRIGIDA
#
# Railway tem "Custom Start Command = n8n" (não podemos mudar),
# então o binário n8n ORIGINAL precisa ficar intacto.
#
# Usamos env vars do próprio n8n para:
#   - N8N_PORT=8080                    → n8n escuta na porta que o Railway espera
#   - N8N_CONTENT_SECURITY_POLICY      → permite iframe no 1crypten.space
#   - N8N_SAMESITE_COOKIE=none         → permite cookies cross-domain no iframe
#
# SEM nginx, SEM wrapper, SEM start.sh → apenas n8n puro.
#
# NOTA: N8N_DISABLE_X_FRAME_OPTIONS NÃO EXISTE no n8n!
# O controle correto é via Content Security Policy (frame-ancestors).
# ==============================================================

# Volta para o usuário padrão do N8N
USER node

# Configura n8n para escutar na porta 8080 (Railway)
ENV N8N_PORT=8080

# Permite iframe no 1crypten.space (remove bloqueio de frame-ancestors)
ENV N8N_CONTENT_SECURITY_POLICY={"frame-ancestors":["https://1crypten.space"]}

# Permite cookies cross-domain (necessário para iframe em domínio diferente)
ENV N8N_SAMESITE_COOKIE=none

# Mantém as configs existentes
ENV N8N_HOST=0.0.0.0
ENV WEBHOOK_URL=https://n8n-production-8e2d4.up.railway.app

# Railway usará esta porta para roteamento HTTP
EXPOSE 8080
