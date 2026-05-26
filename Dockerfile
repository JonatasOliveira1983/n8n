FROM docker.n8n.io/n8nio/n8n

# CACHEBUST: altere este valor para forçar um rebuild completo no Railway
ARG CACHEBUST=4
# Usa o ARG em um RUN para realmente invalidar o cache Docker
RUN echo "[BUILD] Cache bust: $CACHEBUST"

USER root

# Instala o Nginx
RUN apk add --no-cache nginx

# Cria diretórios necessários para o nginx e dá permissão pro usuário node
RUN mkdir -p /run/nginx /var/lib/nginx /var/log/nginx /tmp/client_temp /tmp/proxy_temp_path /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    chown -R node:node /run/nginx /var/lib/nginx /var/log/nginx /etc/nginx /tmp/client_temp /tmp/proxy_temp_path /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp

# Copia as configurações do Nginx e valida
COPY nginx.conf /etc/nginx/nginx.conf
RUN nginx -t

# Remove configs default do nginx que possam conflitar
RUN rm -f /etc/nginx/conf.d/default.conf /etc/nginx/sites-enabled/default 2>/dev/null; true

# ==============================================================
# WRAPPER: substitui o binário n8n por um script que:
#  1) Inicia nginx na porta 8080 (Railway roteia para esta porta)
#  2) Executa o n8n real na porta 5678 (proxy reverso via nginx)
#
# Isso é NECESSÁRIO porque o Railway tem "Custom Start Command = n8n"
# configurado no dashboard, que ignora ENTRYPOINT/CMD do Dockerfile.
# ==============================================================
RUN mv /usr/local/bin/n8n /usr/local/bin/n8n.real && \
    printf '%s\n' \
      '#!/bin/sh' \
      'echo "[WRAPPER] ===== nginx + n8n startup ====="' \
      'echo "[WRAPPER] Starting nginx on port 8080..."' \
      'nginx 2>&1' \
      'if [ -f /tmp/nginx.pid ] && kill -0 $(cat /tmp/nginx.pid) 2>/dev/null; then' \
      '  echo "[WRAPPER] nginx is running on port 8080 (PID $(cat /tmp/nginx.pid))"' \
      'else' \
      '  echo "[WRAPPER] WARNING: nginx PID not found - check /tmp/nginx-error.log"' \
      'fi' \
      'echo "[WRAPPER] Executing n8n on port 5678..."' \
      'exec /usr/local/bin/n8n.real "$@"' \
    > /usr/local/bin/n8n && \
    chmod +x /usr/local/bin/n8n

# start.sh como alternativa para debug manual (caso Railway use ENTRYPOINT)
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Volta para o usuário padrão do N8N (segurança)
USER node

ENV N8N_HOST=0.0.0.0
ENV WEBHOOK_URL=https://n8n-production-8e2d4.up.railway.app

# Railway usará esta porta para roteamento HTTP
EXPOSE 8080

# Entrypoint como fallback (se Railway não forçar start command)
ENTRYPOINT ["tini", "--", "/start.sh"]
