
# **Project**: Simple Hello World Full-Stack App (Django Backend + React/Vite Frontend) 
 
**Phase**: 1 – Containerization (Mandatory)  
**Goal**: Dockerize both services, run via Docker Compose, ensure communication, use best practices (multi-stage, non-root, env vars)

## 1. Project Structure (Relevant to Docker)

```
project-root/
├── backend/
│   ├── Dockerfile             # Multi-stage for Django + Gunicorn
│   ├── requirements.txt
│   ├── .dockerignore
│   └── ... (manage.py, config/, core/, etc.)
├── frontend/
│   ├── Dockerfile             # Multi-stage: Node build → NGINX serve
│   ├── nginx.conf             # SPA routing config
│   ├── .dockerignore
│   └── ... (src/, package.json, vite.config.ts)
├── docker-compose.yml         # Orchestrates both services
├── .gitignore                 # Ignores venv, node_modules, dist, etc.
└── DEVOPS.md                  # This file
```

## 2. Dockerfiles Overview

### Backend (Django) – backend/Dockerfile
- Base: `python:3.12-slim-bookworm` (stable, supports Django 6.0)
- Multi-stage: Builder installs deps → Runtime copies only needed artifacts
- Non-root: Creates `appuser`, `chown -R`, `USER appuser`
- Server: Gunicorn (production-ready, not runserver)
- Size: ~120–180 MB (optimized)

### Frontend (React/Vite) – frontend/Dockerfile
- Base: `node:20-slim` (builder) → `nginxinc/nginx-unprivileged:alpine-slim` (runtime)
- Multi-stage: Builds static files → Serves via NGINX
- Non-root: `adduser -S appuser`, `chown -R`, `USER appuser`
- SPA support: Custom `nginx.conf` with `try_files` for client routing
- Size: ~80–120 MB (very lightweight)

## 3. docker-compose.yml Overview

Located at project root.

Key features:
- Builds both images automatically
- Maps ports: backend 8000, frontend 3000
- Environment variables:
  - Backend: `DEBUG=1` (can toggle to 0 in prod)
  - Frontend: `VITE_API_URL=http://backend:8000` (uses Docker network service name)
- Depends-on: Frontend waits for backend to be ready (basic ordering)

## 4. Setup Guide – How to Run

### Prerequisites
- Docker Desktop / Docker Engine + Compose plugin installed
- Git clone the repo

### Local Development (without Docker)
(For quick iterations – still works after containerization)

**Backend**  
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py runserver
```

**Frontend**  
```bash
cd frontend
npm install
npm run dev
```

URLs:  
- API: http://localhost:8000/api/hello/  
- App: http://localhost:5173/

### Dockerized Run (Phase 1 Goal – One Command)

From project root:

1. Build & start both services  
   ```bash
   docker compose up --build
   ```
   - First time: 3–8 minutes (downloads layers, builds images)  
   - Later: 10–60 seconds

2. Open in browser:
   - Frontend (React app): http://localhost:3000  
   - Backend API test: http://localhost:8000/api/hello/

3. Stop: Ctrl+C in terminal, or  
   ```bash
   docker compose down
   ```

**Expected behavior**:  
Frontend fetches "Hello World from Django!" from backend automatically via Axios. No CORS issues inside Docker network.

### Environment Variables Usage
- Backend: Set `DEBUG=0` for production-like mode (change in compose file)
- Frontend: `VITE_API_URL` controls API base (defaults to container-internal URL)
- Add more via `.env` file later (e.g. for secrets) – not committed to git



