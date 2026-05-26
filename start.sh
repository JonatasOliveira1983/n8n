#!/bin/sh

echo "[START] ===== n8n + nginx startup ====="

# Inicia o n8n em segundo plano
echo "[START] Starting n8n in background..."
n8n "$@" &
N8N_PID=$!
echo "[START] n8n PID: $N8N_PID"

# Aguarda o n8n iniciar
echo "[START] Waiting for n8n to initialize..."
sleep 5

# Verifica se n8n ainda está rodando
if kill -0 $N8N_PID 2>/dev/null; then
    echo "[START] n8n is running (PID $N8N_PID)"
else
    echo "[START] ERROR: n8n died during startup!"
    exit 1
fi

# Inicia o Nginx em primeiro plano (isso bloqueia, mantendo o container vivo)
echo "[START] Starting nginx on port 8080..."
nginx -g 'daemon off;'
NGINX_EXIT=$?
echo "[START] nginx exited with code $NGINX_EXIT"

# Repassa o código de saída do nginx
exit $NGINX_EXIT
