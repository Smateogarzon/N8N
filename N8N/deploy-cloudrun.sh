#!/bin/bash
# Script de despliegue para Google Cloud Run

set -e

# Configuración
PROJECT_ID="your-project-id"
REGION="us-central1"
SERVICE_NAME="n8n"
IMAGE_NAME="gcr.io/$PROJECT_ID/n8n"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Desplegando n8n a Google Cloud Run ===${NC}"

# Verificar que gcloud está configurado
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI no está instalado${NC}"
    exit 1
fi

# Verificar que estamos en el proyecto correcto
CURRENT_PROJECT=$(gcloud config get-value project)
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo -e "${YELLOW}Cambiando al proyecto: $PROJECT_ID${NC}"
    gcloud config set project $PROJECT_ID
fi

# Habilitar APIs necesarias
echo -e "${YELLOW}Habilitando APIs necesarias...${NC}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Construir imagen
echo -e "${YELLOW}Construyendo imagen Docker...${NC}"
gcloud builds submit --tag $IMAGE_NAME --file Dockerfile.cloudrun .

# Obtener la URL de la imagen construida
IMAGE_URL=$(gcloud container images list-tags $IMAGE_NAME --limit=1 --format="value(digest)")
FULL_IMAGE_URL="$IMAGE_NAME@$IMAGE_URL"

echo -e "${GREEN}Imagen construida: $FULL_IMAGE_URL${NC}"

# Desplegar a Cloud Run
echo -e "${YELLOW}Desplegando a Cloud Run...${NC}"
gcloud run deploy $SERVICE_NAME \
    --image $FULL_IMAGE_URL \
    --region $REGION \
    --platform managed \
    --allow-unauthenticated \
    --memory 2Gi \
    --cpu 2 \
    --max-instances 10 \
    --timeout 300 \
    --concurrency 80 \
    --set-env-vars="DB_TYPE=postgresdb,DB_POSTGRESDB_HOST=${DB_HOST},DB_POSTGRESDB_DATABASE=${DB_NAME},DB_POSTGRESDB_USER=${DB_USER},DB_POSTGRESDB_PASSWORD=${DB_PASSWORD},N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY},N8N_BASIC_AUTH_ACTIVE=true,N8N_BASIC_AUTH_USER=${N8N_USER},N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD},NODE_ENV=production"

# Obtener la URL del servicio
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")

echo -e "${GREEN}=== Despliegue completado ===${NC}"
echo -e "${GREEN}URL del servicio: $SERVICE_URL${NC}"
echo -e "${YELLOW}Para ver logs: gcloud logs tail --service=$SERVICE_NAME --region=$REGION${NC}"

# Mostrar información de configuración
echo -e "${YELLOW}=== Configuración actual ===${NC}"
echo "Proyecto: $PROJECT_ID"
echo "Región: $REGION"
echo "Servicio: $SERVICE_NAME"
echo "URL: $SERVICE_URL"
echo "Memoria: 2Gi"
echo "CPU: 2"
echo "Máx instancias: 10"
echo "Timeout: 300s"
echo "Concurrencia: 80" 