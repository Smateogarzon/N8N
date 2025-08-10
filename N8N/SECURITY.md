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
