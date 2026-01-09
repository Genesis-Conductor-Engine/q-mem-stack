#!/bin/bash
# Real-time build monitor with progress tracking

BUILD_LOG="/tmp/claude/-home-nav/tasks/ba3e221.output"

echo "========================================================================"
echo "           CUDA BUILD MONITOR - Optimized (-j2 parallelism)"
echo "========================================================================"
echo ""

while true; do
    clear
    echo "========================================================================"
    echo "           CUDA BUILD MONITOR - Optimized (-j2 parallelism)"
    echo "========================================================================"
    echo ""

    # Get current progress
    if [ -f "$BUILD_LOG" ]; then
        PROGRESS=$(tail -20 "$BUILD_LOG" | grep -oP '\[\s*\K[0-9]+(?=%\])' | tail -1)
        CURRENT_STEP=$(tail -5 "$BUILD_LOG" | grep "Building" | tail -1 | sed 's/.*Building /Building /')

        echo "📊 BUILD PROGRESS"
        echo "------------------------------------------------------------------------"
        if [ ! -z "$PROGRESS" ]; then
            echo -n "Progress: [$PROGRESS%] "
            # Progress bar
            printf "["
            for i in $(seq 1 50); do
                if [ $i -le $((PROGRESS/2)) ]; then
                    printf "█"
                else
                    printf "░"
                fi
            done
            printf "] $PROGRESS%%\n"

            # Estimated time
            if [ $PROGRESS -gt 0 ]; then
                # Rough estimate based on optimized build
                REMAINING_MIN=$(((100 - PROGRESS) * 2))
                echo "Estimated remaining: ~$REMAINING_MIN minutes"
            fi
        else
            echo "Initializing build..."
        fi

        echo ""
        echo "Current step:"
        echo "$CURRENT_STEP"
        echo ""
    fi

    # System resources
    echo "💻 SYSTEM RESOURCES"
    echo "------------------------------------------------------------------------"
    free -h | awk 'NR==2 {printf "RAM:  %s used / %s total (%s available)\n", $3, $2, $7}'
    free -h | awk 'NR==3 {printf "SWAP: %s used / %s total\n", $3, $2}'
    echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"

    # CUDA compiler processes
    CICC_COUNT=$(ps aux | grep cicc | grep -v grep | wc -l)
    echo "Active CUDA compilers: $CICC_COUNT"

    # GPU status
    if command -v nvidia-smi &> /dev/null; then
        echo ""
        nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader | \
            awk -F', ' '{printf "GPU: %s utilization, VRAM: %s / %s\n", $1, $2, $3}'
    fi

    echo ""
    echo "------------------------------------------------------------------------"
    echo "Build log: $BUILD_LOG"
    echo "Press Ctrl+C to exit monitor (build continues in background)"
    echo "========================================================================"

    # Check if build completed
    if ! ps aux | grep -q "[d]ocker compose build"; then
        echo ""
        echo "✅ BUILD COMPLETED OR STOPPED"
        echo ""
        echo "Check status with: docker images | grep q-mem-stack"
        break
    fi

    sleep 5
done
