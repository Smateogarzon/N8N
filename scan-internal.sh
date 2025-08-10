#!/bin/bash
# Script para escaneo interno de vulnerabilidades dentro del contenedor

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Escaneo Interno de Vulnerabilidades ===${NC}"

# Verificar que Trivy está disponible
if ! command -v trivy &> /dev/null; then
    echo -e "${RED}Error: Trivy no está instalado en el contenedor${NC}"
    exit 1
fi

# Crear directorio para resultados
SCAN_DIR="/home/node/security-scans"
mkdir -p "$SCAN_DIR"

# Función para escanear sistema de archivos
scan_filesystem() {
    echo -e "${YELLOW}Escaneando sistema de archivos...${NC}"
    
    # Escanear directorio de n8n
    trivy fs --severity HIGH,CRITICAL --exit-code 0 --format json --output "$SCAN_DIR/fs-critical.json" /home/node/.n8n
    
    # Escanear configuración
    trivy config --severity HIGH,CRITICAL --exit-code 0 --format json --output "$SCAN_DIR/config-critical.json" /home/node
    
    echo -e "${GREEN}✅ Escaneo de sistema de archivos completado${NC}"
}

# Función para escanear paquetes instalados
scan_packages() {
    echo -e "${YELLOW}Escaneando paquetes instalados...${NC}"
    
    # Escanear paquetes del sistema
    trivy rootfs --severity HIGH,CRITICAL --exit-code 0 --format json --output "$SCAN_DIR/packages-critical.json" /
    
    echo -e "${GREEN}✅ Escaneo de paquetes completado${NC}"
}

# Función para generar reporte
generate_report() {
    echo -e "${BLUE}Generando reporte de seguridad...${NC}"
    
    {
        echo "=== Reporte de Seguridad Interno - $(date) ==="
        echo "Contenedor: $(hostname)"
        echo "Usuario: $(whoami)"
        echo "Directorio: $SCAN_DIR"
        echo ""
        
        # Verificar vulnerabilidades críticas en sistema de archivos
        if [ -f "$SCAN_DIR/fs-critical.json" ]; then
            VULN_COUNT=$(jq '.Results[].Vulnerabilities | length' "$SCAN_DIR/fs-critical.json" 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
            echo "Vulnerabilidades en sistema de archivos: $VULN_COUNT"
        fi
        
        # Verificar vulnerabilidades críticas en configuración
        if [ -f "$SCAN_DIR/config-critical.json" ]; then
            VULN_COUNT=$(jq '.Results[].Vulnerabilities | length' "$SCAN_DIR/config-critical.json" 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
            echo "Vulnerabilidades en configuración: $VULN_COUNT"
        fi
        
        # Verificar vulnerabilidades críticas en paquetes
        if [ -f "$SCAN_DIR/packages-critical.json" ]; then
            VULN_COUNT=$(jq '.Results[].Vulnerabilities | length' "$SCAN_DIR/packages-critical.json" 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
            echo "Vulnerabilidades en paquetes: $VULN_COUNT"
        fi
        
        echo ""
        echo "=== Información del Sistema ==="
        echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo "Node.js: $(node --version)"
        echo "npm: $(npm --version)"
        echo "n8n: $(n8n --version 2>/dev/null || echo 'No disponible')"
        
    } > "$SCAN_DIR/internal-security-report.txt"
    
    echo -e "${GREEN}✅ Reporte guardado en: $SCAN_DIR/internal-security-report.txt${NC}"
}

# Función para mostrar resultados
show_results() {
    echo -e "${BLUE}=== Resultados del Escaneo ===${NC}"
    
    if [ -f "$SCAN_DIR/internal-security-report.txt" ]; then
        cat "$SCAN_DIR/internal-security-report.txt"
    fi
    
    echo ""
    echo -e "${YELLOW}Archivos de resultados:${NC}"
    ls -la "$SCAN_DIR/"
}

# Ejecutar escaneos
scan_filesystem
scan_packages
generate_report
show_results

echo -e "${GREEN}=== Escaneo Interno Completado ===${NC}"
echo -e "📁 Resultados en: $SCAN_DIR"
echo -e "📄 Reporte: $SCAN_DIR/internal-security-report.txt" 