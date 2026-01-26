# ────────────────────────────────────────────────
# Stage 1: Builder – install dependencies with build tools
# ────────────────────────────────────────────────
FROM python:3.12-slim-bookworm AS builder

# Working directory inside container
WORKDIR /app

# Prevent Python from writing .pyc files and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install build dependencies (these stay only in builder stage)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first → better layer caching
COPY requirements.txt .

# Upgrade pip and install dependencies
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ────────────────────────────────────────────────
# Stage 2: Final runtime image – slim, secure, non-root
# ────────────────────────────────────────────────
FROM python:3.12-slim-bookworm

# Set working directory
WORKDIR /app

# Same env vars as builder
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install only runtime necessities (very minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Copy Python packages & scripts from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy your entire Django project
COPY . .

# Create non-root user/group + fix ownership (important security step)
RUN groupadd -r appgroup && \
    useradd -r -g appgroup -m -s /sbin/nologin appuser && \
    chown -R appuser:appgroup /app

# Switch to non-root user (security best practice)
USER appuser

# Expose port
EXPOSE 8000

# Run with Gunicorn (adjust workers/threads for your needs; 2–4 workers good for small app)
CMD ["gunicorn", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "2", \
     "--threads", "4", \
     "--timeout", "120", \
     "--log-level", "info", \
     "config.wsgi:application"]