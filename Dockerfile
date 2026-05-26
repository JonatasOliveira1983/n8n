FROM docker.n8n.io/n8nio/n8n

USER root

# Instala o Nginx
RUN apk add --no-cache nginx

# Cria diretórios necessários para o nginx e dá permissão pro usuário node (que não é root)
RUN mkdir -p /run/nginx /var/lib/nginx /var/log/nginx /tmp/client_temp /tmp/proxy_temp_path /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    chown -R node:node /run/nginx /var/lib/nginx /var/log/nginx /etc/nginx /tmp/client_temp /tmp/proxy_temp_path /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp

# Copia as configurações do Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Cria um wrapper que substitui o comando "n8n" por um script que:
# 1) Inicia o nginx (para Railway escutar na porta 8080)
# 2) Executa o n8n real em foreground
# Isso garante que, independente do Start Command no Railway ("n8n"), ambos os serviços rodem.
RUN mv /usr/local/bin/n8n /usr/local/bin/n8n.real && \
    printf '#!/bin/sh\nnginx\nexec /usr/local/bin/n8n.real "$@"\n' > /usr/local/bin/n8n && \
    chmod +x /usr/local/bin/n8n

# Mantém o start.sh como alternativa (via railway.json startCommand ou ENTRYPOINT)
COPY start.sh /start.sh
RUN chmod +x /start.sh && chown node:node /start.sh

# Volta para o usuário padrão do N8N (segurança)
USER node

# Variáveis do N8N
ENV N8N_HOST=0.0.0.0
ENV WEBHOOK_URL=https://n8n-production-8e2d4.up.railway.app

# Informa ao Railway qual porta o Nginx estará escutando (8080)
EXPOSE 8080
