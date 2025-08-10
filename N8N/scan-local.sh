#!/bin/bash
# Script para escanear vulnerabilidades localmente antes del despliegue

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Escaneo de Vulnerabilidades Local ===${NC}"

# Verificar que Docker está corriendo
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker no está corriendo${NC}"
    exit 1
fi

# Verificar que Trivy está instalado
if ! command -v trivy &> /dev/null; then
    echo -e "${YELLOW}Instalando Trivy...${NC}"
    # Instalar Trivy (Linux/macOS)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install trivy
    else
        echo -e "${RED}Por favor instala Trivy manualmente: https://aquasecurity.github.io/trivy/latest/getting-started/installation/${NC}"
        exit 1
    fi
fi

# Construir imagen si no existe
IMAGE_NAME="my-n8n-image:latest"
if ! docker images | grep -q "my-n8n-image"; then
    echo -e "${YELLOW}Construyendo imagen Docker...${NC}"
    docker build -f Dockerfile.cloudrun -t $IMAGE_NAME .
fi

echo -e "${BLUE}=== Escaneando con Trivy ===${NC}"

# Crear directorio para resultados
mkdir -p scan-results

# Escanear vulnerabilidades críticas y altas
echo -e "${YELLOW}Escaneando vulnerabilidades CRÍTICAS y ALTAS...${NC}"
if trivy image --severity HIGH,CRITICAL --exit-code 1 --format json --output scan-results/trivy-critical.json $IMAGE_NAME; then
    echo -e "${GREEN}✅ No se encontraron vulnerabilidades críticas/altas${NC}"
else
    echo -e "${RED}❌ Se encontraron vulnerabilidades críticas/altas${NC}"
    echo -e "${YELLOW}Detalles guardados en: scan-results/trivy-critical.json${NC}"
    
    # Mostrar resumen
    if command -v jq &> /dev/null; then
        echo -e "${YELLOW}Resumen de vulnerabilidades:${NC}"
        jq -r '.Results[].Vulnerabilities[] | "  - \(.VulnerabilityID): \(.Title) (Severity: \(.Severity))"' scan-results/trivy-critical.json
    fi
fi

# Escanear vulnerabilidades medias (solo reporte)
echo -e "${YELLOW}Escaneando vulnerabilidades MEDIAS...${NC}"
trivy image --severity MEDIUM --exit-code 0 --format table --output scan-results/trivy-medium.txt $IMAGE_NAME

# Escanear vulnerabilidades bajas (solo reporte)
echo -e "${YELLOW}Escaneando vulnerabilidades BAJAS...${NC}"
trivy image --severity LOW --exit-code 0 --format table --output scan-results/trivy-low.txt $IMAGE_NAME

# Escanear configuración de seguridad
echo -e "${YELLOW}Escaneando configuración de seguridad...${NC}"
trivy config --severity HIGH,CRITICAL --exit-code 0 --format table --output scan-results/trivy-config.txt .

# Generar reporte completo
echo -e "${BLUE}=== Generando Reporte Completo ===${NC}"
{
    echo "=== Reporte de Vulnerabilidades - $(date) ==="
    echo "Imagen: $IMAGE_NAME"
    echo ""
    
    echo "=== Vulnerabilidades Críticas/Altas ==="
    if [ -f "scan-results/trivy-critical.json" ]; then
        if command -v jq &> /dev/null; then
            jq -r '.Results[].Vulnerabilities[] | "  - \(.VulnerabilityID): \(.Title) (Severity: \(.Severity))"' scan-results/trivy-critical.json
        else
            echo "  Instala 'jq' para ver detalles JSON"
        fi
    else
        echo "  ✅ No se encontraron vulnerabilidades críticas/altas"
    fi
    
    echo ""
    echo "=== Vulnerabilidades Medias ==="
    if [ -f "scan-results/trivy-medium.txt" ]; then
        cat scan-results/trivy-medium.txt
    fi
    
    echo ""
    echo "=== Vulnerabilidades Bajas ==="
    if [ -f "scan-results/trivy-low.txt" ]; then
        cat scan-results/trivy-low.txt
    fi
    
    echo ""
    echo "=== Configuración de Seguridad ==="
    if [ -f "scan-results/trivy-config.txt" ]; then
        cat scan-results/trivy-config.txt
    fi
    
} > scan-results/security-report.txt

echo -e "${GREEN}✅ Reporte completo guardado en: scan-results/security-report.txt${NC}"

# Mostrar resumen final
echo -e "${BLUE}=== Resumen del Escaneo ===${NC}"
echo -e "📁 Resultados guardados en: scan-results/"
echo -e "📄 Reporte completo: scan-results/security-report.txt"
echo -e "🔍 Para ver detalles: cat scan-results/security-report.txt"

# Verificar si hay vulnerabilidades críticas
if [ -f "scan-results/trivy-critical.json" ]; then
    echo -e "${RED}⚠️  Se encontraron vulnerabilidades críticas/altas${NC}"
    echo -e "${YELLOW}Revisa el reporte antes de desplegar a producción${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Imagen lista para despliegue${NC}"
fi 