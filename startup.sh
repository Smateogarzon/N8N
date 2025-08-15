#!/bin/sh
set -e

echo "=== Iniciando n8n para Cloud Run (v6) ==="
echo "Cloud Run PORT: ${PORT:-8080}"

# Configurar variables críticas
export PATH="/usr/local/bin:${PATH}"
export N8N_PORT="${PORT:-8080}"
export N8N_HOST="0.0.0.0"
export N8N_LISTEN_ADDRESS="0.0.0.0"

echo "N8N escuchará en: $N8N_HOST:$N8N_PORT"

# Delegar al entrypoint oficial
exec /docker-entrypoint.sh
