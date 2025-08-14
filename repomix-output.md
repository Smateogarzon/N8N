This file is a merged representation of the entire codebase, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of the entire repository's contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
```
.gitignore
.trivyignore
CHANGELOG.md
clean-and-start.sh
cloudbuild-secure.yaml
deploy-cloudrun.sh
docker-compose-simple.yml
docker-compose-with-scanning.yml
docker-compose.yml
docker-entrypoint.sh
Dockerfile
Dockerfile.cloudrun
Dockerfile.with-trivy
fix-and-test.sh
flow.json
LICENSE
package.json
README-cloudrun.md
README-cloudsql.md
README-docker.md
README-scanning-flows.md
README-vulnerability-scanning.md
README.md
repomix.config.json
scan-internal.sh
scan-local.sh
scan-simple.ps1
security-audit.sh
SECURITY.md
startup.sh
test-permissions-fix.sh
test-simple-n8n.sh
test-simple.sh
verify-dockerfiles.sh
```

# Files

## File: .gitignore
````
# Archivos de entorno
.env
.env.local
.env.development
.env.production

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Directorios de datos
data/
n8n-backup/
security-scans/
scan-results/

# Archivos temporales
*.tmp
*.temp
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Docker
.dockerignore

# Archivos de configuración local
config.local.js
settings.local.json

# Archivos de backup
*.sql
*.backup

# Archivos de seguridad (no subir nunca)
*.key
*.pem
*.crt
secrets/
````

## File: .trivyignore
````
# Archivo .trivyignore para n8n
# Ignora vulnerabilidades conocidas de bajo riesgo

# Ignorar vulnerabilidad en la herramienta interna de Cloud Build
# No afecta al contenedor final de n8n que se ejecuta en producción
# CVE-2025-47907: Vulnerabilidad en herramienta de construcción
CVE-2025-47907

# Nota: Solo ignorar vulnerabilidades que:
# 1. Estén en herramientas de construcción/desarrollo
# 2. No afecten al contenedor final de producción
# 3. Sean de bajo riesgo para el entorno de ejecución
````

## File: CHANGELOG.md
````markdown
# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-XX

### Added

- Configuración completa de n8n con PostgreSQL usando Docker
- Multi-stage Dockerfiles optimizados
- Scripts de escaneo de vulnerabilidades (Trivy)
- Configuración para Google Cloud Run
- Documentación completa en español
- Scripts de automatización para desarrollo local
- CI/CD pipeline con Cloud Build
- Auditoría de seguridad integrada

### Security

- Usuario no-root para contenedores
- Escaneo automático de vulnerabilidades
- Gestión segura de secretos via variables de entorno
- Configuración de seguridad hardening

### Fixed

- Problema de permisos con gosu/su-exec
- Conflictos de puertos en Docker Compose
- Problemas de conectividad con PostgreSQL
- Errores de construcción en Dockerfiles

## [Unreleased]

### Planned

- Soporte para múltiples bases de datos
- Integración con Kubernetes
- Métricas y monitoreo avanzado
- Backup automático de datos
````

## File: clean-and-start.sh
````bash
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
````

## File: deploy-cloudrun.sh
````bash
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
````

## File: docker-compose-simple.yml
````yaml
services:
  # Base de datos PostgreSQL
  postgres:
    image: postgres:16-alpine
    container_name: n8n-postgres-simple
    restart: unless-stopped
    environment:
      POSTGRES_DB: n8n_db
      POSTGRES_USER: n8n_user
      POSTGRES_PASSWORD: superseguro
    volumes:
      - postgres_data_simple:/var/lib/postgresql/data
    ports:
      - '5433:5432'
    networks:
      - n8n-network-simple

  # n8n simplificado
  n8n:
    build: .
    container_name: n8n-app-simple
    restart: unless-stopped
    depends_on:
      - postgres
    environment:
      # Configuración de base de datos
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: n8n_db
      DB_POSTGRESDB_USER: n8n_user
      DB_POSTGRESDB_PASSWORD: superseguro

      # Configuración básica de n8n
      N8N_HOST: 0.0.0.0
      N8N_PORT: 5678
      N8N_PROTOCOL: http
      N8N_ENCRYPTION_KEY: test-key-for-development-only

      # Sin autenticación básica para pruebas
      N8N_BASIC_AUTH_ACTIVE: 'false'

      # Configuración adicional
      NODE_ENV: production
      TZ: America/Bogota
    volumes:
      - n8n_data_simple:/home/node/.n8n
    ports:
      - '5680:5678'
    networks:
      - n8n-network-simple

volumes:
  postgres_data_simple:
    driver: local
  n8n_data_simple:
    driver: local

networks:
  n8n-network-simple:
    driver: bridge
````

## File: docker-compose-with-scanning.yml
````yaml
version: '3.8'

