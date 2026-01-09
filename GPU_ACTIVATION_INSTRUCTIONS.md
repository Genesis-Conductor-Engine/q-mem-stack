# GPU ACTIVATION INSTRUCTIONS
**Genesis Q-Mem Stack - Full GPU Offload Configuration**

---

## CURRENT STATUS
- Stack running in **CPU mode** (431MB VRAM, `-ngl 0`)
- Host missing `nvidia-container-toolkit`
- Configuration updated for GPU support (`-ngl 33`, full offload)

---

## STEP 1: INSTALL NVIDIA CONTAINER TOOLKIT

Run the provided installation script as root:

```bash
cd /home/nav/q-mem-stack
sudo bash install_nvidia_container_toolkit.sh
```

### What this script does:
1. ✓ Verifies NVIDIA driver with `nvidia-smi`
2. ✓ Adds NVIDIA Container Toolkit GPG key
3. ✓ Adds official NVIDIA repository to apt sources
4. ✓ Updates package index
5. ✓ Installs `nvidia-container-toolkit`
6. ✓ Configures Docker daemon with `nvidia-ctk runtime configure`
7. ✓ Restarts Docker daemon
8. ✓ Runs verification test

**Expected output:** GPU info from `nvidia-smi` visible in container

---

## STEP 2: VERIFY CONFIGURATION CHANGES

The following changes have been applied to `docker-compose.yml`:

### Before (CPU Mode):
```yaml
command: ["-m", "/models/phi-2.Q4_K_M.gguf", "-c", "2048", "-ngl", "0", ...]
# No GPU deployment section
```

### After (GPU Mode):
```yaml
command: ["-m", "/models/phi-2.Q4_K_M.gguf", "-c", "2048", "-ngl", "33", ...]
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

**Key changes:**
- `-ngl 33` → Full GPU offload (all 32 Phi-2 layers + 1 output layer)
- `deploy.resources.reservations.devices` → Docker Compose v2 GPU syntax
- `capabilities: [gpu]` → Enables CUDA/GPU access

---

## STEP 3: RESTART WITH GPU SUPPORT

Execute the GPU restart sequence:

```bash
cd /home/nav/q-mem-stack
bash gpu_restart.sh
```

### Manual restart (alternative):
```bash
cd /home/nav/q-mem-stack
docker compose down
docker compose up -d --force-recreate
```

---

## STEP 4: VERIFY GPU ACTIVATION

### Check container GPU access:
```bash
docker exec genesis-llm-phi2 nvidia-smi
```

**Expected output:** GPU info (GTX 1650, 4GB VRAM, utilization stats)

### Check llama.cpp GPU offload:
```bash
docker logs genesis-llm-phi2 | grep -i 'ngl\|gpu\|cuda'
```

**Expected output:**
```
llm_load_tensors: using CUDA for GPU acceleration
llm_load_tensors: offloading 33 layers to GPU
llm_load_tensors: VRAM used: 2500 MB
```

### Test inference:
```bash
curl -s http://localhost:8082/health
```

**Expected:** `{"status":"ok"}`

### Monitor VRAM usage during inference:
```bash
watch -n 1 nvidia-smi
```

**Expected VRAM:** ~2.5GB allocated (up from 431MB in CPU mode)

---

## TROUBLESHOOTING

### Issue: "could not select device driver nvidia"
**Fix:** Ensure nvidia-container-toolkit installed and Docker daemon restarted
```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Issue: Container starts but no GPU detected
**Fix:** Verify NVIDIA driver on host
```bash
nvidia-smi
```

### Issue: VRAM still shows 431MB
**Fix:** Ensure `-ngl 33` in docker-compose.yml and containers recreated
```bash
docker compose down
docker compose up -d --force-recreate
```

### Issue: "CUDA error: out of memory"
**Fix:** GTX 1650 has 4GB VRAM, Phi-2 Q4_K_M uses ~2.5GB. Close other GPU applications.

---

## PERFORMANCE METRICS

### Before (CPU Mode):
- Inference: ~0.79 tokens/sec
- VRAM: 431MB (minimal allocation)
- Offloaded layers: 0/33

### After (GPU Mode - Expected):
- Inference: ~28.5 tokens/sec (36x faster)
- VRAM: ~2.5GB (full model offload)
- Offloaded layers: 33/33 (100%)

---

## FILES CREATED

1. `install_nvidia_container_toolkit.sh` - Toolkit installation script
2. `gpu_restart.sh` - Container restart sequence
3. `docker-compose.yml` - **UPDATED** with GPU configuration
4. `GPU_ACTIVATION_INSTRUCTIONS.md` - This file

---

## EXECUTION CHECKLIST

- [ ] Run `sudo bash install_nvidia_container_toolkit.sh`
- [ ] Verify Docker daemon restarted successfully
- [ ] Run `bash gpu_restart.sh`
- [ ] Verify `docker exec genesis-llm-phi2 nvidia-smi` shows GPU
- [ ] Check logs: `docker logs genesis-llm-phi2 | grep ngl`
- [ ] Confirm VRAM usage: `nvidia-smi` shows ~2.5GB allocated
- [ ] Test inference endpoint: `curl http://localhost:8082/health`

---

**Status after completion:** GPU-accelerated Phi-2 inference ready at `localhost:8082`
