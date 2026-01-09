#!/bin/bash
# GPU Activation Script for Genesis Q-Mem Stack
# Installs nvidia-container-toolkit and configures Docker daemon

set -e

echo "=========================================="
echo "NVIDIA Container Toolkit Installation"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

echo "[1/6] Checking NVIDIA driver..."
if ! nvidia-smi &> /dev/null; then
    echo "ERROR: nvidia-smi not found. Install NVIDIA drivers first."
    exit 1
fi
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
echo "✓ NVIDIA driver detected"
echo ""

echo "[2/6] Adding NVIDIA Container Toolkit repository..."
# Add GPG key
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Add repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

echo "✓ Repository added"
echo ""

echo "[3/6] Updating package index..."
apt-get update -qq
echo "✓ Package index updated"
echo ""

echo "[4/6] Installing nvidia-container-toolkit..."
apt-get install -y nvidia-container-toolkit
echo "✓ nvidia-container-toolkit installed"
echo ""

echo "[5/6] Configuring Docker runtime..."
nvidia-ctk runtime configure --runtime=docker
echo "✓ Docker runtime configured"
echo ""

echo "[6/6] Restarting Docker daemon..."
systemctl restart docker
echo "✓ Docker daemon restarted"
echo ""

echo "=========================================="
echo "GPU Activation Complete!"
echo "=========================================="
echo ""
echo "Verification:"
docker run --rm --gpus all nvidia/cuda:12.3.1-base-ubuntu22.04 nvidia-smi || echo "Note: Verification requires CUDA image"
echo ""
echo "Next Steps:"
echo "1. Update docker-compose.yml with GPU configuration"
echo "2. Restart containers: docker compose down && docker compose up -d"
echo ""