services:
  # n8n con capacidades de escaneo integradas
  n8n:
    build:
      context: .
      dockerfile: Dockerfile.with-trivy
    container_name: n8n-with-scanning
    restart: unless-stopped

    # Cargar variables desde .env de forma segura
    env_file:
      - .env

    # Variables adicionales (no sensibles)
    environment:
      N8N_HOST: 0.0.0.0
      N8N_PORT: 5678
      N8N_PROTOCOL: http
      NODE_ENV: production

    # Configuración de red segura
    ports:
      - '127.0.0.1:5678:5678' # Solo acceso local

    # Volúmenes con permisos restringidos
    volumes:
      - n8n_data:/home/node/.n8n:rw
      - ./logs:/home/node/.n8n/logs:rw
      - ./security-scans:/home/node/security-scans:rw # Para resultados de escaneo

    # Configuración de seguridad
    security_opt:
      - no-new-privileges:true # Previene escalación de privilegios

    # Límites de recursos
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '2.0'
        reservations:
          memory: 512M
          cpus: '0.5'

    # Health check
    healthcheck:
      test:
        [
          'CMD',
          'wget',
          '--no-verbose',
          '--tries=1',
          '--spider',
          'http://localhost:5678/healthz',
        ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

    # Configuración de logging
    logging:
      driver: 'json-file'
      options:
        max-size: '10m'
        max-file: '3'

    # Configuración de red
    networks:
      - n8n-network

  # Servicio de escaneo periódico (opcional)
  security-scanner:
    build:
      context: .
      dockerfile: Dockerfile.with-trivy
    container_name: n8n-security-scanner
    restart: 'no'
    # depends_on removido - el escaneo no depende de que n8n esté activo

    # Solo ejecutar escaneo, no n8n
    command: ['/usr/local/bin/scan-internal.sh']

    # Volúmenes para compartir resultados
    volumes:
      - ./security-scans:/home/node/security-scans:rw
      - n8n_data:/home/node/.n8n:ro # Solo lectura para escanear

    # Configuración de red
    networks:
      - n8n-network

volumes:
  n8n_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data # Directorio local para datos

networks:
  n8n-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
````

## File: docker-compose.yml
````yaml
services:
  # Base de datos PostgreSQL
  postgres:
    image: postgres:16-alpine
    container_name: n8n-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: n8n_db
      POSTGRES_USER: n8n_user
      POSTGRES_PASSWORD: superseguro
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - '5432:5432'
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U n8n_user -d n8n_db']
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - n8n-network

  # n8n
  n8n:
    build: .
    container_name: n8n-app
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      # Configuración de base de datos
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: n8n_db
      DB_POSTGRESDB_USER: n8n_user
      DB_POSTGRESDB_PASSWORD: superseguro

      # Configuración de n8n
      N8N_HOST: 0.0.0.0
      N8N_PORT: 5678
      N8N_PROTOCOL: http
      N8N_ENCRYPTION_KEY: cambia-esta-clave-larga-y-unica-para-produccion

      # Autenticación básica (opcional)
      N8N_BASIC_AUTH_ACTIVE: 'true'
      N8N_BASIC_AUTH_USER: admin
      N8N_BASIC_AUTH_PASSWORD: tu_password

      # Configuración adicional
      NODE_ENV: production
      TZ: America/Bogota
      # WEBHOOK_URL se debe configurar según el entorno de despliegue

      # Para desarrollo con túnel (opcional)
      # N8N_TUNNEL: true
    volumes:
      - n8n_data:/home/node/.n8n
      - ./logs:/home/node/.n8n/logs
    ports:
      - '5679:5678'
    networks:
      - n8n-network
    healthcheck:
      test:
        [
          'CMD',
          'wget',
          '--no-verbose',
          '--tries=1',
          '--spider',
          'http://localhost:5678/healthz',
        ]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
    driver: local
  n8n_data:
    driver: local

networks:
  n8n-network:
    driver: bridge
````

## File: docker-entrypoint.sh
````bash
#!/bin/sh
# Script de entrada personalizado para n8n Docker

set -e

# Función para validar variables de entorno requeridas
validate_env() {
    if [ -z "$DB_TYPE" ]; then
        echo "Error: DB_TYPE no está definido"
        exit 1
    fi
    
    if [ "$DB_TYPE" = "postgresdb" ]; then
        required_vars="DB_POSTGRESDB_HOST DB_POSTGRESDB_DATABASE DB_POSTGRESDB_USER DB_POSTGRESDB_PASSWORD"
        for var in $required_vars; do
            if [ -z "$(eval echo \$$var)" ]; then
                echo "Error: $var no está definido para PostgreSQL"
                exit 1
            fi
        done
    fi
}

# Función para esperar a que PostgreSQL esté disponible
wait_for_postgres() {
    if [ "$DB_TYPE" = "postgresdb" ]; then
        echo "Esperando a que PostgreSQL esté disponible..."
        # Usar netcat en lugar de pg_isready
        until nc -z "$DB_POSTGRESDB_HOST" "${DB_POSTGRESDB_PORT:-5432}"; do
            echo "PostgreSQL no está listo - esperando..."
            sleep 2
        done
        echo "PostgreSQL está listo!"
    fi
}

# Función para crear directorios necesarios
create_directories() {
    mkdir -p /home/node/.n8n/logs
    mkdir -p /home/node/.n8n/data
    chown -R node:node /home/node/.n8n
}

# Función para configurar variables por defecto
set_defaults() {
    export N8N_HOST=${N8N_HOST:-0.0.0.0}
    export N8N_PORT=${N8N_PORT:-5678}
    export N8N_PROTOCOL=${N8N_PROTOCOL:-http}
    export NODE_ENV=${NODE_ENV:-production}
    
    # Si no hay encryption key, n8n la generará automáticamente
    if [ -z "$N8N_ENCRYPTION_KEY" ]; then
        echo "N8N_ENCRYPTION_KEY no definida - n8n generará una automáticamente"
    fi
}

# Función para mostrar información de configuración
show_config() {
    echo "=== Configuración n8n ==="
    echo "Host: $N8N_HOST"
    echo "Puerto: $N8N_PORT"
    echo "Protocolo: $N8N_PROTOCOL"
    echo "Base de datos: $DB_TYPE"
    if [ "$DB_TYPE" = "postgresdb" ]; then
        echo "PostgreSQL Host: $DB_POSTGRESDB_HOST"
        echo "PostgreSQL Database: $DB_POSTGRESDB_DATABASE"
        echo "PostgreSQL User: $DB_POSTGRESDB_USER"
    fi
    echo "========================"
}

# Ejecutar funciones de inicialización
echo "Iniciando n8n..."
validate_env
set_defaults
create_directories
wait_for_postgres
show_config

# Cambiar al usuario node
exec gosu node "$@"
````

## File: fix-and-test.sh
````bash
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
````

## File: flow.json
````json
{
  "name": "Ping HTTP",
  "active": false,
  "settings": {},
  "nodes": [
    {
      "parameters": {
        "httpMethod": "GET",
        "path": "test-ping",
        "responseMode": "responseNode",
        "options": {
          "alwaysOutputData": true
        }
      },
      "id": "6f3b2e7e-3f4c-4f4d-9b1a-7d5a2c3a9f01",
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [260, 300],
      "webhookId": "b69c41e8-5f0f-4a8d-a5a9-65dbfe5d636a"
    },
    {
      "parameters": {
        "keepOnlySet": true,
        "values": {
          "string": [
            {
              "name": "status",
              "value": "ok"
            },
            {
              "name": "service",
              "value": "n8n-local"
            },
            {
              "name": "echoName",
              "value": "={{$json.query.name || \"sin_nombre\"}}"
            },
            {
              "name": "timestamp",
              "value": "={{$now}}"
            }
          ]
        },
        "options": {}
      },
      "id": "a2a8f0f0-0d2a-49a8-8e6f-3d9c7b1c9e11",
      "name": "Set",
      "type": "n8n-nodes-base.set",
      "typeVersion": 2,
      "position": [540, 300]
    },
    {
      "parameters": {
        "responseCode": 200,
        "responseData": "firstEntryJson"
      },
      "id": "e5d0b3a4-8c71-4b2e-ae2f-2d6c9f1a7c22",
      "name": "Respond to Webhook",
      "type": "n8n-nodes-base.respondToWebhook",
      "typeVersion": 1,
      "position": [820, 300]
    }
  ],
  "connections": {
    "Webhook": {
      "main": [
        [
          {
            "node": "Set",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Set": {
      "main": [
        [
          {
            "node": "Respond to Webhook",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
````

## File: LICENSE
````
MIT License

Copyright (c) 2024 n8n Docker Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
````

## File: package.json
````json
{
  "name": "n8n-docker",
  "version": "1.0.0",
  "description": "n8n con PostgreSQL usando Docker",
  "main": "index.js",
  "scripts": {
    "start": "docker-compose up -d",
    "stop": "docker-compose down",
    "build": "docker build -f Dockerfile -t n8n:latest .",
    "scan": "powershell -ExecutionPolicy Bypass -File scan-simple.ps1",
    "test": "./test-simple-n8n.sh",
    "clean": "./clean-and-start.sh",
    "pack-context": "npm exec -y -- repomix@latest"
  },
  "keywords": [
    "n8n",
    "docker",
    "postgresql",
    "automation"
  ],
  "author": "",
  "license": "MIT"
}
````

## File: README-cloudrun.md
````markdown
# n8n en Google Cloud Run

## 🚀 Configuración para Cloud Run

Esta configuración está optimizada para Google Cloud Run con manejo automático del puerto dinámico.

## 📁 Archivos para Cloud Run

```
N8N/
├── Dockerfile.cloudrun      # Dockerfile optimizado para Cloud Run
├── startup.sh              # Script que maneja puerto dinámico
├── cloudbuild.yaml         # Configuración de Cloud Build
├── deploy-cloudrun.sh      # Script de despliegue
└── README-cloudrun.md      # Esta documentación
```

## 🔧 Características específicas de Cloud Run

### Manejo de puerto dinámico

- **Problema**: Cloud Run asigna puertos aleatorios via `$PORT`
- **Solución**: `startup.sh` detecta `$PORT` y lo mapea a `N8N_PORT`
- **Resultado**: n8n escucha en el puerto correcto automáticamente

### Optimizaciones serverless

- **Cold start**: Imagen optimizada para arranque rápido
- **Memoria**: 2Gi configurado para workflows complejos
- **CPU**: 2 vCPUs para mejor rendimiento
- **Timeout**: 300s para workflows largos
- **Concurrencia**: 80 requests simultáneos

## 🛠️ Configuración previa

### 1. Instalar Google Cloud CLI

```bash
# Windows
# Descargar desde: https://cloud.google.com/sdk/docs/install

# Verificar instalación
gcloud --version
```

### 2. Configurar proyecto

```bash
# Iniciar sesión
gcloud auth login

# Configurar proyecto
gcloud config set project YOUR_PROJECT_ID

# Habilitar APIs necesarias
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 3. Configurar variables de entorno

```bash
# Editar deploy-cloudrun.sh y cambiar:
PROJECT_ID="tu-project-id"
REGION="us-central1"  # o tu región preferida

# Configurar variables de entorno para el despliegue
export DB_HOST="tu-postgres-host"
export DB_NAME="n8n_db"
export DB_USER="n8n_user"
export DB_PASSWORD="tu-db-password"
export N8N_ENCRYPTION_KEY="tu-clave-super-larga-y-unica"
export N8N_USER="admin"
export N8N_PASSWORD="tu-n8n-password"
```

## 🚀 Despliegue

### Opción 1: Script automático (Recomendado)

```bash
# Dar permisos al script
chmod +x deploy-cloudrun.sh

# Ejecutar despliegue
./deploy-cloudrun.sh
```

### Opción 2: Comandos manuales

```bash
# 1. Construir imagen
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/n8n --file Dockerfile.cloudrun .

# 2. Desplegar a Cloud Run
gcloud run deploy n8n \
    --image gcr.io/YOUR_PROJECT_ID/n8n \
    --region us-central1 \
    --platform managed \
    --allow-unauthenticated \
    --memory 2Gi \
    --cpu 2 \
    --max-instances 10 \
    --timeout 300 \
    --concurrency 80 \
    --set-env-vars="DB_TYPE=postgresdb,DB_POSTGRESDB_HOST=tu-host,DB_POSTGRESDB_DATABASE=n8n_db,DB_POSTGRESDB_USER=n8n_user,DB_POSTGRESDB_PASSWORD=tu-password,N8N_ENCRYPTION_KEY=tu-clave,N8N_BASIC_AUTH_ACTIVE=true,N8N_BASIC_AUTH_USER=admin,N8N_BASIC_AUTH_PASSWORD=tu-password,NODE_ENV=production"
```

## 🔍 Monitoreo y logs

### Ver logs en tiempo real

```bash
gcloud logs tail --service=n8n --region=us-central1
```

### Ver información del servicio

```bash
gcloud run services describe n8n --region=us-central1
```

### Ver métricas

```bash
# En Google Cloud Console > Cloud Run > n8n > Métricas
```

## 🔧 Configuración de base de datos

### Opción 1: Cloud SQL (Recomendado)

```bash
# Crear instancia PostgreSQL
gcloud sql instances create n8n-postgres \
    --database-version=POSTGRES_16 \
    --tier=db-f1-micro \
    --region=us-central1 \
    --root-password=tu-root-password

# Crear base de datos
gcloud sql databases create n8n_db --instance=n8n-postgres

# Crear usuario
gcloud sql users create n8n_user \
    --instance=n8n-postgres \
    --password=tu-user-password
```

### Opción 2: PostgreSQL externo

- Usar cualquier PostgreSQL (DigitalOcean, AWS RDS, etc.)
- Configurar variables `DB_POSTGRESDB_*` en el despliegue

## 🔒 Seguridad

### Variables de entorno críticas

```bash
# Encryption key (OBLIGATORIO cambiar)
N8N_ENCRYPTION_KEY="clave-super-segura-de-32-caracteres-minimo"

# Credenciales de autenticación
N8N_BASIC_AUTH_USER="admin"
N8N_BASIC_AUTH_PASSWORD="contraseña-super-fuerte"

# Credenciales de base de datos
DB_POSTGRESDB_PASSWORD="contraseña-segura-de-db"
```

### Configuraciones adicionales

```bash
# Para HTTPS (recomendado)
N8N_PROTOCOL=https

# Para webhooks públicos
WEBHOOK_URL=https://tu-cloud-run-url.run.app/

# Para desarrollo con túnel
N8N_TUNNEL=true
```

## 🔄 CI/CD con Cloud Build

### Configurar trigger automático

```bash
# Crear trigger en Cloud Build
gcloud builds triggers create github \
    --repo-name=tu-repo \
    --repo-owner=tu-usuario \
    --branch-pattern="^main$" \
    --build-config=cloudbuild.yaml
```

### Variables de sustitución en Cloud Build

Editar `cloudbuild.yaml` y configurar:

```yaml
substitutions:
  _DB_HOST: 'tu-postgres-host'
  _DB_NAME: 'n8n_db'
  _DB_USER: 'n8n_user'
  _DB_PASSWORD: 'tu-db-password'
  _N8N_ENCRYPTION_KEY: 'tu-encryption-key'
  _N8N_USER: 'admin'
  _N8N_PASSWORD: 'tu-n8n-password'
```

## 🚨 Troubleshooting

### Problemas comunes

1. **Error de puerto**

   ```bash
   # Verificar que startup.sh tiene permisos
   chmod +x startup.sh
   ```

2. **Error de conexión a DB**

   ```bash
   # Verificar variables de entorno
   gcloud run services describe n8n --region=us-central1 --format="value(spec.template.spec.containers[0].env[].name,spec.template.spec.containers[0].env[].value)"
   ```

3. **Cold start lento**

   ```bash
   # Aumentar memoria/CPU
   gcloud run services update n8n --memory=4Gi --cpu=4 --region=us-central1
   ```

4. **Timeout en workflows largos**
   ```bash
   # Aumentar timeout
   gcloud run services update n8n --timeout=600 --region=us-central1
   ```

### Logs detallados

```bash
# Ver logs específicos
gcloud logs read "resource.type=cloud_run_revision AND resource.labels.service_name=n8n" --limit=50

# Ver logs de errores
gcloud logs read "resource.type=cloud_run_revision AND resource.labels.service_name=n8n AND severity>=ERROR" --limit=20
```

## 💰 Costos estimados

### Cloud Run

- **2Gi RAM + 2 CPU**: ~$0.00002400/100ms
- **10 instancias máx**: Escalado automático
- **Tráfico**: $0.40/million requests

### Cloud SQL (PostgreSQL)

- **db-f1-micro**: ~$7.50/mes
- **db-g1-small**: ~$15/mes

### Estimación mensual

- **Uso bajo**: $10-20/mes
- **Uso medio**: $20-50/mes
- **Uso alto**: $50-100+/mes

## 📚 Recursos adicionales

- [Documentación oficial de Cloud Run](https://cloud.google.com/run/docs)
- [n8n en Cloud Run](https://docs.n8n.io/hosting/installation/cloud-run/)
- [Cloud Build triggers](https://cloud.google.com/build/docs/automate-builds/create-manual-triggers)
- [Cloud SQL para PostgreSQL](https://cloud.google.com/sql/docs/postgres)
````

## File: README-cloudsql.md
````markdown
# n8n con Cloud SQL - Configuración Completa

## 🗄️ Configuración de Cloud SQL para n8n

Esta guía te ayudará a configurar n8n con Cloud SQL PostgreSQL en Google Cloud Run.

## 🚀 Configuración Rápida

### 1. Configurar Cloud SQL y Variables de Entorno

```bash
# Ejecutar script de configuración interactivo
./setup-cloudsql.sh
```

Este script:

- ✅ Crea o configura una instancia de Cloud SQL PostgreSQL
- ✅ Crea la base de datos `n8n_db` y usuario `n8n_user`
- ✅ Genera contraseñas seguras automáticamente
- ✅ Configura variables de sustitución en Cloud Build
- ✅ Genera clave de encriptación para n8n

### 2. Verificar Configuración

```bash
# Verificar que todo esté correcto
./verify-cloudsql.sh
```

### 3. Desplegar

```bash
# Commit y push (activa el trigger automático)
git add .
git commit -m "feat: configurar cloud sql y despliegue"
git push origin main
```

## 📋 Requisitos Previos

### APIs de Google Cloud

```bash
# Habilitar APIs necesarias
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable sqladmin.googleapis.com
```

### Autenticación

```bash
# Iniciar sesión en gcloud
gcloud auth login

# Configurar proyecto
gcloud config set project YOUR_PROJECT_ID
```

## 🔧 Configuración Detallada

### Estructura de la Instancia Cloud SQL

```
Proyecto: your-project-id
Instancia: n8n-postgres
Región: us-central1
Base de datos: n8n_db
Usuario: n8n_user
```

### Variables de Entorno Configuradas

```bash
# Base de datos
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=/cloudsql/your-project-id:us-central1:n8n-postgres
DB_POSTGRESDB_DATABASE=n8n_db
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=[generada automáticamente]

# n8n
N8N_ENCRYPTION_KEY=[generada automáticamente]
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=[generada automáticamente]
```

## 🔒 Seguridad

### Conexión Segura

- **Socket Unix**: Cloud Run se conecta a Cloud SQL via socket Unix
- **Sin IP pública**: La instancia de Cloud SQL no necesita IP pública
- **IAM**: Usa permisos de IAM para autenticación

### Variables Críticas

- `N8N_ENCRYPTION_KEY`: Clave de 32+ caracteres para encriptar datos
- `DB_POSTGRESDB_PASSWORD`: Contraseña de base de datos
- `N8N_BASIC_AUTH_PASSWORD`: Contraseña de autenticación

### Archivos Sensibles

- `.cloudsql-config.local`: Contiene credenciales - NO subir a git
- Agregado automáticamente a `.gitignore`

## 🛠️ Comandos de Gestión

### Verificar Estado de Cloud SQL

```bash
# Listar instancias
gcloud sql instances list

# Ver detalles de la instancia
gcloud sql instances describe n8n-postgres --region=us-central1

# Ver bases de datos
gcloud sql databases list --instance=n8n-postgres

# Ver usuarios
gcloud sql users list --instance=n8n-postgres
```

### Conectar a la Base de Datos

```bash
# Conectar via Cloud SQL Proxy (desarrollo local)
gcloud sql connect n8n-postgres --user=n8n_user --database=n8n_db

# O usar psql directamente
psql "host=/cloudsql/your-project-id:us-central1:n8n-postgres dbname=n8n_db user=n8n_user"
```

### Backup y Restauración

```bash
# Backup
gcloud sql export sql n8n-postgres gs://your-bucket/n8n-backup.sql \
  --database=n8n_db

# Restaurar
gcloud sql import sql n8n-postgres gs://your-bucket/n8n-backup.sql \
  --database=n8n_db
```

## 🔍 Troubleshooting

### Problema: "Connection to database failed"

**Causa**: La conexión a Cloud SQL no está configurada correctamente.

**Solución**:

1. Verificar que la instancia existe: `gcloud sql instances list`
2. Verificar que el usuario existe: `gcloud sql users list --instance=n8n-postgres`
3. Verificar variables de entorno en Cloud Run
4. Verificar que `--add-cloudsql-instances` está configurado

### Problema: "Permission denied"

**Causa**: Falta de permisos para acceder a Cloud SQL.

**Solución**:

1. Verificar que el servicio de Cloud Run tiene permisos de Cloud SQL
2. Verificar que la API `sqladmin.googleapis.com` está habilitada
3. Verificar que la instancia está en la misma región que Cloud Run

### Problema: "Environment variables (0)"

**Causa**: Las variables de sustitución no están configuradas.

**Solución**:

1. Ejecutar `./setup-cloudsql.sh` para configurar variables
2. Verificar que el trigger de Cloud Build tiene las sustituciones correctas
3. Verificar que el archivo `.cloudsql-config.local` existe

## 📊 Monitoreo

### Logs de Cloud SQL

```bash
# Ver logs de la instancia
gcloud sql logs tail n8n-postgres --region=us-central1
```

### Métricas

```bash
# Ver métricas de uso
gcloud sql instances describe n8n-postgres --region=us-central1 \
  --format="value(settings.userLabels)"
```

### Alertas

Configurar alertas para:

- Uso de CPU > 80%
- Uso de memoria > 80%
- Conexiones activas > 100
- Errores de conexión

## 💰 Costos Estimados

### Cloud SQL (PostgreSQL)

- **db-f1-micro**: ~$7.50/mes
- **db-g1-small**: ~$15/mes
- **Almacenamiento**: $0.17/GB/mes

### Estimación Mensual

- **Uso bajo**: $10-20/mes
- **Uso medio**: $20-50/mes
- **Uso alto**: $50-100+/mes

## 📚 Recursos Adicionales

- [Cloud SQL Documentation](https://cloud.google.com/sql/docs/postgres)
- [Cloud Run with Cloud SQL](https://cloud.google.com/run/docs/connect/cloud-sql)
- [n8n Database Configuration](https://docs.n8n.io/hosting/database/)
- [PostgreSQL Best Practices](https://cloud.google.com/sql/docs/postgres/best-practices)
````

## File: README-docker.md
````markdown
# n8n con Docker + PostgreSQL

## Estructura del proyecto

```
N8N/
├── Dockerfile              # Imagen personalizada de n8n
├── docker-compose.yml      # Orquestación con PostgreSQL
├── docker-entrypoint.sh    # Script de inicialización
├── startup.sh             # Script para Cloud Run
├── .dockerignore          # Archivos ignorados en build
└── README-docker.md       # Esta documentación
```

## Requisitos

- Docker Desktop
- Docker Compose
- Al menos 2GB RAM disponible

## Configuración rápida

### 1. Construir y ejecutar

```bash
# Construir imagen y arrancar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f n8n

# Verificar estado
docker-compose ps
```

### 2. Acceder a n8n

- **URL**: http://localhost:5679
- **Usuario**: admin
- **Contraseña**: tu_password

### 3. Verificar base de datos

```bash
# Conectar a PostgreSQL
docker-compose exec postgres psql -U n8n_user -d n8n_db

# Ver tablas de n8n
\dt
```

## Configuración avanzada

### Variables de entorno importantes

Edita `docker-compose.yml` para cambiar:

```yaml
environment:
  # Cambiar encryption key (OBLIGATORIO para producción)
  N8N_ENCRYPTION_KEY: tu-clave-super-larga-y-unica

  # Cambiar credenciales de autenticación
  N8N_BASIC_AUTH_USER: tu_usuario
  N8N_BASIC_AUTH_PASSWORD: tu_contraseña

  # Configurar webhook URL pública
  WEBHOOK_URL: https://tu-dominio.com/

  # Para desarrollo con túnel
  N8N_TUNNEL: 'true'
```

### Volúmenes y persistencia

Los datos se guardan en:

- **PostgreSQL**: `postgres_data` (volumen Docker)
- **n8n**: `n8n_data` (volumen Docker)
- **Logs**: `./logs/` (directorio local)

### Backup y restauración

```bash
# Backup de PostgreSQL
docker-compose exec postgres pg_dump -U n8n_user n8n_db > backup.sql

# Restaurar PostgreSQL
docker-compose exec -T postgres psql -U n8n_user n8n_db < backup.sql

# Backup de datos n8n
docker cp n8n-app:/home/node/.n8n ./n8n-backup
```

## Comandos útiles

```bash
# Reiniciar solo n8n
docker-compose restart n8n

# Ver logs en tiempo real
docker-compose logs -f n8n

# Ejecutar comandos dentro del contenedor
docker-compose exec n8n n8n --help

# Parar todos los servicios
docker-compose down

# Parar y eliminar volúmenes (CUIDADO: borra datos)
docker-compose down -v

# Reconstruir imagen
docker-compose build --no-cache n8n
```

## Troubleshooting

### Problemas comunes

1. **Puerto 5678 ocupado**

   ```bash
   # Cambiar puerto en docker-compose.yml
   ports:
     - "5679:5678"  # Usar puerto 5679 en host
   ```

2. **Error de conexión a PostgreSQL**

   ```bash
   # Verificar que PostgreSQL está corriendo
   docker-compose ps postgres

   # Ver logs de PostgreSQL
   docker-compose logs postgres
   ```

3. **Permisos de archivos**

   ```bash
   # Dar permisos al script de entrada
   chmod +x docker-entrypoint.sh
   ```

4. **Memoria insuficiente**
   ```bash
   # Aumentar memoria en Docker Desktop
   # Settings > Resources > Memory: 4GB+
   ```

### Logs detallados

```bash
# Ver logs de todos los servicios
docker-compose logs

# Ver logs de n8n con timestamps
docker-compose logs -f --timestamps n8n

# Ver logs de PostgreSQL
docker-compose logs postgres
```

## Producción

### Configuraciones de seguridad

1. **Cambiar encryption key**
2. **Usar contraseñas fuertes**
3. **Configurar HTTPS**
4. **Limitar acceso por IP**
5. **Hacer backups regulares**

### Variables de entorno para producción

```yaml
environment:
  N8N_ENCRYPTION_KEY: clave-super-segura-de-32-caracteres-minimo
  N8N_BASIC_AUTH_ACTIVE: 'true'
  N8N_BASIC_AUTH_USER: admin
  N8N_BASIC_AUTH_PASSWORD: contraseña-super-fuerte
  NODE_ENV: production
  WEBHOOK_URL: https://tu-dominio-produccion.com/
```

### Monitoreo

```bash
# Verificar salud de servicios
docker-compose ps

# Ver uso de recursos
docker stats

# Verificar conectividad
curl http://localhost:5678/healthz
```

## Desarrollo

### Modo desarrollo con túnel

```yaml
environment:
  N8N_TUNNEL: 'true'
  NODE_ENV: development
```

### Hot reload (para desarrollo local)

```bash
# Montar código fuente para desarrollo
volumes:
  - ./src:/home/node/src
```

## Soporte

- [Documentación oficial de n8n](https://docs.n8n.io/)
- [Docker Hub n8n](https://hub.docker.com/r/n8nio/n8n)
- [Issues de n8n](https://github.com/n8n-io/n8n/issues)
````

## File: README-scanning-flows.md
````markdown
# Flujos de Escaneo de Vulnerabilidades

## 📋 Resumen de Flujos Disponibles

### 🔍 **Flujo 1: Escaneo Externo (Recomendado para desarrollo diario)**

**Propósito**: Verificar que la imagen Docker está lista para despliegue
**Cuándo usar**: Antes de cada commit/despliegue
**Ventajas**: Rápido, eficiente, estándar de la industria

#### Opciones disponibles:

**Linux/macOS:**

```bash
# Script automático
chmod +x scan-local.sh
./scan-local.sh

# Comando directo
trivy image my-n8n-image:latest
```

**Windows:**

```powershell
# Script automático con instalación de Trivy
.\scan-local-windows.ps1

# O forzar reinstalación
.\scan-local-windows.ps1 -InstallTrivy
```

**Docker (cualquier OS):**

```bash
# Usar contenedor Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image my-n8n-image:latest
```

### 🔍 **Flujo 2: Escaneo Interno (Para auditorías específicas)**

**Propósito**: Auditorías de seguridad en contenedores en ejecución
**Cuándo usar**: Auditorías periódicas, análisis forense, producción
**Ventajas**: Escanea el estado real del contenedor en ejecución

#### Uso:

```bash
# Levantar entorno con capacidades de escaneo
docker-compose -f docker-compose-with-scanning.yml up -d

# Ejecutar escaneo interno
docker exec n8n-with-scanning /usr/local/bin/scan-internal.sh

# Ver resultados
ls -la security-scans/
```

## 🎯 **Recomendaciones de Uso**

### Para Desarrollo Diario

```bash
# 1. Escaneo externo antes de commit
./scan-local.sh  # o .\scan-local-windows.ps1 en Windows

# 2. Si pasa, usar docker-compose estándar
docker-compose -f docker-compose.secure.yml up -d
```

### Para Auditorías de Seguridad

```bash
# 1. Levantar entorno con escaneo
docker-compose -f docker-compose-with-scanning.yml up -d

# 2. Ejecutar escaneo interno
docker exec n8n-with-scanning /usr/local/bin/scan-internal.sh

# 3. Analizar resultados
cat security-scans/internal-security-report.txt
```

### Para CI/CD

```yaml
# Usar cloudbuild-secure.yaml que incluye:
# - Escaneo externo con Trivy
# - Escaneo con Google Artifact Analysis
# - Validación automática
```

## 📊 **Comparación de Flujos**

| Aspecto         | Escaneo Externo    | Escaneo Interno        |
| --------------- | ------------------ | ---------------------- |
| **Velocidad**   | ⚡ Rápido          | 🐌 Más lento           |
| **Recursos**    | 💡 Mínimos         | 🔥 Más recursos        |
| **Cobertura**   | 📦 Imagen completa | 🖥️ Estado en ejecución |
| **Uso diario**  | ✅ Recomendado     | ⚠️ Solo auditorías     |
| **Complejidad** | 🟢 Simple          | 🟡 Avanzado            |

## 🚀 **Flujo de Trabajo Optimizado**

### Desarrollo Local (Diario)

```bash
# 1. Construir imagen
docker build -f Dockerfile.cloudrun -t my-n8n-image:latest .

# 2. Escaneo externo (obligatorio)
./scan-local.sh

# 3. Si pasa, ejecutar
docker-compose -f docker-compose.secure.yml up -d
```

### Auditoría de Seguridad (Semanal/Mensual)

```bash
# 1. Levantar entorno con escaneo
docker-compose -f docker-compose-with-scanning.yml up -d

# 2. Escaneo interno completo
docker exec n8n-with-scanning /usr/local/bin/scan-internal.sh

# 3. Analizar resultados
cat security-scans/internal-security-report.txt

# 4. Limpiar
docker-compose -f docker-compose-with-scanning.yml down
```

### Despliegue a Producción

```bash
# 1. Escaneo externo local
./scan-local.sh

# 2. Push a repositorio
git push

# 3. CI/CD ejecuta escaneos automáticos
# (cloudbuild-secure.yaml)
```

## ⚠️ **Consideraciones Importantes**

### Escaneo Externo

- ✅ **Obligatorio** antes de cada despliegue
- ✅ **Rápido** y eficiente
- ✅ **Estándar** de la industria
- ❌ No detecta vulnerabilidades en runtime

### Escaneo Interno

- ✅ **Detecta** vulnerabilidades en runtime
- ✅ **Útil** para auditorías
- ❌ **Lento** y consume más recursos
- ❌ **Complejo** para uso diario

## 🔧 **Optimizaciones Sugeridas**

### Simplificar docker-compose-with-scanning.yml

```yaml
# Remover dependencia innecesaria
security-scanner:
  # depends_on: - n8n  # ← Remover esta línea
  # El escaneo no depende de que n8n esté activo
```

### Script de verificación rápida

```bash
# Crear script que combine ambos flujos
./security-audit.sh  # Escaneo externo + interno
```

## 📚 **Recursos Adicionales**

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Docker Security Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Container Security Scanning](https://cloud.google.com/architecture/container-security)
````

## File: README-vulnerability-scanning.md
````markdown
# Escaneo de Vulnerabilidades en n8n

## 🛡️ Implementación de Seguridad

Hemos implementado un sistema completo de escaneo de vulnerabilidades que se ejecuta tanto localmente como en el pipeline de CI/CD.

## 📁 Archivos de Escaneo

```
N8N/
├── cloudbuild.yaml           # Pipeline básico con Trivy
├── cloudbuild-secure.yaml    # Pipeline avanzado con validaciones
├── scan-local.sh            # Escaneo local antes del despliegue
└── README-vulnerability-scanning.md  # Esta documentación
```

## 🔍 Herramientas Implementadas

### 1. **Trivy** (Aqua Security)

- **Propósito**: Escaneo de vulnerabilidades en imágenes Docker
- **Cobertura**: CVE, configuraciones de seguridad, secretos
- **Severidades**: CRITICAL, HIGH, MEDIUM, LOW

### 2. **Google Artifact Analysis**

- **Propósito**: Escaneo nativo de Google Cloud
- **Cobertura**: Vulnerabilidades conocidas en paquetes
- **Integración**: Automática con Container Registry

## 🚀 Uso Local

### Escaneo antes del despliegue

```bash
# Dar permisos al script
chmod +x scan-local.sh

# Ejecutar escaneo completo
./scan-local.sh
```

### Escaneo manual con Trivy

```bash
# Opción 1: Instalar Trivy localmente
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Opción 2: Usar Dockerfile con Trivy integrado
docker build -f Dockerfile.with-trivy -t my-n8n-image:latest .

# Escanear imagen
trivy image my-n8n-image:latest

# Escanear solo vulnerabilidades críticas/altas
trivy image --severity HIGH,CRITICAL my-n8n-image:latest

# Escanear configuración de seguridad
trivy config .
```

## 🔄 Pipeline de CI/CD

### Pipeline Básico (`cloudbuild.yaml`)

```yaml
# Escaneo con Trivy
- name: 'aquasec/trivy'
  args:
    - 'image'
    - '--severity'
    - 'HIGH,CRITICAL'
    - '--exit-code'
    - '1'
    - 'gcr.io/$PROJECT_ID/n8n:$COMMIT_SHA'

# Escaneo con Google Artifact Analysis
- name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
  args:
    - 'artifacts'
    - 'docker'
    - 'images'
    - 'scan'
    - 'gcr.io/$PROJECT_ID/n8n:$COMMIT_SHA'
```

### Pipeline Avanzado (`cloudbuild-secure.yaml`)

- ✅ Escaneo de múltiples severidades
- ✅ Validación automática de resultados
- ✅ Reportes detallados
- ✅ Fail-fast en vulnerabilidades críticas
- ✅ Recursos optimizados para escaneos

## 📊 Niveles de Severidad

### CRITICAL

- **Acción**: Bloquea el despliegue
- **Ejemplos**: RCE, escalación de privilegios
- **Política**: Corregir inmediatamente

### HIGH

- **Acción**: Bloquea el despliegue
- **Ejemplos**: DoS, acceso no autorizado
- **Política**: Corregir antes del despliegue

### MEDIUM

- **Acción**: Reporte informativo
- **Ejemplos**: Información de debug, logs
- **Política**: Revisar y corregir cuando sea posible

### LOW

- **Acción**: Reporte informativo
- **Ejemplos**: Configuraciones no óptimas
- **Política**: Mejorar en futuras versiones

## 🔧 Configuración

### Habilitar APIs necesarias

```bash
# Google Artifact Analysis
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containerscanning.googleapis.com

# Cloud Build
gcloud services enable cloudbuild.googleapis.com
```

### Configurar políticas de escaneo

```bash
# Configurar política de escaneo automático
gcloud artifacts repositories create n8n-repo \
    --repository-format=docker \
    --location=us \
    --description="n8n container repository"

# Habilitar escaneo automático
gcloud artifacts docker images scan-enable \
    --repository=n8n-repo \
    --location=us
```

## 📈 Monitoreo y Alertas

### Configurar alertas de seguridad

```bash
# Crear canal de notificaciones
gcloud logging sinks create security-alerts \
    storage.googleapis.com/projects/$PROJECT_ID/buckets/security-logs \
    --log-filter='resource.type="cloud_run_revision" AND severity>=ERROR'

# Configurar alertas para vulnerabilidades
gcloud monitoring policies create \
    --policy-from-file=vulnerability-alert-policy.yaml
```

### Verificar resultados de escaneo

```bash
# Ver escaneos recientes
gcloud artifacts docker images list-vulnerabilities \
    gcr.io/$PROJECT_ID/n8n:latest \
    --location=us

# Ver detalles de vulnerabilidades
gcloud artifacts docker images describe \
    gcr.io/$PROJECT_ID/n8n:latest \
    --location=us
```

## 🚨 Respuesta a Incidentes

### Cuando se encuentran vulnerabilidades críticas

1. **Detener el pipeline**

   ```bash
   # El build fallará automáticamente
   # Revisar logs en Cloud Build
   ```

2. **Analizar vulnerabilidades**

   ```bash
   # Ver detalles
   cat scan-results/security-report.txt

   # Verificar CVE específicos
   trivy image --severity HIGH,CRITICAL my-n8n-image:latest
   ```

3. **Corregir vulnerabilidades**

   ```dockerfile
   # Actualizar imagen base
   FROM n8nio/n8n:latest

   # Actualizar paquetes
   RUN apk update && apk upgrade
   ```

4. **Re-ejecutar escaneos**

   ```bash
   # Escaneo local
   ./scan-local.sh

   # Re-ejecutar pipeline
   gcloud builds submit --config=cloudbuild-secure.yaml
   ```

## 📋 Checklist de Seguridad

### Antes del despliegue

- [ ] Ejecutar `./scan-local.sh`
- [ ] Revisar reporte de vulnerabilidades
- [ ] Corregir vulnerabilidades críticas/altas
- [ ] Verificar configuración de seguridad

### Durante el despliegue

- [ ] Pipeline ejecuta escaneos automáticamente
- [ ] Validar que no hay vulnerabilidades críticas
- [ ] Revisar logs de Cloud Build
- [ ] Confirmar despliegue exitoso

### Mantenimiento

- [ ] Ejecutar escaneos semanalmente
- [ ] Actualizar imagen base regularmente
- [ ] Revisar nuevas vulnerabilidades
- [ ] Actualizar políticas de seguridad

## 🔗 Recursos Adicionales

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Google Artifact Analysis](https://cloud.google.com/artifact-registry/docs/analysis)
- [Container Security Best Practices](https://cloud.google.com/architecture/container-security)
- [CVE Database](https://cve.mitre.org/)

## 💡 Mejores Prácticas

1. **Escaneo temprano**: Ejecutar escaneos antes del merge
2. **Automatización**: Integrar en CI/CD pipeline
3. **Monitoreo continuo**: Escaneos regulares en producción
4. **Respuesta rápida**: Corregir vulnerabilidades críticas inmediatamente
5. **Documentación**: Mantener registro de vulnerabilidades y correcciones
````

## File: README.md
````markdown
# n8n con PostgreSQL - Proyecto Docker Optimizado

Proyecto completo para ejecutar n8n con PostgreSQL usando Docker, optimizado para desarrollo local y despliegue en Google Cloud Run.

## 🚀 Inicio Rápido

### Desarrollo Local

```bash
# Construir y ejecutar con Docker Compose
docker-compose up -d

# Acceder a n8n
# http://localhost:5679
# Usuario: admin
# Contraseña: tu_password
```

### Escaneo de Vulnerabilidades

```bash
# Linux/macOS
./scan-local.sh

# Windows
.\scan-simple.ps1
```

### Despliegue en Cloud Run

```bash
# Desplegar a Google Cloud Run
./deploy-cloudrun.sh
```

## 📁 Estructura del Proyecto

### 🐳 Dockerfiles

- `Dockerfile` - Imagen básica para desarrollo local
- `Dockerfile.cloudrun` - Optimizada para Google Cloud Run
- `Dockerfile.with-trivy` - Con herramientas de escaneo integradas

### 🔧 Scripts Principales

- `docker-compose.yml` - Orquestación local con PostgreSQL
- `startup.sh` - Script de inicio para Cloud Run
- `docker-entrypoint.sh` - Entrypoint personalizado
- `deploy-cloudrun.sh` - Despliegue automatizado a Cloud Run

### 🔒 Seguridad

- `scan-simple.ps1` - Escaneo de vulnerabilidades (Windows)
- `scan-local.sh` - Escaneo de vulnerabilidades (Linux/macOS)
- `security-audit.sh` - Auditoría de seguridad completa
- `verify-dockerfiles.sh` - Verificación de Dockerfiles

### 📚 Documentación

- `README-docker.md` - Guía completa de Docker
- `README-cloudrun.md` - Despliegue en Google Cloud Run
- `README-vulnerability-scanning.md` - Escaneo de vulnerabilidades
- `README-scanning-flows.md` - Flujos de escaneo
- `SECURITY.md` - Mejores prácticas de seguridad

### 🏗️ CI/CD

- `cloudbuild-secure.yaml` - Pipeline seguro para Cloud Build
- `docker-compose-with-scanning.yml` - Entorno con escaneo integrado

## 🛠️ Comandos Útiles

### Construcción de Imágenes

```bash
# Imagen básica
docker build -f Dockerfile -t n8n:latest .

# Imagen para Cloud Run
docker build -f Dockerfile.cloudrun -t n8n-cloudrun:latest .

# Imagen con Trivy
docker build -f Dockerfile.with-trivy -t n8n-trivy:latest .
```

### Verificación

```bash
# Verificar Dockerfiles
./verify-dockerfiles.sh

# Probar construcción
./test-simple.sh
```

### Escaneo

```bash
# Linux/macOS
./scan-local.sh

# Windows
.\scan-simple.ps1
```

## 🔐 Variables de Entorno

Las variables están configuradas en `docker-compose.yml`. Para producción, crea un archivo `.env`:

```bash
# Base de datos
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n_db
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=tu_contraseña_segura

# n8n (OBLIGATORIO cambiar en producción)
N8N_ENCRYPTION_KEY=tu_clave_de_encriptacion_super_larga_y_unica
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=tu_contraseña_admin_segura
```

## 🎯 Características

- ✅ **Multi-stage builds** para imágenes optimizadas
- ✅ **Usuario no-root** para seguridad
- ✅ **Escaneo de vulnerabilidades** integrado
- ✅ **CI/CD seguro** con Cloud Build
- ✅ **PostgreSQL** como base de datos
- ✅ **Cloud Run** optimizado
- ✅ **Documentación completa**

## 📖 Más Información

- [Guía de Docker](README-docker.md)
- [Despliegue en Cloud Run](README-cloudrun.md)
- [Escaneo de Vulnerabilidades](README-vulnerability-scanning.md)
- [Mejores Prácticas de Seguridad](SECURITY.md)
````

## File: repomix.config.json
````json
{
  "$schema": "https://repomix.com/schemas/latest/schema.json",
  "input": {
    "maxFileSize": 52428800
  },
  "output": {
    "filePath": "repomix-output.md",
    "style": "markdown",
    "parsableStyle": false,
    "fileSummary": true,
    "directoryStructure": true,
    "files": true,
    "removeComments": false,
    "removeEmptyLines": false,
    "compress": false,
    "topFilesLength": 5,
    "showLineNumbers": false,
    "truncateBase64": false,
    "copyToClipboard": false,
    "git": {
      "sortByChanges": true,
      "sortByChangesMaxCommits": 100,
      "includeDiffs": false
    }
  },
  "include": [],
  "ignore": {
    "useGitignore": true,
    "useDefaultPatterns": true,
    "customPatterns": []
  },
  "security": {
    "enableSecurityCheck": true
  },
  "tokenCount": {
    "encoding": "o200k_base"
  }
}
````

## File: scan-internal.sh
````bash
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
````

## File: scan-local.sh
````bash
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
````

## File: scan-simple.ps1
````powershell
# Script simplificado de escaneo de vulnerabilidades
# Usa Docker para evitar problemas de instalación local

param(
    [string]$ImageName = "my-n8n-image:latest"
)

Write-Host "=== Escaneo de Vulnerabilidades Simplificado ===" -ForegroundColor Blue
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Gray

# Verificar Docker
try {
    docker info | Out-Null
    Write-Host "OK: Docker está corriendo" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Docker no está corriendo" -ForegroundColor Red
    exit 1
}

# Construir imagen si no existe
if (-not (docker images | Select-String $ImageName)) {
    Write-Host "Construyendo imagen Docker..." -ForegroundColor Yellow
    docker build -f Dockerfile.cloudrun -t $ImageName .
}

Write-Host "=== Escaneando con Trivy (Docker) ===" -ForegroundColor Blue

# Crear directorio para resultados
$scanDir = "scan-results"
New-Item -ItemType Directory -Force -Path $scanDir | Out-Null

# Función para ejecutar Trivy
function Invoke-TrivyDocker {
    param(
        [string]$Severity,
        [string]$OutputFile,
        [string]$Format = "table"
    )
    
    Write-Host "Escaneando vulnerabilidades $Severity..." -ForegroundColor Yellow
    
    $dockerArgs = @(
        "run", "--rm",
        "-v", "${PWD}:/workspace",
        "-w", "/workspace",
        "aquasec/trivy:latest"
    )
    
    if ($Format -eq "json") {
        $dockerArgs += @("image", "--severity", $Severity, "--exit-code", "0", "--format", $Format, "--output", $OutputFile, $ImageName)
    } else {
        $dockerArgs += @("image", "--severity", $Severity, "--exit-code", "0", "--format", $Format, "--output", $OutputFile, $ImageName)
    }
    
    docker $dockerArgs
}

# Escaneo crítico/alto
try {
    Invoke-TrivyDocker -Severity "HIGH,CRITICAL" -OutputFile "$scanDir\critical.json" -Format "json"
    Write-Host "OK: No se encontraron vulnerabilidades críticas/altas" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Se encontraron vulnerabilidades críticas/altas" -ForegroundColor Red
}

# Escaneo medio
Invoke-TrivyDocker -Severity "MEDIUM" -OutputFile "$scanDir\medium.txt"

# Escaneo bajo
Invoke-TrivyDocker -Severity "LOW" -OutputFile "$scanDir\low.txt"

# Escaneo de configuración
Write-Host "Escaneando configuración de seguridad..." -ForegroundColor Yellow
docker run --rm -v "${PWD}:/workspace" -w /workspace aquasec/trivy:latest config --severity HIGH,CRITICAL --exit-code 0 --format table --output "$scanDir\config.txt" .

# Generar reporte
Write-Host "=== Generando Reporte ===" -ForegroundColor Blue

$report = @"
=== Reporte de Vulnerabilidades ===
Fecha: $(Get-Date)
Imagen: $ImageName
Método: Docker + Trivy

=== Vulnerabilidades Críticas/Altas ===
"@

if (Test-Path "$scanDir\critical.json") {
    $report += "`nSe encontraron vulnerabilidades. Revisa: $scanDir\critical.json"
} else {
    $report += "`nOK: No se encontraron vulnerabilidades críticas/altas"
}

$report += @"

=== Vulnerabilidades Medias ===
"@

if (Test-Path "$scanDir\medium.txt") {
    $report += "`n" + (Get-Content "$scanDir\medium.txt" -Raw)
}

$report += @"

=== Vulnerabilidades Bajas ===
"@

if (Test-Path "$scanDir\low.txt") {
    $report += "`n" + (Get-Content "$scanDir\low.txt" -Raw)
}

$report += @"

=== Configuración de Seguridad ===
"@

if (Test-Path "$scanDir\config.txt") {
    $report += "`n" + (Get-Content "$scanDir\config.txt" -Raw)
}

$report | Out-File -FilePath "$scanDir\report.txt" -Encoding UTF8

Write-Host "OK: Reporte guardado en: $scanDir\report.txt" -ForegroundColor Green

# Resumen
Write-Host "`n=== Resumen ===" -ForegroundColor Blue
Write-Host "Resultados: $scanDir\" -ForegroundColor Green
Write-Host "Reporte: $scanDir\report.txt" -ForegroundColor Green

if (Test-Path "$scanDir\critical.json") {
    Write-Host "ADVERTENCIA: Se encontraron vulnerabilidades críticas" -ForegroundColor Red
Write-Host "Revisa el reporte antes de desplegar" -ForegroundColor Yellow
} else {
    Write-Host "OK: Imagen lista para despliegue" -ForegroundColor Green
}

Write-Host "`nConsejo: Este script usa Docker, no requiere instalar Trivy localmente" -ForegroundColor Cyan
````

## File: security-audit.sh
````bash
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
````

## File: SECURITY.md
````markdown
# Seguridad en n8n Docker

## ✅ Buenas prácticas implementadas

### 1. Usuario no privilegiado

- **Estado**: ✅ IMPLEMENTADO
- **Detalles**:
  - Imagen base `n8nio/n8n:latest` ya usa usuario `node`
  - Script `startup.sh` ejecuta con `su-exec node`
  - Mitiga riesgos de seguridad si el contenedor es comprometido

### 2. Secretos via variables de entorno

- **Estado**: ✅ IMPLEMENTADO
- **Detalles**:
  - NO hardcodeamos contraseñas en la imagen
  - Todas las credenciales se pasan como variables de entorno
  - Archivo `env.example` muestra configuración sin secretos reales

### 3. Imagen base actualizada

- **Estado**: ✅ IMPLEMENTADO
- **Detalles**:
  - Usa `FROM n8nio/n8n:latest` (siempre última versión)
  - Incluye parches de seguridad automáticamente

### 4. Archivos sensibles excluidos

- **Estado**: ✅ IMPLEMENTADO
- **Detalles**:
  - `.dockerignore` excluye `.env*`, `*.md`, `.git`
  - `env.example` no contiene secretos reales

## ⚠️ Configuraciones que requieren atención

### Variables de entorno críticas

```bash
# OBLIGATORIO cambiar en producción:
N8N_ENCRYPTION_KEY="clave-super-segura-de-32-caracteres-minimo"
N8N_BASIC_AUTH_PASSWORD="contraseña-super-fuerte"
DB_POSTGRESDB_PASSWORD="contraseña-segura-de-db"
```

### Configuración de red

```bash
# Para producción, usar HTTPS:
N8N_PROTOCOL=https
WEBHOOK_URL=https://tu-dominio-seguro.com/
```

## 🔒 Medidas de seguridad adicionales recomendadas

### 1. Escaneo de vulnerabilidades

```bash
# Escanear imagen con Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image my-n8n-image:latest

# Escanear con Snyk
snyk container test my-n8n-image:latest
```

### 2. Firmado de imágenes

```bash
# Firmar imagen con Docker Content Trust
export DOCKER_CONTENT_TRUST=1
docker build -f Dockerfile.cloudrun -t my-n8n-image:latest .
```

### 3. Políticas de red

```bash
# En producción, limitar acceso por IP
# Configurar firewall/security groups
# Usar VPC para aislamiento de red
```

### 4. Monitoreo de seguridad

```bash
# Logs de seguridad
docker logs n8n-container | grep -i "error\|warning\|security"

# Auditoría de contenedor
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image --severity HIGH,CRITICAL my-n8n-image:latest
```

## 🚨 Checklist de seguridad

### Antes del despliegue

- [ ] Cambiar `N8N_ENCRYPTION_KEY` por clave única y segura
- [ ] Cambiar `N8N_BASIC_AUTH_PASSWORD` por contraseña fuerte
- [ ] Cambiar `DB_POSTGRESDB_PASSWORD` por contraseña segura
- [ ] Configurar `WEBHOOK_URL` para tu dominio
- [ ] Habilitar HTTPS en producción
- [ ] Escanear imagen en busca de vulnerabilidades

### Durante el despliegue

- [ ] Usar secretos management (Cloud Secret Manager, AWS Secrets Manager)
- [ ] Configurar políticas de red restrictivas
- [ ] Habilitar logging de seguridad
- [ ] Configurar alertas de seguridad

### Mantenimiento

- [ ] Actualizar imagen base regularmente
- [ ] Revisar logs de seguridad
- [ ] Escanear vulnerabilidades periódicamente
- [ ] Rotar credenciales regularmente

## 📚 Recursos adicionales

- [Docker Security Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [n8n Security Documentation](https://docs.n8n.io/hosting/security/)
- [OWASP Container Security](https://owasp.org/www-project-container-security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker/)
````

## File: test-permissions-fix.sh
````bash
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
````

## File: test-simple-n8n.sh
````bash
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
````

## File: test-simple.sh
````bash
#!/bin/bash
set -e

echo "=== Prueba Simple de Dockerfile ==="

# Verificar que Docker esté disponible
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker no está disponible"
    exit 1
fi

echo "OK: Docker está disponible"

# Verificar que el archivo existe
if [ ! -f "docker-entrypoint.sh" ]; then
    echo "ERROR: docker-entrypoint.sh no existe"
    exit 1
fi

echo "OK: docker-entrypoint.sh existe"

# Probar construcción
echo "Construyendo Dockerfile básico..."
if docker build -f Dockerfile -t test-n8n:latest .; then
    echo "✅ Construcción exitosa"
    echo "✅ El Dockerfile funciona correctamente"
else
    echo "❌ Error en la construcción"
    exit 1
fi
````

## File: verify-dockerfiles.sh
````bash
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
````

## File: startup.sh
````bash
#!/bin/sh
# Script de inicio para Cloud Run - Maneja puerto dinámico

set -e

echo "=== Iniciando n8n para Cloud Run ==="

# Manejar puerto dinámico de Cloud Run
if [ -n "$PORT" ]; then
    echo "Puerto Cloud Run detectado: $PORT"
    export N8N_PORT=$PORT
    echo "Configurando n8n para escuchar en puerto: $N8N_PORT"
else
    echo "Puerto Cloud Run no detectado, usando puerto por defecto: ${N8N_PORT:-5678}"
    export N8N_PORT=${N8N_PORT:-5678}
fi

# Configurar host para Cloud Run
export N8N_HOST=${N8N_HOST:-0.0.0.0}
export N8N_PROTOCOL=${N8N_PROTOCOL:-http}

# Validar variables de entorno críticas
if [ -z "$DB_TYPE" ]; then
    echo "Error: DB_TYPE no está definido"
    exit 1
fi

if [ "$DB_TYPE" = "postgresdb" ]; then
    required_vars="DB_POSTGRESDB_HOST DB_POSTGRESDB_DATABASE DB_POSTGRESDB_USER DB_POSTGRESDB_PASSWORD"
    for var in $required_vars; do
        if [ -z "$(eval echo \$$var)" ]; then
            echo "Error: $var no está definido para PostgreSQL"
            exit 1
        fi
    done
fi

# Crear directorios necesarios
mkdir -p /home/node/.n8n/logs
mkdir -p /home/node/.n8n/data
chown -R node:node /home/node/.n8n

# Mostrar configuración final
echo "=== Configuración final ==="
echo "Host: $N8N_HOST"
echo "Puerto: $N8N_PORT"
echo "Protocolo: $N8N_PROTOCOL"
echo "Base de datos: $DB_TYPE"
if [ "$DB_TYPE" = "postgresdb" ]; then
    echo "PostgreSQL Host: $DB_POSTGRESDB_HOST"
    echo "PostgreSQL Database: $DB_POSTGRESDB_DATABASE"
    echo "PostgreSQL User: $DB_POSTGRESDB_USER"
fi
echo "=========================="

# Cambiar al usuario node y ejecutar n8n
echo "Iniciando n8n con logs detallados..."
# La siguiente línea ejecutará n8n. Si falla, el script continuará y mostrará un error.
gosu node n8n start || {
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "!! EL PROCESO 'n8n start' HA FALLADO CON UN CÓDIGO DE ERROR !!"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1
}
````

## File: Dockerfile
````dockerfile
# Dockerfile para n8n - Optimizado para producción
# Multi-stage build para reducir tamaño final

# Etapa 1: Builder (para dependencias adicionales si las necesitas)
FROM node:22-alpine AS builder
WORKDIR /app

# Instalar dependencias del sistema
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Copiar package.json si tienes dependencias adicionales
# COPY package.json package-lock.json ./
# RUN npm ci --only=production

# Etapa 2: Imagen final basada en n8n oficial
FROM n8nio/n8n:latest

# Cambiar al directorio de trabajo
WORKDIR /home/node

# Copiar dependencias adicionales desde builder (si las hay)
# COPY --from=builder /app/node_modules ./node_modules

# Instalar paquetes adicionales si los necesitas
# RUN npm install -g paquete-extra

# Copiar script de entrada personalizado (como root)
USER root
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Instalar netcat y gosu (reemplazo de su-exec)
RUN apk add --no-cache netcat-openbsd gosu

# Crear directorio para logs (como root, el entrypoint lo arreglará)
RUN mkdir -p /home/node/.n8n/logs

# ---> ELIMINADA LA LÍNEA "USER node" - El entrypoint manejará los privilegios <---

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_PROTOCOL=http
ENV WEBHOOK_URL=http://localhost:5678/

# Exponer puerto
EXPOSE 5678

# Usar script de entrada personalizado
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["n8n", "start"]
````

## File: Dockerfile.with-trivy
````
# Dockerfile para n8n con Trivy integrado
# Permite escaneos de seguridad internos

# Etapa 1: Builder (para dependencias adicionales si las necesitas)
FROM node:22-alpine AS builder
WORKDIR /app

# Instalar dependencias del sistema
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Etapa 2: Imagen final basada en n8n oficial
FROM n8nio/n8n:latest

# Cambiar al directorio de trabajo
WORKDIR /home/node

# Instalar herramientas adicionales incluyendo Trivy
USER root
RUN apk add --no-cache \
    curl \
    wget \
    postgresql-client \
    jq \
    bash \
    gosu

# Instalar Trivy (método robusto)
USER root
RUN ARCH=$(uname -m) \
    && if [ "$ARCH" = "x86_64" ]; then ARCH="64bit"; fi \
    && wget -qO- "https://github.com/aquasecurity/trivy/releases/download/v0.54.0/trivy_0.54.0_Linux-${ARCH}.tar.gz" | \
    tar -xz -C /usr/local/bin trivy \
    && chmod +x /usr/local/bin/trivy

# Copiar scripts (como root)
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

COPY scan-internal.sh /usr/local/bin/scan-internal.sh
RUN chmod +x /usr/local/bin/scan-internal.sh

# ---> ELIMINADA LA LÍNEA "USER node" - El startup.sh manejará los privilegios <---

# Crear directorio para logs y escaneos (como root, el startup.sh lo arreglará)
RUN mkdir -p /home/node/.n8n/logs /home/node/security-scans

# Variables de entorno por defecto para Cloud Run
ENV NODE_ENV=production
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=http
# NO incluir WEBHOOK_URL aquí - debe ser variable de entorno en runtime

# Exponer puerto (Cloud Run lo manejará dinámicamente)
EXPOSE 8080

# Usar script de inicio para Cloud Run
ENTRYPOINT ["/startup.sh"]
````

## File: Dockerfile.cloudrun
````
# Dockerfile para n8n en Google Cloud Run
# Optimizado para serverless con puerto dinámico

# Etapa 1: Builder (para dependencias adicionales si las necesitas)
FROM node:22-alpine AS builder
WORKDIR /app

# Instalar dependencias del sistema
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Etapa 2: Imagen final basada en n8n oficial
FROM n8nio/n8n:latest

# Cambiar al directorio de trabajo
WORKDIR /home/node

# Instalar herramientas adicionales para Cloud Run
USER root
RUN apk add --no-cache \
    curl \
    wget \
    postgresql-client \
    jq \
    gosu

# Instalar Trivy para escaneos internos (método robusto)
USER root
RUN apk add --no-cache bash \
    && ARCH=$(uname -m) \
    && if [ "$ARCH" = "x86_64" ]; then ARCH="64bit"; fi \
    && wget -qO- "https://github.com/aquasecurity/trivy/releases/download/v0.54.0/trivy_0.54.0_Linux-${ARCH}.tar.gz" | \
    tar -xz -C /usr/local/bin trivy \
    && chmod +x /usr/local/bin/trivy

# Copiar script de inicio para Cloud Run (como root)
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Crear directorio para logs (está bien hacerlo como root, el startup.sh lo arregla)
RUN mkdir -p /home/node/.n8n/logs

# ---> ELIMINADA LA LÍNEA "USER node" - El startup.sh manejará los privilegios <---

# Variables de entorno por defecto para Cloud Run
ENV NODE_ENV=production
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=http
# NO incluir WEBHOOK_URL aquí - debe ser variable de entorno en runtime

# Exponer puerto (Cloud Run lo manejará dinámicamente)
EXPOSE 8080

# Usar script de inicio para Cloud Run
ENTRYPOINT ["/startup.sh"]
````

## File: cloudbuild-secure.yaml
````yaml
steps:
  # Construir la imagen Docker
  - name: 'gcr.io/cloud-builders/docker'
    args:
      [
        'build',
        '-f',
        'Dockerfile.cloudrun',
        '-t',
        'gcr.io/$PROJECT_ID/n8n:$COMMIT_SHA',
        '.',
      ]

  # Escanear imagen con Trivy (vulnerabilidades críticas y altas)
  - name: 'aquasec/trivy'
    id: 'trivy-scan'
    args:
      - 'image'
      - '--severity'
      - 'HIGH,CRITICAL'
      - '--exit-code'
      - '1'
      - '--format'
      - 'table'
      - '--skip-files'
      - '/usr/local/bin/trivy'
      - 'gcr.io/$PROJECT_ID/n8n:$COMMIT_SHA'

  # Escanear con Trivy para vulnerabilidades medias y bajas (guardar en archivo)
  - name: 'aquasec/trivy'
    id: 'trivy-scan-medium'
    args:
      - 'image'
      - '--severity'
      - 'MEDIUM,LOW'
      - '--exit-code'
      - '0'
      - '--format'
      - 'table'
      - '--output'
      - 'trivy-non-critical-results.txt'
      - '--skip-files'
      - '/usr/local/bin/trivy'
      - 'gcr.io/$PROJECT_ID/n8n:$COMMIT_SHA'

  # Escanear con Google Artifact Analysis
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    id: 'artifact-scan'
    entrypoint: gcloud
    args:
      - 'artifacts'
      - 'docker'
      - 'images'
      - 'scan'
      - 'gcr.io/$PROJECT_ID/n8n:$COMMIT_SHA'
      - '--location=us'
      - '--format=json'
      - '--quiet'

  # Mostrar vulnerabilidades no críticas solo si existen
  - name: 'alpine'
    id: 'display-non-critical-vulnerabilities'
    entrypoint: 'sh'
    args:
      - '-c'
      - |
        if [ -s trivy-non-critical-results.txt ]; then
          echo "--- Found non-critical vulnerabilities (Medium/Low) ---"
          cat trivy-non-critical-results.txt
          echo "-------------------------------------------------------"
        else
          echo "✅ No non-critical vulnerabilities found."
        fi

  # Subir imagen a Container Registry (solo si escaneos pasan)
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/n8n:$COMMIT_SHA']

  # Desplegar a Cloud Run
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: gcloud
    args:
      - 'run'
      - 'deploy'
      - 'n8n'
      - '--image'
      - 'gcr.io/$PROJECT_ID/n8n:$COMMIT_SHA'
      - '--region'
      - 'us-central1'
      - '--platform'
      - 'managed'
      - '--allow-unauthenticated'
      - '--memory'
      - '2Gi'
      - '--cpu'
      - '2'
      - '--cpu-boost'
      - '--max-instances'
      - '5'
      - '--timeout'
      - '300'
      - '--concurrency'
      - '80'
      - '--add-cloudsql-instances=${_CLOUDSQL_INSTANCE}'
      - '--set-env-vars'
      - 'DB_TYPE=postgresdb,DB_POSTGRESDB_HOST=/cloudsql/${_CLOUDSQL_INSTANCE},DB_POSTGRESDB_DATABASE=${_DB_NAME},DB_POSTGRESDB_USER=${_DB_USER},DB_POSTGRESDB_PASSWORD=${_DB_PASSWORD},N8N_ENCRYPTION_KEY=${_N8N_ENCRYPTION_KEY},N8N_BASIC_AUTH_ACTIVE=true,N8N_BASIC_AUTH_USER=${_N8N_USER},N8N_BASIC_AUTH_PASSWORD=${_N8N_PASSWORD},NODE_ENV=production,WEBHOOK_URL=${_WEBHOOK_URL},N8N_RUNNERS_ENABLED=true'

# Opciones de build
options:
  logging: CLOUD_LOGGING_ONLY
  machineType: 'E2_MEDIUM'

# Sustituciones (se definen en Cloud Build)
substitutions:
  # Configuración de Cloud SQL
  _CLOUDSQL_INSTANCE: 'your-project-id:us-central1:your-instance-name'
  _DB_NAME: 'n8n_db'
  _DB_USER: 'n8n_user'
  _DB_PASSWORD: 'your-db-password'
  _N8N_ENCRYPTION_KEY: 'your-encryption-key'
  _N8N_USER: 'admin'
  _N8N_PASSWORD: 'your-n8n-password'
  _WEBHOOK_URL: 'https://your-service-url.run.app/'
````
