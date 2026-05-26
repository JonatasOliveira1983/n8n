#!/bin/sh

# Inicia o n8n em segundo plano (background)
echo "[START] Iniciando n8n..."
n8n &
N8N_PID=$!
echo "[START] n8n iniciado com PID $N8N_PID"

# Aguarda o n8n ficar pronto
echo "[START] Aguardando n8n ficar pronto..."
sleep 5

# Verifica se n8n ainda está rodando
if kill -0 $N8N_PID 2>/dev/null; then
    echo "[START] n8n está rodando (PID $N8N_PID)"
else
    echo "[START] ERRO: n8n morreu! Verifique as migrações."
fi

# Inicia o Nginx em primeiro plano
echo "[START] Iniciando nginx na porta 8080..."
nginx -g 'daemon off;'
NGINX_EXIT=$?
echo "[START] nginx finalizou com código $NGINX_EXIT"