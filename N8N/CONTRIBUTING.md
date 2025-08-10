# Contribuyendo al Proyecto n8n Docker

¡Gracias por tu interés en contribuir! Este documento proporciona las pautas para contribuir al proyecto.

## 🚀 Cómo Contribuir

### 1. Fork y Clone

```bash
# Fork el repositorio en GitHub
# Luego clona tu fork
git clone https://github.com/tu-usuario/n8n-docker.git
cd n8n-docker
```

### 2. Crear una Rama

```bash
git checkout -b feature/nombre-de-tu-feature
# o
git checkout -b fix/nombre-del-fix
```

### 3. Hacer Cambios

- Sigue las convenciones de código existentes
- Añade tests si es necesario
- Actualiza la documentación
- Verifica que los scripts funcionen

### 4. Probar Cambios

```bash
# Probar construcción
./test-simple.sh

# Probar ejecución
./test-simple-n8n.sh

# Escanear vulnerabilidades
./scan-local.sh  # Linux/macOS
# o
.\scan-simple.ps1  # Windows
```

### 5. Commit y Push

```bash
git add .
git commit -m "feat: descripción del cambio"
git push origin feature/nombre-de-tu-feature
```

### 6. Crear Pull Request

- Ve a GitHub y crea un Pull Request
- Describe claramente los cambios
- Incluye información de testing

## 📋 Convenciones

### Commits

Usa el formato convencional:

- `feat:` nueva característica
- `fix:` corrección de bug
- `docs:` cambios en documentación
- `style:` cambios de formato
- `refactor:` refactorización
- `test:` añadir tests
- `chore:` tareas de mantenimiento

### Código

- Usa nombres descriptivos
- Comenta código complejo
- Sigue las mejores prácticas de Docker
- Mantén la seguridad como prioridad

## 🔒 Seguridad

- Nunca subas credenciales o secretos
- Verifica vulnerabilidades antes de contribuir
- Reporta problemas de seguridad de forma privada

## 📚 Recursos

- [Documentación de n8n](https://docs.n8n.io/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

## 🤝 Contacto

Si tienes preguntas, abre un issue en GitHub.
