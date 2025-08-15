#!/bin/sh
set -e

echo "=== Iniciando n8n para Cloud Run (v5) ==="

echo "Cloud Run PORT: ${PORT:-'No definido (usando default de n8n)'}"

# Asegurar PATH correcto y mapear $PORT a N8N_PORT
export PATH="/usr/local/bin:${PATH}"
[ -n "${PORT:-}" ] && export N8N_PORT="$PORT"
export N8N_HOST="${N8N_HOST:-0.0.0.0}"

# Delegar al entrypoint oficial (deja que él ejecute n8n con su comando por defecto)
exec /docker-entrypoint.sh
