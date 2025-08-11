#!/bin/sh
# Script de inicio para Cloud Run - Maneja puerto dinámico

set -e

echo "=== Iniciando n8n para Cloud Run ==="

# Manejar puerto dinámico de Cloud Run
if [ -n "$PORT" ]; then
    echo "Puerto Cloud Run detectado: $PORT"
    export N8N_PORT=$PORT
    echo "Configurando n8n para escuchar en puerto: $N8N_PORT"
else
    echo "Puerto Cloud Run no detectado, usando puerto por defecto: ${N8N_PORT:-5678}"
    export N8N_PORT=${N8N_PORT:-5678}
fi

# Configurar host para Cloud Run
export N8N_HOST=${N8N_HOST:-0.0.0.0}
export N8N_PROTOCOL=${N8N_PROTOCOL:-http}

# Validar variables de entorno críticas
if [ -z "$DB_TYPE" ]; then
    echo "Error: DB_TYPE no está definido"
    exit 1
fi

if [ "$DB_TYPE" = "postgresdb" ]; then
    required_vars="DB_POSTGRESDB_HOST DB_POSTGRESDB_DATABASE DB_POSTGRESDB_USER DB_POSTGRESDB_PASSWORD"
    for var in $required_vars; do
        if [ -z "$(eval echo \$$var)" ]; then
            echo "Error: $var no está definido para PostgreSQL"
            exit 1
        fi
    done
fi

# Crear directorios necesarios
mkdir -p /home/node/.n8n/logs
mkdir -p /home/node/.n8n/data
chown -R node:node /home/node/.n8n

# Mostrar configuración final
echo "=== Configuración final ==="
echo "Host: $N8N_HOST"
echo "Puerto: $N8N_PORT"
echo "Protocolo: $N8N_PROTOCOL"
echo "Base de datos: $DB_TYPE"
if [ "$DB_TYPE" = "postgresdb" ]; then
    echo "PostgreSQL Host: $DB_POSTGRESDB_HOST"
    echo "PostgreSQL Database: $DB_POSTGRESDB_DATABASE"
    echo "PostgreSQL User: $DB_POSTGRESDB_USER"
fi
echo "=========================="

# Cambiar al usuario node y ejecutar n8n
echo "Iniciando n8n con logs detallados..."
# La siguiente línea ejecutará n8n. Si falla, el script continuará y mostrará un error.
gosu node n8n start || {
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "!! EL PROCESO 'n8n start' HA FALLADO CON UN CÓDIGO DE ERROR !!"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1
} 