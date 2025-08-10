#!/bin/bash
set -e

echo "=== Aplicando corrección y probando n8n ==="

# Detener contenedores
echo "1. Deteniendo contenedores..."
docker-compose down 2>/dev/null || true
docker-compose -f docker-compose-simple.yml down 2>/dev/null || true

# Limpiar volúmenes
echo "2. Limpiando volúmenes..."
docker volume prune -f

# Reconstruir con la corrección
echo "3. Reconstruyendo con la corrección..."
docker-compose -f docker-compose-simple.yml up -d --build

# Esperar
echo "4. Esperando que los servicios se inicien..."
sleep 20

# Verificar estado
echo "5. Verificando estado..."
docker ps

echo ""
echo "6. Logs de n8n:"
docker-compose -f docker-compose-simple.yml logs n8n

echo ""
echo "=== Información de acceso ==="
echo "🌐 n8n: http://localhost:5680"
echo ""
echo "Si n8n responde, deberías poder acceder ahora" 