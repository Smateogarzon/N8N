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
# 1. Configurar Cloud SQL y variables de entorno (OBLIGATORIO)
./setup-cloudsql.sh

# 2. Solucionar problema de entrypoint con configuración oficial
./fix-entrypoint-issue.sh

# 3. Desplegar (automático con git push)
git add .
git commit -m "fix: usar entrypoint oficial de n8n y configuración correcta"
git push origin main
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
