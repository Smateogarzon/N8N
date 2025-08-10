#!/bin/bash
set -e

echo "=== Probando n8n con configuración simplificada ==="

# Detener contenedores existentes
echo "1. Deteniendo contenedores existentes..."
docker-compose down 2>/dev/null || true
docker-compose -f docker-compose-simple.yml down 2>/dev/null || true

# Limpiar volúmenes
echo "2. Limpiando volúmenes..."
docker volume prune -f

# Construir y ejecutar versión simplificada
echo "3. Construyendo y ejecutando versión simplificada..."
docker-compose -f docker-compose-simple.yml up -d --build

# Esperar un poco
echo "4. Esperando que los servicios se inicien..."
sleep 15

# Verificar estado
echo "5. Verificando estado de contenedores..."
docker ps

echo ""
echo "6. Logs de PostgreSQL:"
docker-compose -f docker-compose-simple.yml logs postgres

echo ""
echo "7. Logs de n8n:"
docker-compose -f docker-compose-simple.yml logs n8n

echo ""
echo "=== Información de acceso ==="
echo "🌐 n8n: http://localhost:5680"
echo "🗄️  PostgreSQL: localhost:5433"
echo ""
echo "Si n8n no responde, revisa los logs arriba" 