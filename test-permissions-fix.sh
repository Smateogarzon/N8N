#!/bin/bash
# Script para probar la corrección de permisos en Dockerfiles

set -e

echo "=== Probando corrección de permisos ==="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para verificar que no hay USER node en los Dockerfiles
check_dockerfiles() {
    echo -e "${YELLOW}Verificando Dockerfiles...${NC}"
    
    # Verificar Dockerfile principal
    if grep -q "^USER node" Dockerfile; then
        echo -e "${RED}❌ ERROR: Dockerfile aún contiene 'USER node'${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Dockerfile: OK - No contiene 'USER node'${NC}"
    fi
    
    # Verificar Dockerfile.cloudrun
    if grep -q "^USER node" Dockerfile.cloudrun; then
        echo -e "${RED}❌ ERROR: Dockerfile.cloudrun aún contiene 'USER node'${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Dockerfile.cloudrun: OK - No contiene 'USER node'${NC}"
    fi
    
    # Verificar Dockerfile.with-trivy
    if grep -q "^USER node" Dockerfile.with-trivy; then
        echo -e "${RED}❌ ERROR: Dockerfile.with-trivy aún contiene 'USER node'${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Dockerfile.with-trivy: OK - No contiene 'USER node'${NC}"
    fi
    
    return 0
}

# Función para verificar que los scripts de entrada están correctos
check_entrypoint_scripts() {
    echo -e "${YELLOW}Verificando scripts de entrada...${NC}"
    
    # Verificar que docker-entrypoint.sh usa gosu
    if grep -q "gosu node" docker-entrypoint.sh; then
        echo -e "${GREEN}✅ docker-entrypoint.sh: OK - Usa gosu para bajar privilegios${NC}"
    else
        echo -e "${RED}❌ ERROR: docker-entrypoint.sh no usa gosu${NC}"
        return 1
    fi
    
    # Verificar que startup.sh usa gosu
    if grep -q "gosu node" startup.sh; then
        echo -e "${GREEN}✅ startup.sh: OK - Usa gosu para bajar privilegios${NC}"
    else
        echo -e "${RED}❌ ERROR: startup.sh no usa gosu${NC}"
        return 1
    fi
    
    return 0
}

# Función para probar build local
test_local_build() {
    echo -e "${YELLOW}Probando build local...${NC}"
    
    # Limpiar imágenes anteriores
    docker rmi n8n-test-permissions 2>/dev/null || true
    
    # Build de prueba
    if docker build -t n8n-test-permissions .; then
        echo -e "${GREEN}✅ Build local: OK${NC}"
        return 0
    else
        echo -e "${RED}❌ ERROR: Build local falló${NC}"
        return 1
    fi
}

# Función para probar que el entrypoint se ejecuta como root
test_entrypoint_permissions() {
    echo -e "${YELLOW}Probando permisos del entrypoint...${NC}"
    
    # Crear contenedor temporal para probar
    container_id=$(docker create n8n-test-permissions)
    
    # Verificar que el entrypoint se ejecuta como root durante la inicialización
    # El script debe poder crear directorios y hacer chown exitosamente
    if docker run --rm -e DB_TYPE=sqlite n8n-test-permissions sh -c "echo 'Test completado'" 2>&1 | grep -q "chown.*Operation not permitted"; then
        echo -e "${RED}❌ ERROR: Entrypoint no tiene permisos de root para chown${NC}"
        result=1
    else
        echo -e "${GREEN}✅ Entrypoint: OK - Tiene permisos de root para operaciones privilegiadas${NC}"
        result=0
    fi
    
    # Limpiar
    docker rm $container_id 2>/dev/null || true
    
    return $result
}

# Ejecutar todas las verificaciones
main() {
    local exit_code=0
    
    check_dockerfiles || exit_code=1
    check_entrypoint_scripts || exit_code=1
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${YELLOW}¿Quieres probar el build local? (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            test_local_build || exit_code=1
            
            if [ $exit_code -eq 0 ]; then
                test_entrypoint_permissions || exit_code=1
            fi
        fi
    fi
    
    echo -e "\n${YELLOW}=== Resumen ===${NC}"
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ Todas las verificaciones pasaron${NC}"
        echo -e "${GREEN}La corrección de permisos está lista para usar${NC}"
    else
        echo -e "${RED}❌ Algunas verificaciones fallaron${NC}"
        echo -e "${RED}Revisa los errores arriba${NC}"
    fi
    
    return $exit_code
}

# Ejecutar script
main "$@"
