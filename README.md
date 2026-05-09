# 🚀 Backend Innovatech Chile — EP2 ISY1101

Microservicio backend de la aplicación Innovatech Chile, construido con **Node.js + Express + MySQL**, contenedorizado con Docker y desplegado automáticamente en AWS EC2 mediante GitHub Actions.

---

## 📐 Arquitectura

```
Internet
   │
   ▼
[EC2 Frontend - subred pública 10.0.1.0/24]
   │  HTTP → puerto 3000 (IP privada EC2 Backend)
   ▼
[EC2 Backend - subred privada 10.0.2.0/24]
   │  contenedor: innovatech-backend (Node.js :3000)
   │  contenedor: innovatech-db      (MySQL :3306)
   │  volumen:    db_data            (persistencia)
```

---

## 📦 Estructura del repositorio

```
innovatech-backend/
├── app.js                         # Aplicación Express principal
├── package.json                   # Dependencias del proyecto
├── test.js                        # Pruebas unitarias
├── Dockerfile                     # Multi-stage build (builder + runtime)
├── docker-compose.yml             # Stack completo: backend + MySQL
├── .env.example                   # Variables de entorno de referencia
├── .gitignore
└── .github/
    └── workflows/
        └── deploy.yml             # Pipeline CI/CD (build → push ECR → deploy EC2)
```

---

## 🐳 Dockerfile — Multi-stage Build

| Stage | Base | Propósito |
|-------|------|-----------|
| `builder` | `node:18-alpine` | Instala dependencias de producción |
| `runtime` | `node:18-alpine` | Imagen final mínima, usuario no root |

**Buenas prácticas aplicadas:**
- ✅ Multi-stage build (imagen final más pequeña y segura)
- ✅ Usuario no root (`appuser`) — principio de mínimo privilegio
- ✅ `npm ci --only=production` — solo dependencias necesarias
- ✅ `npm cache clean --force` — limpieza de capas
- ✅ `HEALTHCHECK` integrado

---

## ⚙️ Variables de entorno

Copia `.env.example` como `.env` y ajusta los valores:

```bash
cp .env.example .env
```

| Variable | Descripción | Default |
|----------|-------------|---------|
| `PORT` | Puerto del backend | `3000` |
| `DB_HOST` | Host MySQL (nombre servicio Docker) | `db` |
| `DB_PORT` | Puerto MySQL | `3306` |
| `DB_USER` | Usuario de la base de datos | `admin` |
| `DB_PASSWORD` | Contraseña de la base de datos | `password123` |
| `DB_NAME` | Nombre de la base de datos | `innovatech` |
| `MYSQL_ROOT_PASSWORD` | Contraseña root MySQL | `rootpassword` |

---

## 🚀 Cómo ejecutar localmente

```bash
# 1. Clonar el repositorio
git clone https://github.com/tu-usuario/innovatech-backend.git
cd innovatech-backend

# 2. Configurar variables de entorno
cp .env.example .env

# 3. Levantar el stack completo (backend + MySQL)
docker compose up -d

# 4. Ver logs
docker compose logs -f

# 5. Verificar que está corriendo
curl http://localhost:3000/health
```

---

## 🔗 Endpoints disponibles

| Método | Ruta | Descripción |
|--------|------|-------------|
| `GET` | `/` | Info del servicio |
| `GET` | `/health` | Health check |
| `GET` | `/db-status` | Estado de conexión a MySQL |
| `GET` | `/usuarios` | Listar usuarios |
| `POST` | `/usuarios` | Crear usuario `{ "nombre": "", "email": "" }` |

---

## 💾 Persistencia de datos

Se utiliza un **named volume** (`db_data`) para el contenedor MySQL:

```yaml
volumes:
  db_data:
    driver: local
```

**Justificación named volume vs bind mount:**
- Los datos persisten aunque el contenedor se elimine y recree
- No depende de rutas del sistema host → más portable entre entornos
- Docker gestiona el ciclo de vida del volumen de forma segura
- Ideal para bases de datos en entornos contenerizados

---

## 🔄 Pipeline CI/CD

Se activa automáticamente al hacer **push a la rama `deploy`**:

```
push → rama deploy
        │
        ▼
   [Job 1: Build & Push]
   ├── Checkout código
   ├── Configurar credenciales AWS
   ├── Login a ECR
   ├── docker build (multi-stage)
   └── docker push → ECR (:sha + :latest)
        │
        ▼
   [Job 2: Deploy EC2]
   ├── SSH a instancia EC2 Backend
   ├── Pull nueva imagen desde ECR
   ├── docker compose down
   ├── docker compose up -d
   └── curl /health (verificación)
```

### GitHub Secrets requeridos

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Credencial AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS Academy |
| `AWS_SESSION_TOKEN` | Token de sesión AWS Academy |
| `EC2_BACKEND_SSH_KEY` | Clave privada PEM de la EC2 Backend |
| `EC2_BACKEND_HOST` | IP pública de la EC2 Backend |
| `DB_PASSWORD` | Contraseña de la base de datos |
| `DB_ROOT_PASSWORD` | Contraseña root de MySQL |

---

## 🛡️ Seguridad

- Backend en **subred privada** de AWS (no accesible desde Internet)
- Solo el Frontend puede comunicarse con el backend (Security Groups)
- Credenciales gestionadas mediante **GitHub Secrets**
- Contenedor corre con usuario no root

---

## 🧪 Tests

```bash
node test.js
```

---

*EP2 — ISY1101 Introducción a Herramientas DevOps — DuocUC 2025*
