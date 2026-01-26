# ────────────────────────────────────────────────
# Stage 1: Builder – install deps & build the app
# ────────────────────────────────────────────────
FROM node:22-slim AS builder

# Set working directory
WORKDIR /app

# Copy package files first → excellent caching
COPY package*.json ./

# Install dependencies (use npm ci for exact lockfile match if you have package-lock.json)
RUN npm ci

# Copy the rest of the source code
COPY . .

# Build for production (creates /app/dist)
# If you need env vars at build time (e.g. VITE_API_URL), pass them via --build-arg
ARG VITE_API_URL=http://localhost:8000
ENV VITE_API_URL=${VITE_API_URL}

RUN npm run build

# ────────────────────────────────────────────────
# Stage 2: Runtime – serve static files with NGINX
# ────────────────────────────────────────────────
FROM nginxinc/nginx-unprivileged:alpine-slim  


# Copy built static files (chown not strictly needed, but harmless)
COPY --from=builder --chown=101:101 /app/dist /usr/share/nginx/html

# Copy custom NGINX config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# No need for addgroup/adduser/chown — image already runs as non-root (UID 101 / nobody/nogroup usually)

# No USER directive needed — image sets it

EXPOSE 80  

CMD ["nginx", "-g", "daemon off;"]