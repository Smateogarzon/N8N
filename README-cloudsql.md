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
