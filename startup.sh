#!/bin/sh
set -e

echo "=== Iniciando n8n para Cloud Run (v7 - Simple) ==="

# Solo configurar PATH, dejar que Cloud Run maneje los puertos
export PATH="/usr/local/bin:${PATH}"

echo "Variables de entorno:"
echo "PORT: ${PORT:-'no definido'}"
echo "N8N_PORT: ${N8N_PORT:-'no definido'}"
echo "N8N_HOST: ${N8N_HOST:-'no definido'}"

# Delegar al entrypoint oficial (él manejará todos los puertos)
exec /docker-entrypoint.sh
