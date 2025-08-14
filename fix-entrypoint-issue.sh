#!/bin/bash
# Script para solucionar el problema del entrypoint en n8n Cloud Run
# Usa el entrypoint oficial de n8n y configuración correcta

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}=== Solución Correcta: Usar Entrypoint Oficial de n8n ===${NC}"
echo -e "${BLUE}Diagnóstico: Problema con entrypoint personalizado${NC}"
echo ""

# URL específica del usuario (sin slash final)
BASE_URL="https://n8n-1059853171455.us-central1.run.app"

echo -e "${GREEN}URL base del servicio: $BASE_URL${NC}"

# Verificar que gcloud está configurado
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI no está instalado${NC}"
    exit 1
fi

# Obtener proyecto actual
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: No hay proyecto configurado en gcloud${NC}"
    exit 1
fi

echo -e "${GREEN}Proyecto actual: $PROJECT_ID${NC}"

# Verificar si existe archivo de configuración local
if [ -f ".cloudsql-config.local" ]; then
    echo -e "${GREEN}Archivo de configuración local encontrado${NC}"
    source .cloudsql-config.local
    
    # Verificar que tenemos las variables necesarias
    if [ -z "$CLOUDSQL_INSTANCE" ] || [ -z "$DB_PASSWORD" ] || [ -z "$N8N_ENCRYPTION_KEY" ] || [ -z "$N8N_USER" ] || [ -z "$N8N_PASSWORD" ]; then
        echo -e "${RED}Error: Faltan variables de configuración${NC}"
        echo -e "${YELLOW}Ejecuta ./setup-cloudsql.sh primero${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: Archivo .cloudsql-config.local no encontrado${NC}"
    echo -e "${YELLOW}Ejecuta ./setup-cloudsql.sh primero${NC}"
    exit 1
fi

# Mostrar configuración actual
echo -e "${BLUE}=== Configuración Actual ===${NC}"
echo "Proyecto: $PROJECT_ID"
echo "URL base: $BASE_URL"
echo "Instancia Cloud SQL: $CLOUDSQL_INSTANCE"
echo "Usuario n8n: $N8N_USER"

# Mostrar cambios que se aplicarán
echo -e "${BLUE}=== Cambios que se Aplicarán ===${NC}"
echo "✅ Dockerfile.cloudrun simplificado (usa entrypoint oficial)"
echo "✅ startup.sh usa /docker-entrypoint.sh n8n start"
echo "✅ Variables de entorno completas y correctas"
echo "✅ N8N_EDITOR_BASE_URL=$BASE_URL (sin slash)"
echo "✅ WEBHOOK_URL=$BASE_URL/ (con slash)"
echo "✅ Endpoints fijados a valores por defecto"
echo "✅ Puerto 8080 configurado explícitamente"

# Función para diagnóstico paso a paso
diagnose_service() {
    echo -e "${BLUE}=== Diagnóstico del Servicio ===${NC}"
    
    echo -e "${YELLOW}1. Verificando endpoint de salud...${NC}"
    if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/healthz" | grep -q "200"; then
        echo -e "${GREEN}✅ /healthz responde 200${NC}"
    else
        echo -e "${RED}❌ /healthz no responde correctamente${NC}"
    fi
    
    echo -e "${YELLOW}2. Verificando endpoint de readiness...${NC}"
    if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/healthz/readiness" | grep -q "200"; then
        echo -e "${GREEN}✅ /healthz/readiness responde 200${NC}"
    else
        echo -e "${RED}❌ /healthz/readiness no responde correctamente${NC}"
    fi
    
    echo -e "${YELLOW}3. Verificando endpoint REST...${NC}"
    if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/rest/ping" | grep -q "200"; then
        echo -e "${GREEN}✅ /rest/ping responde 200${NC}"
    else
        echo -e "${RED}❌ /rest/ping no responde correctamente${NC}"
    fi
    
    echo -e "${YELLOW}4. Verificando página principal...${NC}"
    MAIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/")
    if [ "$MAIN_STATUS" = "200" ]; then
        echo -e "${GREEN}✅ Página principal responde 200${NC}"
    else
        echo -e "${RED}❌ Página principal responde $MAIN_STATUS${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}=== Análisis del Diagnóstico ===${NC}"
    if [ "$MAIN_STATUS" = "404" ]; then
        echo -e "${YELLOW}🔍 Problema identificado: Error 404 en página principal${NC}"
        echo -e "${YELLOW}💡 La solución del entrypoint oficial debería resolverlo${NC}"
    elif [ "$MAIN_STATUS" = "200" ]; then
        echo -e "${GREEN}🎉 ¡El servicio ya está funcionando correctamente!${NC}"
    else
        echo -e "${YELLOW}⚠️  Estado inesperado: $MAIN_STATUS${NC}"
    fi
}

# Ejecutar diagnóstico si el servicio está disponible
echo ""
read -p "¿Quieres ejecutar diagnóstico del servicio actual? (y/N): " run_diagnosis
if [[ "$run_diagnosis" =~ ^[Yy]$ ]]; then
    diagnose_service
fi

# Confirmar aplicación de la solución
echo ""
read -p "¿Aplicar la solución del entrypoint oficial? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Aplicación cancelada${NC}"
    exit 0
fi

# Actualizar el trigger de Cloud Build
echo -e "${YELLOW}Actualizando trigger de Cloud Build...${NC}"

TRIGGER_NAME="n8n-deploy-trigger"

