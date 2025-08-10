#!/bin/sh
# Script de entrada personalizado para n8n Docker

set -e

# Función para validar variables de entorno requeridas
validate_env() {
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
}

# Función para esperar a que PostgreSQL esté disponible
wait_for_postgres() {
    if [ "$DB_TYPE" = "postgresdb" ]; then
        echo "Esperando a que PostgreSQL esté disponible..."
        # Usar netcat en lugar de pg_isready
        until nc -z "$DB_POSTGRESDB_HOST" "${DB_POSTGRESDB_PORT:-5432}"; do
            echo "PostgreSQL no está listo - esperando..."
            sleep 2
        done
        echo "PostgreSQL está listo!"
    fi
}

# Función para crear directorios necesarios
create_directories() {
    mkdir -p /home/node/.n8n/logs
    mkdir -p /home/node/.n8n/data
    chown -R node:node /home/node/.n8n
}

# Función para configurar variables por defecto
set_defaults() {
    export N8N_HOST=${N8N_HOST:-0.0.0.0}
    export N8N_PORT=${N8N_PORT:-5678}
    export N8N_PROTOCOL=${N8N_PROTOCOL:-http}
    export NODE_ENV=${NODE_ENV:-production}
    
    # Si no hay encryption key, n8n la generará automáticamente
    if [ -z "$N8N_ENCRYPTION_KEY" ]; then
        echo "N8N_ENCRYPTION_KEY no definida - n8n generará una automáticamente"
    fi
}

# Función para mostrar información de configuración
show_config() {
    echo "=== Configuración n8n ==="
    echo "Host: $N8N_HOST"
    echo "Puerto: $N8N_PORT"
    echo "Protocolo: $N8N_PROTOCOL"
    echo "Base de datos: $DB_TYPE"
    if [ "$DB_TYPE" = "postgresdb" ]; then
        echo "PostgreSQL Host: $DB_POSTGRESDB_HOST"
        echo "PostgreSQL Database: $DB_POSTGRESDB_DATABASE"
        echo "PostgreSQL User: $DB_POSTGRESDB_USER"
    fi
    echo "========================"
}

# Ejecutar funciones de inicialización
echo "Iniciando n8n..."
validate_env
set_defaults
create_directories
wait_for_postgres
show_config

# Cambiar al usuario node
exec gosu node "$@" 