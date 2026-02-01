#!/bin/bash
set -ex

# Update & install basics
apt-get update -y
apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg lsb-release git

# === Official Docker repo setup (includes Buildx + Compose plugin) ===
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y

# Install Docker Engine + Buildx plugin + Compose plugin (this fixes your error)
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start & enable Docker
systemctl daemon-reload
systemctl enable docker
systemctl start docker

# Wait until Docker is ready
sleep 5
until docker info >/dev/null 2>&1; do
echo "Waiting for Docker daemon..."
sleep 3
done

# Add user to docker group
usermod -aG docker ubuntu

# Verify versions (for your logs/debug)
docker --version
docker buildx version   # Should be >= 0.17.0 now
docker compose version  # Should show Compose v2.x

# Clone your repo & deploy (adjust paths/repo)
git clone ${repo_url} /home/ubuntu/app
cd /home/ubuntu/app

# Run compose as the ubuntu user
echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USERNAME" --password-stdin
sudo -u ubuntu docker compose pull || true
sudo -u ubuntu docker compose up -d --remove-orphans

echo "Deployment done at $(date)" > /home/ubuntu/deploy.log
docker ps >> /home/ubuntu/deploy.log
