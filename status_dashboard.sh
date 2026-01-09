#!/bin/bash
# Q-Mem Stack Status Dashboard
# Shows all services, endpoints, and capabilities

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================================================"
echo "                   GENESIS Q-MEM STACK STATUS"
echo "========================================================================"
echo ""

# System Resources
echo "${BLUE}[SYSTEM RESOURCES]${NC}"
echo "------------------------------------------------------------------------"
free -h | awk 'NR==1 {print "         "$1"    "$2"    "$3"    "$4"    "$5"    "$6} NR==2 {printf "RAM:     %s   %s   %s (%s available)\n", $2, $3, $4, $7} NR==3 {printf "SWAP:    %s   %s   %s\n", $2, $3, $4}'
echo ""
echo "CPU Cores: $(nproc)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# GPU Status
echo "${BLUE}[GPU STATUS]${NC}"
echo "------------------------------------------------------------------------"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,driver_version,memory.used,memory.total,utilization.gpu --format=csv,noheader | \
    awk -F', ' '{printf "GPU: %s\nDriver: %s\nVRAM: %s / %s\nUtilization: %s\n", $1, $2, $3, $4, $5}'
else
    echo "nvidia-smi not available"
fi
echo ""

# Docker Context
echo "${BLUE}[DOCKER CONTEXT]${NC}"
echo "------------------------------------------------------------------------"
docker context show
docker info 2>&1 | grep -A 3 "Runtimes:"
echo ""

# Container Status
echo "${BLUE}[CONTAINER STATUS]${NC}"
echo "------------------------------------------------------------------------"
printf "%-25s %-20s %-10s\n" "CONTAINER" "STATUS" "PORTS"
echo "------------------------------------------------------------------------"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tail -n +2 | while read line; do
    container=$(echo $line | awk '{print $1}')
    status=$(echo $line | awk '{print $2}')

    if [[ $status == "Up" ]]; then
        echo -e "${GREEN}$line${NC}"
    else
        echo -e "${RED}$line${NC}"
    fi
done
echo ""

# Service Endpoints & Capabilities
echo "${BLUE}[SERVICE ENDPOINTS & CAPABILITIES]${NC}"
echo "========================================================================"
echo ""

# LLM Server
echo "${YELLOW}1. LLM Inference Server (Phi-2)${NC}"
echo "   Container: genesis-llm-phi2"
echo "   Endpoint:  http://localhost:8082"
echo "   Health:    http://localhost:8082/health"
if curl -s http://localhost:8082/health &> /dev/null; then
    echo -e "   Status:    ${GREEN}ONLINE${NC}"
    echo "   Capabilities:"
    echo "      - Text completion: POST /v1/completions"
    echo "      - Chat completion: POST /v1/chat/completions"
    echo "      - Model info: GET /v1/models"
    echo "      - GPU offload: -ngl 33 (full offload)"
    echo "      - Context window: 2048 tokens"
    echo "      - Quantization: Q4_K_M"
else
    echo -e "   Status:    ${RED}OFFLINE${NC}"
fi
echo ""

# Redis Cache
echo "${YELLOW}2. Quantum Cache (Redis)${NC}"
echo "   Container: genesis-q-mem"
echo "   Endpoint:  localhost:6379"
if docker exec genesis-q-mem redis-cli ping &> /dev/null 2>&1; then
    echo -e "   Status:    ${GREEN}ONLINE${NC}"
    REDIS_INFO=$(docker exec genesis-q-mem redis-cli INFO memory 2>/dev/null | grep "used_memory_human\|maxmemory_human" || echo "")
    if [ ! -z "$REDIS_INFO" ]; then
        USED=$(echo "$REDIS_INFO" | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
        MAX=$(echo "$REDIS_INFO" | grep "maxmemory_human" | cut -d: -f2 | tr -d '\r')
        echo "   Memory:    $USED / $MAX"
    fi
    KEY_COUNT=$(docker exec genesis-q-mem redis-cli DBSIZE 2>/dev/null | awk '{print $2}' || echo "N/A")
    echo "   Keys:      $KEY_COUNT"
    echo "   Capabilities:"
    echo "      - Vector caching"
    echo "      - LRU eviction policy"
    echo "      - Max memory: 1500mb"
else
    echo -e "   Status:    ${RED}OFFLINE${NC}"
fi
echo ""

# Orchestrator
echo "${YELLOW}3. Health Orchestrator (q-mem-sync)${NC}"
echo "   Container: q-mem-sync"
if docker ps --filter "name=q-mem-sync" --filter "status=running" | grep -q q-mem-sync; then
    echo -e "   Status:    ${GREEN}RUNNING${NC}"
    echo "   Capabilities:"
    echo "      - Health monitoring (LLM + Redis)"
    echo "      - Check interval: 30 seconds"
    echo "   Recent logs:"
    docker logs q-mem-sync --tail 3 2>&1 | sed 's/^/      /'
else
    echo -e "   Status:    ${RED}OFFLINE${NC}"
fi
echo ""

# Weaviate (if running)
if docker ps --filter "name=sanctum_memory" --filter "status=running" | grep -q sanctum_memory; then
    echo "${YELLOW}4. Vector Database (Weaviate)${NC}"
    echo "   Container: sanctum_memory"
    echo "   Endpoint:  http://localhost:8081"
    echo -e "   Status:    ${GREEN}ONLINE${NC}"
    echo "   Capabilities:"
    echo "      - Vector storage"
    echo "      - Semantic search"
    echo ""
fi

# Gemini Bridge (if running)
if docker ps --filter "name=sanctum_gemini_bridge" --filter "status=running" | grep -q sanctum_gemini_bridge; then
    echo "${YELLOW}5. Gemini Bridge${NC}"
    echo "   Container: sanctum_gemini_bridge"
    echo -e "   Status:    ${GREEN}ONLINE${NC}"
    echo "   Capabilities:"
    echo "      - Gemini API integration"
    echo ""
fi

# Build Status (if building)
echo "${BLUE}[BUILD STATUS]${NC}"
echo "------------------------------------------------------------------------"
if ps aux | grep -q "[d]ocker compose build"; then
    echo -e "${YELLOW}Build in progress...${NC}"
    if [ -f /tmp/claude/-home-nav/tasks/bb6105f.output ]; then
        PROGRESS=$(tail -1 /tmp/claude/-home-nav/tasks/bb6105f.output | grep -oP '\[\s*\K[0-9]+(?=%\])')
        if [ ! -z "$PROGRESS" ]; then
            echo "Progress: $PROGRESS%"
            echo -n "["
            for i in $(seq 1 50); do
                if [ $i -le $((PROGRESS/2)) ]; then
                    echo -n "="
                else
                    echo -n " "
                fi
            done
            echo "] $PROGRESS%"
        fi
    fi
else
    echo -e "${GREEN}No active builds${NC}"
fi
echo ""

echo "========================================================================"
echo "                    Quick Test Commands"
echo "========================================================================"
echo ""
echo "Test LLM Inference:"
echo "  curl -X POST http://localhost:8082/v1/completions \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"prompt\": \"Hello, world!\", \"max_tokens\": 50}'"
echo ""
echo "Test Redis:"
echo "  docker exec genesis-q-mem redis-cli ping"
echo ""
echo "Monitor GPU:"
echo "  watch -n 1 nvidia-smi"
echo ""
echo "View Orchestrator Logs:"
echo "  docker logs -f q-mem-sync"
echo ""
echo "========================================================================"
