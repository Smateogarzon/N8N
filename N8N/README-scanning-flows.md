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
