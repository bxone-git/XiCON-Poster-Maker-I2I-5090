#!/bin/bash
# NO set -e: handler MUST start for RunPod to see worker as "ready"

echo "=========================================="
echo "Container startup - $(date)"
echo "=========================================="

# System diagnostics
echo "--- System Info ---"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null || echo "nvidia-smi: FAILED"
echo "CUDA version: $(nvcc --version 2>/dev/null | grep release | awk '{print $6}' || echo 'unknown')"
echo "Python: $(python --version 2>&1)"
df -h / 2>/dev/null | tail -1
echo ""

# Network Volume Setup
NETVOLUME="/runpod-volume"
COMFYUI_READY=false

echo "--- Network Volume ---"
echo "Checking $NETVOLUME..."
ls -la /runpod-volume/ 2>/dev/null | head -5 || echo "Cannot list $NETVOLUME"

if [ ! -d "$NETVOLUME" ]; then
    echo "WARNING: Network Volume not mounted at $NETVOLUME"
    echo "Available mounts:"
    mount | grep -E "nfs|cifs|fuse" || echo "  (no network mounts found)"
    echo "ls /:"
    ls / | tr '\n' ' '
    echo ""
else
    echo "Network Volume: OK"

    # Check models
    echo ""
    echo "--- Model Check ---"
    MODELS_OK=true

    for model in \
        "$NETVOLUME/models/diffusion_models/flux-2-klein-base-9b-fp8.safetensors" \
        "$NETVOLUME/models/text_encoders/qwen_3_8b_fp8mixed.safetensors" \
        "$NETVOLUME/models/vae/flux2-vae.safetensors"; do
        if [ -f "$model" ]; then
            SIZE=$(du -h "$model" 2>/dev/null | cut -f1)
            echo "  [OK] $(basename $model) ($SIZE)"
        else
            echo "  [MISSING] $model"
            MODELS_OK=false
        fi
    done

    if [ "$MODELS_OK" = true ]; then
        # Create symlinks
        echo ""
        echo "Creating symlinks..."
        rm -rf /ComfyUI/models/diffusion_models
        rm -rf /ComfyUI/models/text_encoders
        rm -rf /ComfyUI/models/vae

        ln -sf $NETVOLUME/models/diffusion_models /ComfyUI/models/diffusion_models
        ln -sf $NETVOLUME/models/text_encoders /ComfyUI/models/text_encoders
        ln -sf $NETVOLUME/models/vae /ComfyUI/models/vae
        echo "Symlinks created!"

        # GPU Detection and SageAttention
        GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo "Unknown")
        echo ""
        echo "Detected GPU: $GPU_NAME"

        SAGE_FLAG=""
        if echo "$GPU_NAME" | grep -qi "5090\|5080\|blackwell"; then
            echo "SageAttention: ENABLED (Blackwell)"
            export SAGEATTENTION_ENABLED=1
            SAGE_FLAG="--use-sage-attention"
        elif echo "$GPU_NAME" | grep -qi "4090\|4080\|L40\|6000.*Ada\|ada"; then
            echo "SageAttention: ENABLED (Ada)"
            export SAGEATTENTION_ENABLED=1
            SAGE_FLAG="--use-sage-attention"
        else
            echo "SageAttention: DISABLED (unknown GPU: $GPU_NAME)"
        fi

        # Start ComfyUI
        echo ""
        echo "Starting ComfyUI ${SAGE_FLAG:+with SageAttention}..."
        python /ComfyUI/main.py --listen $SAGE_FLAG &
        COMFYUI_PID=$!

        # Wait for ComfyUI (max 300 seconds for model loading)
        echo "Waiting for ComfyUI (PID: $COMFYUI_PID)..."
        max_wait=300
        wait_count=0
        while [ $wait_count -lt $max_wait ]; do
            if curl -s http://127.0.0.1:8188/ > /dev/null 2>&1; then
                echo "ComfyUI is ready! (took ${wait_count}s)"
                COMFYUI_READY=true
                break
            fi
            # Check if ComfyUI process is still alive
            if ! kill -0 $COMFYUI_PID 2>/dev/null; then
                echo "WARNING: ComfyUI process died!"
                break
            fi
            sleep 2
            wait_count=$((wait_count + 2))
        done

        if [ "$COMFYUI_READY" = false ]; then
            echo "WARNING: ComfyUI did not become ready after ${max_wait}s"
        fi
    else
        echo "WARNING: Models missing, skipping ComfyUI startup"
    fi
fi

echo ""
echo "=========================================="
echo "Starting handler (ComfyUI ready: $COMFYUI_READY) - $(date)"
echo "=========================================="

# ALWAYS start the handler so RunPod sees the worker as "ready"
exec python handler.py
