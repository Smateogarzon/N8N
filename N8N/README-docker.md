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
