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
