FROM docker.n8n.io/n8nio/n8n

# CACHEBUST: altere este valor para forçar um rebuild completo no Railway
ARG CACHEBUST=7
RUN echo "[BUILD] Cache bust: $CACHEBUST"

USER root

# Instala nginx
RUN apk add --no-cache nginx && \
    mkdir -p /run/nginx /var/lib/nginx /var/log/nginx

# Copia config do nginx (com proxy_hide_header para remover bloqueio de iframe)
COPY nginx.conf /etc/nginx/nginx.conf
RUN nginx -t  # valida a config ANTES de ir pra produção

# ==============================================================
# CONFIGURAÇÃO: nginx + wrapper
#
# Railway tem "Custom Start Command = n8n" (não podemos mudar),
# então substituímos o binário n8n por um wrapper que:
#   1) Inicia nginx na porta 8080 (daemon mode)
#   2) Executa o n8n REAL na porta 5678
#
# O nginx faz proxy de 8080 → 5678, REMOVENDO os headers
# X-Frame-Options e Content-Security-Policy que bloqueiam iframe.
#
# Railway roteia para a porta 8080 → nginx → n8n (5678)
# ==============================================================

# Substitui o binário n8n por um wrapper que inicia nginx antes
RUN mv /usr/local/bin/n8n /usr/local/bin/n8n.real && \
    printf '#!/bin/sh\n\
echo "[WRAPPER] Starting nginx on port 8080..."\n\
nginx 2>&1\n\
echo "[WRAPPER] nginx started. Executing n8n on port 5678..."\n\
exec /usr/local/bin/n8n.real "$@"\n' > /usr/local/bin/n8n && \
    chmod +x /usr/local/bin/n8n

# Remove configs default do nginx que possam conflitar
RUN rm -f /etc/nginx/conf.d/default.conf /etc/nginx/sites-enabled/default 2>/dev/null; true

# Mantém start.sh como alternativa
COPY start.sh /start.sh
RUN chmod +x /start.sh

USER node

# Configurações n8n
ENV N8N_HOST=0.0.0.0
ENV WEBHOOK_URL=https://n8n-production-8e2d4.up.railway.app

# Porta que o Railway vai expor (nginx escuta aqui)
EXPOSE 8080
