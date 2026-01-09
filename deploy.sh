#!/bin/bash
# Q-Mem Stack Automated Deployment

set -e

echo "Q-Mem Stack Deployment"
echo "======================"

# Check GPU
echo -n "Checking GPU... "
if nvidia-smi &> /dev/null; then
    echo "OK"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
else
    echo "FAILED - nvidia-smi not found"
    exit 1
fi

# Check Docker
echo -n "Checking Docker... "
if docker --version &> /dev/null; then
    echo "OK"
else
    echo "FAILED"
    exit 1
fi

# Check model
echo -n "Checking Phi-2 model... "
if [ -f "models/phi-2.Q4_K_M.gguf" ]; then
    echo "OK ($(du -h models/phi-2.Q4_K_M.gguf | cut -f1))"
else
    echo "MISSING"
    echo ""
    echo "Download from: https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf"
    echo "Place in: $(pwd)/models/phi-2.Q4_K_M.gguf"
    exit 1
fi

# Check ports
echo "Checking ports..."
for port in 8080 6379; do
    if ss -tlnp | grep -q ":$port "; then
        echo "  WARNING: Port $port in use"
    else
        echo "  Port $port: available"
    fi
done

echo ""
echo "Deploying..."

# Stop existing
docker compose down 2>/dev/null || true

# Pull and build
docker compose pull
docker compose build

# Start
docker compose up -d

echo ""
echo "Waiting for services..."
sleep 15

# Status
docker compose ps

echo ""
echo "Testing endpoints..."
echo -n "  LLM (8080): "
curl -s -f http://localhost:8080/health > /dev/null && echo "OK" || echo "WAITING"

echo -n "  Redis (6379): "
redis-cli -h localhost PING 2>/dev/null || echo "WAITING"

echo ""
echo "Deployment complete!"
echo "  Logs: docker compose logs -f"
echo "  Status: ./status.sh"
