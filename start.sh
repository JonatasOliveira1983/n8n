#!/bin/sh

echo "[START] ===== n8n + nginx startup (start.sh) ====="

# Inicia nginx em background
echo "[START] Starting nginx on port 8080..."
nginx 2>&1
echo "[START] nginx started"

# Inicia n8n real em foreground
echo "[START] Starting n8n on port 5678..."
exec /usr/local/bin/n8n.real "$@"
