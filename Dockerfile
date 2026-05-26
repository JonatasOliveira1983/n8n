FROM docker.n8n.io/n8nio/n8n

# CACHEBUST: altere este valor para forçar um rebuild completo no Railway
ARG CACHEBUST=3
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

# Copia o script de inicialização
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Remove configs default do nginx que possam conflitar
RUN rm -f /etc/nginx/conf.d/default.conf /etc/nginx/sites-enabled/default 2>/dev/null; true

# O binário original n8n permanece intacto (start.sh chama ele diretamente)

# Volta para o usuário padrão do N8N (segurança)
USER node

ENV N8N_HOST=0.0.0.0
ENV WEBHOOK_URL=https://n8n-production-8e2d4.up.railway.app

# Railway usará esta porta para roteamento HTTP
EXPOSE 8080

# Entrypoint: tini cuida dos sinais, start.sh gerencia nginx + n8n
ENTRYPOINT ["tini", "--", "/start.sh"]
