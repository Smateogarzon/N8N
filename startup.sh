#!/usr/bin/env bash
set -euo pipefail

echo "=== Iniciando n8n para Cloud Run ==="

# Cloud Run inyecta $PORT; n8n debe escuchar ahí
export N8N_PORT="${PORT:-8080}"
export N8N_HOST="${N8N_HOST:-0.0.0.0}"

echo "Host: $N8N_HOST"
echo "Puerto: $N8N_PORT"

# MUY IMPORTANTE: delegar al entrypoint oficial
exec /docker-entrypoint.sh n8n start
