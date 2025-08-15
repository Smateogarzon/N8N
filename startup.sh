#!/bin/sh
set -eu

echo "=== Iniciando n8n para Cloud Run ==="

# Cloud Run inyecta $PORT; n8n debe escuchar ahí
export N8N_PORT="${PORT:-8080}"
export N8N_HOST="${N8N_HOST:-0.0.0.0}"

# Asegurar que /usr/local/bin esté en PATH (donde vive n8n)
export PATH="/usr/local/bin:${PATH}"

echo "Host: $N8N_HOST"
echo "Puerto: $N8N_PORT"

# Delegar al entrypoint oficial con ruta absoluta a n8n
exec /docker-entrypoint.sh /usr/local/bin/n8n start
