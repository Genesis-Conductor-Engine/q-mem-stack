#!/bin/bash
# GPU-Enabled Restart Sequence for Q-Mem Stack

set -e

STACK_DIR="/home/nav/q-mem-stack"

echo "=========================================="
echo "Q-Mem Stack GPU Restart Sequence"
echo "=========================================="
echo ""

cd "$STACK_DIR"

echo "[1/4] Stopping current CPU-mode containers..."
docker compose down
echo "✓ Containers stopped"
echo ""

echo "[2/4] Removing old container images (force clean)..."
docker compose rm -f
echo "✓ Old containers removed"
echo ""

echo "[3/4] Starting GPU-enabled stack..."
docker compose up -d --force-recreate
echo "✓ Containers recreated with GPU support"
echo ""

echo "[4/4] Verifying GPU activation..."
sleep 5
docker logs genesis-llm-phi2 2>&1 | grep -i "gpu\|cuda\|nvidia" | head -10 || echo "Check logs manually if GPU info not shown above"
echo ""

echo "=========================================="
echo "Container Status:"
echo "=========================================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "=========================================="
echo "GPU Verification Commands:"
echo "=========================================="
echo "  docker exec genesis-llm-phi2 nvidia-smi"
echo "  docker logs genesis-llm-phi2 | grep -i 'ngl\|gpu'"
echo "  curl -s http://localhost:8082/health"
echo ""
