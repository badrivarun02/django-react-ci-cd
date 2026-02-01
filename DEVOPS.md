
# **Project**: Simple Hello World Full-Stack App (Django Backend + React/Vite Frontend) 
 
## **Phase** 1: Containerization   
**Goal**: Dockerize both services, run via Docker Compose, ensure communication, use best practices (multi-stage, non-root, env vars)

## 1. **Project Structure** (Relevant to Docker)

* **`backend/`**: Contains the Django application.
* **`Dockerfile`**: A multi-stage build for the Django server using Gunicorn.
* **`requirements.txt`**: Lists Python dependencies.
* **`.dockerignore`**: Prevents unnecessary files from being sent to the Docker image.
* **App Files**: Includes `manage.py`, project configuration, and core logic.


* **`frontend/`**: Contains the React/Vite application.
* **`Dockerfile`**: A multi-stage build that compiles Node.js code and serves it via NGINX.
* **`nginx.conf`**: Configuration for NGINX to handle Single Page Application (SPA) routing.
* **`.dockerignore`**: Excludes `node_modules` and local builds from Docker.
* **App Files**: Includes source code, dependencies, and build settings.


* **`docker-compose.yml`**: The main configuration file to run and connect both the backend and frontend services.
* **`.gitignore`**: Ensures temporary files like virtual environments and build folders are not tracked by Git.

## 2. Dockerfiles Overview

### Backend (Django) – backend/Dockerfile
- Base: `python:3.12-slim-bookworm` (stable, supports Django 6.0)
- Multi-stage: Builder installs deps → Runtime copies only needed artifacts
- Non-root: Creates `appuser`, `chown -R`, `USER appuser`
- Server: Gunicorn (production-ready, not runserver)
- Size: ~266 MB (optimized)

### Frontend (React/Vite) – frontend/Dockerfile
- Base: `node:20-slim` (builder) → `nginxinc/nginx-unprivileged:alpine-slim` (runtime)
- Multi-stage: Builds static files → Serves via NGINX
- Non-root: `adduser -S appuser`, `chown -R`, `USER appuser`
- SPA support: Custom `nginx.conf` with `try_files` for client routing
- Size: ~30 MB (very lightweight)

## 3. docker-compose.yml Overview

Located at project root.

Key features:
- Builds both images automatically
- Maps ports: backend 8000, frontend 80
- Environment variables:
  - Backend: `DEBUG=0` (can toggle to 0 in prod)
  - Frontend: `VITE_API_URL=http://backend:8000` (uses Docker network service name)
- Depends-on: Frontend waits for backend to be ready (basic ordering)

## 4. Setup Guide – How to Run

### Prerequisites
- Docker Desktop / Docker Engine + Compose plugin installed
- Git clone the repo


### Dockerized Run (Phase 1 Goal – One Command)

From project root:

1. **Build & Start** (Local Test) 
   ```bash
   docker compose up --build 
   ```
   - First time: 3–8 minutes (downloads layers, builds images)  
   - Later: 10–60 seconds
   - *Frontend (React):* http://localhost:80
   - *Backend (Django/Gunicorn):* Running on port 8000 (internal)

2. **Stop Services**
	```bash
	# Use Ctrl+C or:
	docker compose down
	```

3. **Login to Registry**
    ```bash
    docker login -u <username>
    # When prompted for password, paste your Docker Hub Token
    ```

4. **Upload Images**
    ```bash
    docker compose push
    ```

**Everything looks solid!** This flow ensures that the images you just tested locally are exactly what gets pushed to the cloud.

**Expected behavior**:  
Frontend fetches "Hello World from Django!" from backend automatically via Axios. No CORS issues inside Docker network.

### Environment Variables Usage
- Backend: Set `DEBUG=0` for production-like mode (change in compose file)
- Frontend: `VITE_API_URL` controls API base (defaults to container-internal URL)
- Add more via `.env` file later (e.g. for secrets) – not committed to git


