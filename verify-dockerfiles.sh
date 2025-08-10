#!/bin/bash
# Script para verificar que los Dockerfiles están correctamente configurados

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Verificación de Dockerfiles ===${NC}"

# Función para verificar archivo
check_dockerfile() {
    local file=$1
    local name=$2
    
    echo -e "${YELLOW}Verificando $name...${NC}"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Archivo $file no encontrado${NC}"
        return 1
    fi
    
    # Verificar que usa Alpine
    if grep -q "FROM.*alpine" "$file"; then
        echo -e "${GREEN}✅ Usa imagen Alpine${NC}"
    else
        echo -e "${RED}❌ No usa imagen Alpine${NC}"
        return 1
    fi
    
    # Verificar que NO usa apt-get (Debian/Ubuntu)
    if grep -q "apt-get" "$file"; then
        echo -e "${RED}❌ Usa apt-get (Debian/Ubuntu) en imagen Alpine${NC}"
        return 1
    else
        echo -e "${GREEN}✅ No usa apt-get${NC}"
    fi
    
    # Verificar que usa apk (Alpine)
    if grep -q "apk add" "$file"; then
        echo -e "${GREEN}✅ Usa apk (Alpine)${NC}"
    else
        echo -e "${YELLOW}⚠️  No usa apk add${NC}"
    fi
    
    # Verificar instalación de Trivy
    if grep -q "trivy" "$file"; then
        if grep -q "wget.*trivy.*tar.gz" "$file"; then
            echo -e "${GREEN}✅ Instalación de Trivy correcta (Alpine)${NC}"
        else
            echo -e "${RED}❌ Instalación de Trivy incorrecta${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  No incluye Trivy${NC}"
    fi
    
    echo -e "${GREEN}✅ $name verificado correctamente${NC}"
    return 0
}

# Verificar todos los Dockerfiles
echo -e "${BLUE}Verificando Dockerfiles...${NC}"

errors=0

# Verificar Dockerfile.cloudrun
if check_dockerfile "Dockerfile.cloudrun" "Dockerfile.cloudrun"; then
    echo -e "${GREEN}✅ Dockerfile.cloudrun está correcto${NC}"
else
    echo -e "${RED}❌ Dockerfile.cloudrun tiene errores${NC}"
    ((errors++))
fi

echo ""

# Verificar Dockerfile.with-trivy
if check_dockerfile "Dockerfile.with-trivy" "Dockerfile.with-trivy"; then
    echo -e "${GREEN}✅ Dockerfile.with-trivy está correcto${NC}"
else
    echo -e "${RED}❌ Dockerfile.with-trivy tiene errores${NC}"
    ((errors++))
fi

echo ""

# Verificar Dockerfile original
if [ -f "Dockerfile" ]; then
    if check_dockerfile "Dockerfile" "Dockerfile"; then
        echo -e "${GREEN}✅ Dockerfile está correcto${NC}"
    else
        echo -e "${RED}❌ Dockerfile tiene errores${NC}"
        ((errors++))
    fi
else
    echo -e "${YELLOW}⚠️  Dockerfile no encontrado${NC}"
fi

echo ""

# Resumen
if [ $errors -eq 0 ]; then
    echo -e "${GREEN}=== Todos los Dockerfiles están correctos ===${NC}"
    echo -e "${GREEN}✅ Puedes proceder con la construcción${NC}"
else
    echo -e "${RED}=== Se encontraron $errors errores ===${NC}"
    echo -e "${RED}❌ Corrige los errores antes de construir${NC}"
    exit 1
fi

# Verificar que los scripts existen
echo -e "${BLUE}Verificando scripts...${NC}"

required_scripts=("startup.sh" "scan-internal.sh")
for script in "${required_scripts[@]}"; do
    if [ -f "$script" ]; then
        echo -e "${GREEN}✅ $script existe${NC}"
    else
        echo -e "${YELLOW}⚠️  $script no encontrado${NC}"
    fi
done

echo -e "${GREEN}=== Verificación completada ===${NC}" 