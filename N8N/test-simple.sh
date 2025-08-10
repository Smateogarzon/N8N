#!/bin/bash
set -e

echo "=== Prueba Simple de Dockerfile ==="

# Verificar que Docker esté disponible
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker no está disponible"
    exit 1
fi

echo "OK: Docker está disponible"

# Verificar que el archivo existe
if [ ! -f "docker-entrypoint.sh" ]; then
    echo "ERROR: docker-entrypoint.sh no existe"
    exit 1
fi

echo "OK: docker-entrypoint.sh existe"

# Probar construcción
echo "Construyendo Dockerfile básico..."
if docker build -f Dockerfile -t test-n8n:latest .; then
    echo "✅ Construcción exitosa"
    echo "✅ El Dockerfile funciona correctamente"
else
    echo "❌ Error en la construcción"
    exit 1
fi 