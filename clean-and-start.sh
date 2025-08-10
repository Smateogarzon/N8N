#!/bin/bash
set -e

echo "=== Limpiando y reiniciando n8n ==="

# Detener y eliminar contenedores y volúmenes
echo "Deteniendo contenedores..."
docker-compose down -v

# Eliminar imágenes si existen
echo "Limpiando imágenes..."
docker rmi n8n:latest 2>/dev/null || true
docker rmi n8n_n8n:latest 2>/dev/null || true

# Limpiar volúmenes huérfanos
echo "Limpiando volúmenes..."
docker volume prune -f

# Construir y ejecutar
echo "Construyendo y ejecutando n8n..."
docker-compose up -d --build

echo "✅ n8n iniciado correctamente"
echo "🌐 Accede a: http://localhost:5679"
echo "📊 Usuario: admin"
echo "🔑 Contraseña: tu_password" 