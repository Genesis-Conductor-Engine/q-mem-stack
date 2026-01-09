#!/bin/bash
# Q-Mem Stack Status

echo "Q-Mem Stack Status"
echo "=================="
echo ""

# Container status
echo "Containers:"
docker compose ps 2>/dev/null || echo "  Not running"

echo ""

# GPU status
echo "GPU:"
nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader 2>/dev/null || echo "  Not available"

echo ""

# LLM health
echo -n "LLM Server (8080): "
if curl -s -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "HEALTHY"
else
    echo "DOWN"
fi

# Redis health
echo -n "Redis Cache (6379): "
if redis-cli -h localhost PING 2>/dev/null | grep -q PONG; then
    echo "HEALTHY"
    redis-cli -h localhost INFO memory 2>/dev/null | grep -E "used_memory_human|maxmemory_human" | sed 's/^/  /'
else
    echo "DOWN"
fi

echo ""
