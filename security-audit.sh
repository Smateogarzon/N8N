#!/bin/bash
# Script de auditoría de seguridad completa
# Combina escaneo externo e interno para análisis exhaustivo

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}=== Auditoría de Seguridad Completa ===${NC}"
echo -e "${BLUE}Fecha: $(date)${NC}"
echo ""

# Configuración
IMAGE_NAME="my-n8n-image:latest"
AUDIT_DIR="security-audit-$(date +%Y%m%d-%H%M%S)"
EXTERNAL_SCAN=true
INTERNAL_SCAN=true

# Función para mostrar progreso
show_progress() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] $1${NC}"
}

# Función para mostrar éxito
show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Función para mostrar error
show_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Crear directorio de auditoría
mkdir -p "$AUDIT_DIR"
show_success "Directorio de auditoría creado: $AUDIT_DIR"

# ===== FASE 1: ESCANEO EXTERNO =====
if [ "$EXTERNAL_SCAN" = true ]; then
    echo -e "${BLUE}=== FASE 1: Escaneo Externo ===${NC}"
    
    show_progress "Verificando que Docker está corriendo..."
    if ! docker info > /dev/null 2>&1; then
        show_error "Docker no está corriendo"
        exit 1
    fi
    show_success "Docker está corriendo"
    
    show_progress "Verificando imagen..."
    if ! docker images | grep -q "$IMAGE_NAME"; then
        show_progress "Construyendo imagen..."
        docker build -f Dockerfile.cloudrun -t "$IMAGE_NAME" .
        show_success "Imagen construida"
    else
        show_success "Imagen encontrada"
    fi
    
    show_progress "Ejecutando escaneo externo con Trivy..."
    
    # Escaneo crítico/alto
    if trivy image --severity HIGH,CRITICAL --exit-code 0 --format json --output "$AUDIT_DIR/external-critical.json" "$IMAGE_NAME"; then
        show_success "No se encontraron vulnerabilidades críticas/altas"
    else
        show_error "Se encontraron vulnerabilidades críticas/altas"
        VULN_COUNT=$(jq '.Results[].Vulnerabilities | length' "$AUDIT_DIR/external-critical.json" 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        echo -e "${RED}Vulnerabilidades encontradas: $VULN_COUNT${NC}"
    fi
    
    # Escaneo medio/bajo (solo reporte)
    trivy image --severity MEDIUM,LOW --exit-code 0 --format table --output "$AUDIT_DIR/external-all.txt" "$IMAGE_NAME"
    
    # Escaneo de configuración
    trivy config --severity HIGH,CRITICAL --exit-code 0 --format table --output "$AUDIT_DIR/external-config.txt" .
    
    show_success "Escaneo externo completado"
fi

# ===== FASE 2: ESCANEO INTERNO =====
if [ "$INTERNAL_SCAN" = true ]; then
    echo -e "${BLUE}=== FASE 2: Escaneo Interno ===${NC}"
    
    show_progress "Levantando entorno con capacidades de escaneo..."
    
    # Detener contenedores existentes
    docker-compose -f docker-compose-with-scanning.yml down 2>/dev/null || true
    
    # Levantar entorno
    docker-compose -f docker-compose-with-scanning.yml up -d n8n
    
    # Esperar a que n8n esté listo
    show_progress "Esperando a que n8n esté listo..."
    sleep 10
    
    # Ejecutar escaneo interno
    show_progress "Ejecutando escaneo interno..."
    if docker exec n8n-with-scanning /usr/local/bin/scan-internal.sh; then
        show_success "Escaneo interno completado"
        
        # Copiar resultados
        if [ -d "security-scans" ]; then
            cp -r security-scans/* "$AUDIT_DIR/"
            show_success "Resultados copiados a $AUDIT_DIR"
        fi
    else
        show_error "Error en escaneo interno"
    fi
    
    # Limpiar
    show_progress "Limpiando entorno..."
    docker-compose -f docker-compose-with-scanning.yml down
    show_success "Entorno limpiado"
fi

# ===== FASE 3: ANÁLISIS Y REPORTE =====
echo -e "${BLUE}=== FASE 3: Análisis y Reporte ===${NC}"

show_progress "Generando reporte de auditoría..."

# Crear reporte principal
{
    echo "=== REPORTE DE AUDITORÍA DE SEGURIDAD ==="
    echo "Fecha: $(date)"
    echo "Imagen: $IMAGE_NAME"
    echo "Directorio: $AUDIT_DIR"
    echo ""
    
    echo "=== RESUMEN EJECUTIVO ==="
    
    # Contar vulnerabilidades externas
    if [ -f "$AUDIT_DIR/external-critical.json" ]; then
        EXT_VULN_COUNT=$(jq '.Results[].Vulnerabilities | length' "$AUDIT_DIR/external-critical.json" 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        echo "Vulnerabilidades críticas/altas (externas): $EXT_VULN_COUNT"
    else
        echo "Vulnerabilidades críticas/altas (externas): 0"
    fi
    
    # Contar vulnerabilidades internas
    if [ -f "$AUDIT_DIR/internal-security-report.txt" ]; then
        echo "Escaneo interno: Completado"
    else
        echo "Escaneo interno: No disponible"
    fi
    
    echo ""
    echo "=== RECOMENDACIONES ==="
    
    if [ "$EXT_VULN_COUNT" -gt 0 ]; then
        echo "❌ CORREGIR VULNERABILIDADES CRÍTICAS ANTES DEL DESPLIEGUE"
        echo "   - Revisar: $AUDIT_DIR/external-critical.json"
        echo "   - Actualizar imagen base si es necesario"
    else
        echo "✅ No se encontraron vulnerabilidades críticas/altas"
    fi
    
    echo ""
    echo "=== ARCHIVOS DE RESULTADOS ==="
    echo "Reporte completo: $AUDIT_DIR/audit-report.txt"
    echo "Escaneo externo: $AUDIT_DIR/external-all.txt"
    echo "Configuración: $AUDIT_DIR/external-config.txt"
    echo "Escaneo interno: $AUDIT_DIR/internal-security-report.txt"
    
} > "$AUDIT_DIR/audit-report.txt"

show_success "Reporte generado: $AUDIT_DIR/audit-report.txt"

# Mostrar resumen
echo -e "${PURPLE}=== RESUMEN DE AUDITORÍA ===${NC}"
cat "$AUDIT_DIR/audit-report.txt"

# Verificar si hay vulnerabilidades críticas
if [ "$EXT_VULN_COUNT" -gt 0 ]; then
    echo -e "${RED}⚠️  SE ENCONTRARON VULNERABILIDADES CRÍTICAS${NC}"
    echo -e "${YELLOW}Revisa el reporte antes de proceder con el despliegue${NC}"
    exit 1
else
    echo -e "${GREEN}✅ AUDITORÍA COMPLETADA - IMAGEN LISTA PARA DESPLIEGUE${NC}"
fi

echo -e "${BLUE}📁 Resultados completos en: $AUDIT_DIR${NC}" 