## **Phase** 2: CI/CD Pipeline 

**Goal**: Every push to the `main` branch automatically:
1. Builds Docker images for backend and frontend
2. Pushes them to Docker Hub
3. Deploys the updated app

We provide **two options**:
- **Standard** → Deploy to your local machine (laptop/desktop) using a self-hosted GitHub Actions runner (zero cost, great for development/testing)
- **Plus Point** → Automatically deploy to AWS EC2 using Terraform (real cloud, costs money after free tier)

**Choose only one at a time** — keep only one active `.yml` file in `.github/workflows/`.

### Prerequisites (Do Once)

For **both** options:
1. Create Docker Hub account (if not already) → hub.docker.com
2. Generate Docker Hub **access token** (not password): Account Settings → Security → New Access Token
3. In GitHub repo → Settings → Secrets and variables → Actions → New repository secret:
   - `DOCKER_USERNAME` = your Docker Hub username
   - `DOCKER_PASSWORD` = the access token you created

For **Cloud option only** (later):
- AWS IAM user with `AmazonEC2FullAccess` (or minimal EC2 + IAM PassRole)
- `aws configure` on your laptop with that user's keys
- For examples secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` (e.g. `us-east-1`)

### Option 1 – Standard: Local Deployment (Self-Hosted Runner)

**Workflow file**: `.github/workflows/ci-cd-local.yml`

**What happens**:
- On push to main → GitHub builds & pushes images to Docker Hub
- Then runs deployment job **on your laptop** → pulls images + `docker compose up -d`

**Steps to activate**:

1. **Rename the file**  
   Find the local version (probably `ci-cd-local.yml.backup` or similar) → rename to `ci-cd-local.yml`  
   Make sure the cloud version stays `.backup` or different name.

2. **Set up self-hosted runner on your laptop** (one-time, ~10 min)
   - Go to repo → Settings → Actions → Runners → New self-hosted runner
   - Choose OS (Linux/macOS/Windows)
   - Copy-paste the commands GitHub shows into a terminal on your laptop
   - Example (Linux):
     ```bash
     mkdir actions-runner && cd actions-runner
     curl -o actions-runner-linux-x64.tar.gz -L https://github.com/actions/runner/releases/download/v2.XXX/actions-runner-linux-x64-2.XXX.tar.gz
     tar xzf ./actions-runner-linux-x64.tar.gz
     ./config.sh --url https://github.com/YOURUSERNAME/YOURREPO --token LONG_TOKEN_HERE
     ```
   - When prompted: add labels if you want (e.g. `local`)
   - Install as service (recommended):
     ```bash
     ./svc.sh install
     ./svc.sh start
     ```
   - Check GitHub → Runners page: your laptop should show "Idle" (green)

3. **Prepare your laptop**
   - Docker + Docker Compose installed
   - `docker compose` command works (not old `docker-compose`)
   - Your repo has `docker-compose.yml` in root referencing:
     ```yaml
     services:
       backend:
         image: YOURUSERNAME/hello-django-backend:latest
       frontend:
         image: YOURUSERNAME/hello-react-frontend:latest
     ```

4. **Test**
   - Push any change to `main`
   - Watch repo → Actions tab
   - After success → open http://localhost:80 (or your port)

**Notes**:
- Runner must stay running (service survives reboot)
- If offline → restart with `./svc.sh start` or `./run.sh`
- For production → switch to real cloud (this is dev-friendly fallback)

### Option 2 – Plus Point: Cloud Deployment to AWS EC2 + Terraform

**Workflow file**: `.github/workflows/ci-cd-cloud.yml`

**What happens**:
- Build & push images (same as local)
- Then: Terraform provisions EC2 → user_data script installs Docker, clones repo, pulls images, runs `docker compose up`
- App becomes live on public IP port 80

**Extra Prerequisites**
- Terraform installed on your laptop (`terraform version` → should work)
- AWS CLI installed & configured (`aws configure`)
- GitHub secrets added (see above)

**Steps to activate**:

1. **Rename workflow**  
   Rename cloud version to `ci-cd-cloud.yml` (only one active!)

2. **Test**
   - Push to main
   - Workflow → look at summary/output for `public_ip`
   - Access: http://<public_ip>

**Cleanup** (important – avoids charges!):
```bash
cd terraform
terraform destroy -auto-approve
```

**Security Notes**
- Restrict SSH to your IP only
- Use HTTPS in prod (add certbot/Let's Encrypt in user_data)
- Don't commit secrets – use GitHub secrets + TF vars
- For real prod: use ECR instead of Docker Hub, ECS/Fargate instead of plain EC2, OIDC instead of keys

Pick local first, get it working, then add cloud when ready.



## **Troubleshoot Logs**:
## 2. Nginx container fails to start – "mkdir /var/cache/nginx/client_temp Permission denied"

**Symptoms** (from `docker compose logs frontend`)  
```
nginx: [emerg] mkdir() "/var/cache/nginx/client_temp" failed (13: Permission denied)
frontend-1  | exited with code 1
```

**Root Cause**  
- Using `nginx:alpine` or `nginx:alpine-slim` base image + custom non-root user (e.g. `USER appuser`)  
- Nginx needs to create temporary directories at runtime (`/var/cache/nginx/*_temp`)  
- These folders are not pre-created or owned by the non-root user → permission denied  
- Very common in WSL2, rootless Docker setups, security-hardened images, or Kubernetes when running as non-root.

**Solutions that worked / recommended**

1. **Best & cleanest fix** – Switch to the official **unprivileged** variant  
   In your `./frontend/Dockerfile`:

   ```dockerfile
   # Stage 2 (final image)
   FROM nginxinc/nginx-unprivileged:alpine-slim    # ← this tag is reliable
   # Alternatives: nginxinc/nginx-unprivileged:stable-alpine
   #               nginxinc/nginx-unprivileged:1.27-alpine (if you want version pin)

   # Copy built React/Vite files with correct ownership
   COPY --from=builder --chown=101:101 /app/dist /usr/share/nginx/html

   # Copy your config
   COPY nginx.conf /etc/nginx/conf.d/default.conf

   # Unprivileged image listens on 8080 by default (not 80)
   EXPOSE 8080

   # Remove manual user/group creation & USER line – image already handles non-root
   ```

   Update `docker-compose.yml`:
   ```yaml
   services:
     frontend:
       ports:
         - "80:8080"      # Host port 80 → container port 8080
         # or "3000:8080" if you prefer accessing via :3000
   ```

   Then rebuild:
   ```bash
   docker compose down
   docker compose build frontend
   docker compose up -d
   ```

2. **If you must keep official nginx image** (less preferred)  
   Add runtime directory setup before the `USER` line:
   ```dockerfile
   RUN mkdir -p /var/cache/nginx/{client,proxy,fastcgi,uwsgi,scgi}_temp \
       && chown -R nginx:nginx /var/cache/nginx \
       && chmod -R 755 /var/cache/nginx \
       && touch /var/run/nginx.pid \
       && chown nginx:nginx /var/run/nginx.pid
   ```

**Why previous attempts sometimes failed**  
- Using invalid tag like `nginxinc/nginx-unprivileged:1.27-alpine-slim` → parse error  
- Correct common tags: `alpine-slim`, `stable-alpine`, `1.27-alpine`, `alpine3.22-slim`, etc. (check Docker Hub for latest)

## Quick Reference Commands

```bash
# Clean frontend & reinstall deps (after Node upgrade)
cd frontend
rm -rf node_modules package-lock.json
npm install

# Rebuild & restart everything
docker compose down
docker compose up -d --build

# Or just rebuild frontend
docker compose build frontend
docker compose up -d --force-recreate frontend

# Watch logs
docker compose logs -f frontend