# ============================================================
# STAGE 1: Builder
# Instala dependencias de producción solamente
# ============================================================
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar solo los archivos de dependencias primero (aprovecha cache de capas)
COPY package*.json ./

# Instalar solo dependencias de producción y limpiar cache
RUN npm ci --only=production && npm cache clean --force

# ============================================================
# STAGE 2: Runtime (imagen final mínima)
# ============================================================
FROM node:18-alpine AS runtime

# Crear grupo y usuario no root (principio de mínimo privilegio)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiar dependencias instaladas desde el stage builder
COPY --from=builder /app/node_modules ./node_modules

# Copiar el código fuente
COPY app.js ./
COPY package.json ./

# Cambiar propietario de los archivos al usuario no root
RUN chown -R appuser:appgroup /app

# Usar usuario no root
USER appuser

# Puerto que expone el backend
EXPOSE 3000

# Healthcheck para que Docker sepa si el contenedor está OK
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "app.js"]
