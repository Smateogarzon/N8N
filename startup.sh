#!/bin/sh
set -e

echo "=== Iniciando n8n para Cloud Run (v3) ==="

echo "Cloud Run PORT: ${PORT:-'No definido (usando default de n8n)'}"

# Asegurar que n8n escuche en el puerto dinámico de Cloud Run
export N8N_PORT="${PORT:-8080}"
export N8N_HOST="${N8N_HOST:-0.0.0.0}"

# Delegar al entrypoint oficial con la sintaxis correcta
exec /docker-entrypoint.sh n8n start
