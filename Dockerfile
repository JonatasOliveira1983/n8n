# CACHEBUST: increment this number to force a full Docker rebuild on Railway
ARG CACHEBUST=1

FROM docker.n8n.io/n8nio/n8n

USER root

# Instala o Nginx
RUN apk add --no-cache nginx

# Cria diretórios necessários para o nginx e dá permissão pro usuário node (que não é root)
RUN mkdir -p /run/nginx /var/lib/nginx /var/log/nginx /tmp/client_temp /tmp/proxy_temp_path /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    chown -R node:node /run/nginx /var/lib/nginx /var/log/nginx /etc/nginx /tmp/client_temp /tmp/proxy_temp_path /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp

# Copia as configurações do Nginx e testa se estão válidas
COPY nginx.conf /etc/nginx/nginx.conf
RUN nginx -t

# Cria um wrapper que substitui o comando "n8n" por um script que:
# 1) Inicia o nginx em background (porta 8080 para Railway)
# 2) Executa o n8n real em foreground
# Isso funciona mesmo que o Railway use "n8n" como Start Command (locked)
RUN mv /usr/local/bin/n8n /usr/local/bin/n8n.real && \
    printf '#!/bin/sh\nnginx 2>/tmp/nginx-wrapper-error.log\nexec /usr/local/bin/n8n.real "$@"\n' > /usr/local/bin/n8n && \
    chmod +x /usr/local/bin/n8n

# Mantém o start.sh como alternativa para debug manual
COPY start.sh /start.sh
RUN chmod +x /start.sh && chown node:node /start.sh

# Remove configs default do nginx que possam conflitar (ex: conf.d/default.conf em porta 80)
RUN rm -f /etc/nginx/conf.d/default.conf /etc/nginx/sites-enabled/default 2>/dev/null; true

# Volta para o usuário padrão do N8N (segurança)
USER node

# Variáveis do N8N
ENV N8N_HOST=0.0.0.0
ENV WEBHOOK_URL=https://n8n-production-8e2d4.up.railway.app

# Informa ao Railway qual porta o Nginx estará escutando (8080)
EXPOSE 8080
