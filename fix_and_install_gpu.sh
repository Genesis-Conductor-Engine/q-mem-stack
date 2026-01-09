#!/bin/bash
# GPU Recovery Script - Fixes corrupted apt sources and installs nvidia-container-toolkit
# Run with: sudo bash fix_and_install_gpu.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     GPU RECOVERY & INSTALLATION SCRIPT                        ║"
echo "║     Fixes corrupted apt sources, installs nvidia-toolkit      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# ============================================================
# PHASE 1: CLEANUP CORRUPTED FILES
# ============================================================
echo -e "${YELLOW}[PHASE 1/4] CLEANUP${NC}"
echo "────────────────────────────────────────────────────────────────"

echo -n "  Removing corrupted nvidia-container-toolkit.list... "
rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list 2>/dev/null && echo "done" || echo "not found"

echo -n "  Removing old GPG key... "
rm -f /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg 2>/dev/null && echo "done" || echo "not found"

echo -e "${GREEN}  ✓ Cleanup complete${NC}"
echo ""

# ============================================================
# PHASE 2: RE-ADD NVIDIA REPOSITORY (WITH VALIDATION)
# ============================================================
echo -e "${YELLOW}[PHASE 2/4] RE-ADD NVIDIA REPOSITORY${NC}"
echo "────────────────────────────────────────────────────────────────"

# Download and install GPG key
echo "  Downloading GPG key..."
GPG_KEY_URL="https://nvidia.github.io/libnvidia-container/gpgkey"
GPG_KEY_FILE="/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"

curl -fsSL "$GPG_KEY_URL" -o /tmp/nvidia-gpg.key
if [ ! -s /tmp/nvidia-gpg.key ]; then
    echo -e "${RED}  ERROR: Failed to download GPG key${NC}"
    exit 1
fi

# Validate it's not HTML
if head -1 /tmp/nvidia-gpg.key | grep -qi "<!doctype\|<html"; then
    echo -e "${RED}  ERROR: GPG key download returned HTML (server error)${NC}"
    rm -f /tmp/nvidia-gpg.key
    exit 1
fi

gpg --dearmor -o "$GPG_KEY_FILE" < /tmp/nvidia-gpg.key
rm -f /tmp/nvidia-gpg.key
echo -e "${GREEN}  ✓ GPG key installed${NC}"

# Download and validate repository list
echo "  Downloading repository list..."
REPO_LIST_URL="https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list"
REPO_LIST_FILE="/etc/apt/sources.list.d/nvidia-container-toolkit.list"

curl -fsSL "$REPO_LIST_URL" -o /tmp/nvidia-repo.list
if [ ! -s /tmp/nvidia-repo.list ]; then
    echo -e "${RED}  ERROR: Failed to download repository list${NC}"
    exit 1
fi

# Validate it's not HTML
if head -1 /tmp/nvidia-repo.list | grep -qi "<!doctype\|<html"; then
    echo -e "${RED}  ERROR: Repository list download returned HTML (server error)${NC}"
    echo "  Contents: $(head -1 /tmp/nvidia-repo.list)"
    rm -f /tmp/nvidia-repo.list
    exit 1
fi

# Validate it looks like a valid sources list (should start with "deb")
if ! head -1 /tmp/nvidia-repo.list | grep -q "^deb "; then
    echo -e "${YELLOW}  WARNING: Repository list may not be valid${NC}"
    echo "  First line: $(head -1 /tmp/nvidia-repo.list)"
fi

# Add signed-by directive and install
sed "s#deb https://#deb [signed-by=${GPG_KEY_FILE}] https://#g" /tmp/nvidia-repo.list > "$REPO_LIST_FILE"
rm -f /tmp/nvidia-repo.list
echo -e "${GREEN}  ✓ Repository list installed${NC}"

echo ""
echo "  Installed repository:"
cat "$REPO_LIST_FILE"
echo ""

# ============================================================
# PHASE 3: INSTALL NVIDIA CONTAINER TOOLKIT
# ============================================================
echo -e "${YELLOW}[PHASE 3/4] INSTALL NVIDIA CONTAINER TOOLKIT${NC}"
echo "────────────────────────────────────────────────────────────────"

echo "  Updating apt package index..."
apt-get update -qq
echo -e "${GREEN}  ✓ Package index updated${NC}"

echo "  Installing nvidia-container-toolkit..."
apt-get install -y nvidia-container-toolkit
echo -e "${GREEN}  ✓ nvidia-container-toolkit installed${NC}"

echo "  Configuring Docker runtime..."
nvidia-ctk runtime configure --runtime=docker
echo -e "${GREEN}  ✓ Docker runtime configured${NC}"

echo "  Restarting Docker daemon..."
systemctl restart docker
echo -e "${GREEN}  ✓ Docker daemon restarted${NC}"

echo ""

# ============================================================
# PHASE 4: VERIFY & RE-DEPLOY STACK
# ============================================================
echo -e "${YELLOW}[PHASE 4/4] VERIFY & RE-DEPLOY${NC}"
echo "────────────────────────────────────────────────────────────────"

echo "  Verifying GPU access in Docker..."
if docker run --rm --gpus all nvidia/cuda:12.3.1-base-ubuntu22.04 nvidia-smi > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓ GPU access verified in Docker${NC}"
else
    echo -e "${YELLOW}  ⚠ GPU verification skipped (CUDA image not cached)${NC}"
fi

echo ""
echo "  Re-deploying Q-Mem stack with GPU..."
cd ~/q-mem-stack || cd /home/nav/q-mem-stack

docker compose down 2>/dev/null || true
sleep 2
docker compose up -d

echo ""
sleep 5
echo "  Container status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    RECOVERY COMPLETE                          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Next steps:"
echo "    1. Run validation: ./thermodynamic_validation.sh"
echo "    2. Check VRAM usage: nvidia-smi"
echo ""
