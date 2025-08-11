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