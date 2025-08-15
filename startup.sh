#!/bin/sh
set -e

echo "=== Iniciando n8n para Cloud Run (v4 - Final) ==="

# Cloud Run inyecta la variable $PORT.
echo "Cloud Run PORT: ${PORT:-'No definido (usando default de n8n)'}"

# PASO CRÍTICO: Reconstruir el PATH para incluir los binarios de n8n.
export PATH="/usr/local/bin:${PATH}"

# Delegamos al entrypoint oficial con la sintaxis correcta
exec /docker-entrypoint.sh n8n start
