#!/usr/bin/env bash
set -euo pipefail

# Script de inicio para Cloud Run que usa el entrypoint oficial
echo "=== Iniciando n8n para Cloud Run ==="

# Manejar puerto dinámico de Cloud Run
export N8N_PORT="${PORT:-8080}"
echo "Configurando n8n para escuchar en puerto: $N8N_PORT"

# Configurar host para Cloud Run
export N8N_HOST="${N8N_HOST:-0.0.0.0}"

# Mostrar configuración
echo "=== Configuración final ==="
echo "Host: $N8N_HOST"
echo "Puerto: $N8N_PORT"
echo "=========================="

# Usar el entrypoint oficial de n8n
exec /docker-entrypoint.sh n8n start 