#!/bin/bash
# Q-Mem Stack Validation

echo "Q-Mem Stack Validation"
echo "======================"

ERRORS=0

# GPU
echo -n "[1/5] GPU access: "
if nvidia-smi &> /dev/null; then
    echo "PASS"
else
    echo "FAIL"
    ((ERRORS++))
fi

# Docker
echo -n "[2/5] Docker: "
if docker --version &> /dev/null; then
    echo "PASS"
else
    echo "FAIL"
    ((ERRORS++))
fi

# Docker Compose
echo -n "[3/5] Docker Compose: "
if docker compose version &> /dev/null; then
    echo "PASS"
else
    echo "FAIL"
    ((ERRORS++))
fi

# Model file
echo -n "[4/5] Phi-2 model: "
if [ -f "models/phi-2.Q4_K_M.gguf" ]; then
    SIZE=$(du -h models/phi-2.Q4_K_M.gguf | cut -f1)
    echo "PASS ($SIZE)"
else
    echo "FAIL (missing)"
    ((ERRORS++))
fi

# Config files
echo -n "[5/5] Config files: "
if [ -f "docker-compose.yml" ] && [ -f "Dockerfile" ] && [ -f "sync_orchestrator.py" ]; then
    echo "PASS"
else
    echo "FAIL"
    ((ERRORS++))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "All checks passed! Ready to deploy."
    echo "Run: ./deploy.sh"
else
    echo "$ERRORS check(s) failed. Fix issues before deploying."
fi
