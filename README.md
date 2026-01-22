# Q-Mem Stack - GPU-Accelerated LLM Inference

A production-ready GPU-accelerated quantum memory stack for LLM inference with Redis caching and health monitoring.

## Quick Start

```bash
# 1. Install GPU support
sudo bash install_nvidia_container_toolkit.sh

# 2. Download model
mkdir -p models
wget https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf -O models/phi-2.Q4_K_M.gguf

# 3. Deploy
bash deploy.sh

# 4. Verify
curl http://localhost:8082/health
```

## Architecture

- **LLM Server** (port 8082): GPU-accelerated Phi-2 inference via llama.cpp
- **Redis Cache** (port 6379): Vector/memory caching with LRU eviction
- **Health Orchestrator**: Continuous monitoring of all services and GPU stats

## Services

| Service | Container | Port | Purpose |
|---------|-----------|------|---------|
| LLM Inference | genesis-llm-phi2 | 8082 | Phi-2 model serving with full GPU offload |
| Redis Cache | genesis-q-mem | 6379 | Memory caching with 1.5GB limit |
| Orchestrator | q-mem-sync | - | Health monitoring and status reporting |

## Requirements

- **GPU**: NVIDIA GPU with 4GB+ VRAM (tested on GTX 1650)
- **RAM**: 16GB minimum
- **Storage**: 32GB minimum
- **OS**: Ubuntu 22.04 or compatible
- **Software**: Docker 20.10+, NVIDIA drivers, nvidia-container-toolkit

## Performance

| Mode | Speed | VRAM | Layers Offloaded |
|------|-------|------|------------------|
| CPU | 0.79 tok/s | 431MB | 0/33 |
| GPU | 28.5 tok/s | 2.5GB | 33/33 |

*36x speedup with full GPU acceleration*

## Management Commands

```bash
# Status check
./status.sh

# Full dashboard
./status_dashboard.sh

# Monitor GPU
watch -n 1 nvidia-smi

# View logs
docker compose logs -f

# Restart with GPU
bash gpu_restart.sh

# Validation
bash validate.sh
```

## API Examples

### Text Completion
```bash
curl -X POST http://localhost:8082/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain quantum computing in simple terms:",
    "max_tokens": 100,
    "temperature": 0.7
  }'
```

### Health Check
```bash
curl http://localhost:8082/health
# Returns: {"status":"ok"}
```

### Redis Operations
```bash
# Ping Redis
docker exec genesis-q-mem redis-cli ping

# Check memory
docker exec genesis-q-mem redis-cli INFO memory

# Get orchestrator status
docker exec genesis-q-mem redis-cli GET q-mem:status
```

## Deployment for Spark

See **[SPARK_DEPLOYMENT_PROMPT.md](SPARK_DEPLOYMENT_PROMPT.md)** for a comprehensive deployment prompt that includes:
- Complete architecture documentation
- All service specifications and configurations
- Step-by-step deployment procedures
- Troubleshooting guides
- API documentation
- Extension points

This prompt is designed to be provided to Spark (or any AI deployment system) for complete automated deployment.

## Documentation

- **[GPU_ACTIVATION_INSTRUCTIONS.md](GPU_ACTIVATION_INSTRUCTIONS.md)**: GPU setup and activation guide
- **[SPARK_DEPLOYMENT_PROMPT.md](SPARK_DEPLOYMENT_PROMPT.md)**: Complete deployment prompt for AI systems
- **[deploy.sh](deploy.sh)**: Automated deployment script
- **[validate.sh](validate.sh)**: Pre-deployment validation

## Troubleshooting

### GPU Not Detected
```bash
# Verify NVIDIA driver
nvidia-smi

# Install container toolkit
sudo bash install_nvidia_container_toolkit.sh

# Restart Docker
sudo systemctl restart docker

# Recreate containers
docker compose down && docker compose up -d --force-recreate
```

### Minimal VRAM Usage
```bash
# Check GPU offload setting
grep "ngl" docker-compose.yml
# Should show: "-ngl", "33"

# Check logs for GPU initialization
docker logs genesis-llm-phi2 | grep -i "gpu\|cuda\|ngl"
```

### Build Failures
```bash
# Monitor build progress
bash monitor_build.sh

# Check available memory
free -h

# Reduce parallelism if swap thrashing (edit Dockerfile.llama-cuda)
# Change: cmake --build build --config Release -j4
# To: cmake --build build --config Release -j2
```

## License

See repository license file.

## Contributing

Issues and pull requests welcome at https://github.com/Genesis-Conductor-Engine/q-mem-stack
