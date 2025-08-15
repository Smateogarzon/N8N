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

# Detectar la ruta correcta del binario de n8n
if [ -x "/usr/local/bin/n8n" ]; then
	N8N_BIN="/usr/local/bin/n8n"
elif [ -x "/usr/bin/n8n" ]; then
	N8N_BIN="/usr/bin/n8n"
else
	N8N_BIN="n8n"
fi

echo "Usando binario: $N8N_BIN"

# Delegar al entrypoint oficial con la ruta detectada
exec /docker-entrypoint.sh "$N8N_BIN" start