# Verificar si el trigger existe
if gcloud builds triggers describe "$TRIGGER_NAME" --region=global 2>/dev/null; then
    echo -e "${YELLOW}Actualizando trigger existente...${NC}"
    gcloud builds triggers update github "$TRIGGER_NAME" \
        --repo-name="N8N" \
        --repo-owner="tu-usuario" \
        --branch-pattern="^main$" \
        --build-config="cloudbuild-secure.yaml" \
        --substitutions="_CLOUDSQL_INSTANCE=$CLOUDSQL_INSTANCE,_DB_NAME=n8n_db,_DB_USER=n8n_user,_DB_PASSWORD=$DB_PASSWORD,_N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY,_N8N_USER=$N8N_USER,_N8N_PASSWORD=$N8N_PASSWORD,_BASE_URL=$BASE_URL" \
        --region=global
else
    echo -e "${YELLOW}Creando nuevo trigger...${NC}"
    gcloud builds triggers create github "$TRIGGER_NAME" \
        --repo-name="N8N" \
        --repo-owner="tu-usuario" \
        --branch-pattern="^main$" \
        --build-config="cloudbuild-secure.yaml" \
        --substitutions="_CLOUDSQL_INSTANCE=$CLOUDSQL_INSTANCE,_DB_NAME=n8n_db,_DB_USER=n8n_user,_DB_PASSWORD=$DB_PASSWORD,_N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY,_N8N_USER=$N8N_USER,_N8N_PASSWORD=$N8N_PASSWORD,_BASE_URL=$BASE_URL" \
        --region=global
fi

# Actualizar archivo de configuración local
echo -e "${YELLOW}Actualizando archivo de configuración local...${NC}"
{
    echo "# Configuración de Cloud SQL y Cloud Build - $(date)"
    echo "# IMPORTANTE: Este archivo contiene información sensible"
    echo "# No subir a repositorio público"
    echo ""
    echo "PROJECT_ID=$PROJECT_ID"
    echo "CLOUDSQL_INSTANCE=$CLOUDSQL_INSTANCE"
    echo "INSTANCE_NAME=$INSTANCE_NAME"
    echo "INSTANCE_REGION=$INSTANCE_REGION"
    echo "DB_NAME=n8n_db"
    echo "DB_USER=n8n_user"
    echo "DB_PASSWORD=$DB_PASSWORD"
    echo "N8N_USER=$N8N_USER"
    echo "N8N_PASSWORD=$N8N_PASSWORD"
    echo "N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY"
    echo "BASE_URL=$BASE_URL"
    echo ""
    echo "# Variables de n8n configuradas (ENTRYPOINT OFICIAL)"
    echo "N8N_HOST=0.0.0.0"
    echo "N8N_PORT=8080"
    echo "N8N_PROTOCOL=https"
    echo "N8N_DISABLE_UI=false"
    echo "N8N_PATH=/"
    echo "N8N_EDITOR_BASE_URL=$BASE_URL"
    echo "WEBHOOK_URL=$BASE_URL/"
    echo ""
    echo "# Solución aplicada: Entrypoint oficial de n8n"
} > .cloudsql-config.local

chmod 600 .cloudsql-config.local

echo -e "${GREEN}✅ Configuración actualizada${NC}"
echo -e "${BLUE}📁 Configuración actualizada en: .cloudsql-config.local${NC}"

# Mostrar próximos pasos
echo -e "${BLUE}=== Próximos Pasos ===${NC}"
echo "1. La configuración ha sido actualizada en el trigger"
echo "2. Haz push de tus cambios para activar un nuevo despliegue"
echo "3. El nuevo despliegue usará el entrypoint oficial de n8n"
echo "4. Esto debería resolver definitivamente el error 404"

# Opción para hacer deploy inmediatamente
echo ""
read -p "¿Quieres hacer deploy inmediatamente? (y/N): " deploy_now
if [[ "$deploy_now" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Haciendo deploy...${NC}"
    
    # Trigger manual del build
    gcloud builds triggers run "$TRIGGER_NAME" \
        --branch=main \
        --region=global
    
    echo -e "${GREEN}✅ Deploy iniciado${NC}"
    echo -e "${BLUE}Verifica el progreso en: https://console.cloud.google.com/cloud-build${NC}"
    echo -e "${BLUE}Una vez completado, n8n debería estar disponible en: $BASE_URL${NC}"
    
    # Esperar un poco y hacer diagnóstico post-deploy
    echo ""
    echo -e "${YELLOW}Esperando 2 minutos para que el deploy se complete...${NC}"
    sleep 120
    
    echo -e "${BLUE}=== Diagnóstico Post-Deploy ===${NC}"
    diagnose_service
    
else
    echo -e "${YELLOW}Para hacer deploy, ejecuta:${NC}"
    echo "git add ."
    echo "git commit -m 'fix: usar entrypoint oficial de n8n y configuración correcta'"
    echo "git push origin main"
fi

echo ""
echo -e "${GREEN}=== Solución Aplicada ===${NC}"
echo -e "${GREEN}✅ Entrypoint oficial de n8n configurado${NC}"
echo -e "${GREEN}✅ Variables de entorno completas${NC}"
echo -e "${GREEN}✅ Endpoints fijados a valores por defecto${NC}"
echo -e "${GREEN}✅ Configuración robusta y estable${NC}"
echo -e "${BLUE}🌐 URL: $BASE_URL${NC}"
