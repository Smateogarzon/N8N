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
