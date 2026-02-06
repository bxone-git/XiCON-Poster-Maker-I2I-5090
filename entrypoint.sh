#!/bin/bash
set -e

echo "=========================================="
echo "Container startup (RTX 5090 + SageAttention2++) - $(date)"
echo "=========================================="

# Network Volume Setup
NETVOLUME="/runpod-volume"

echo "Checking Network Volume at $NETVOLUME..."
if [ ! -d "$NETVOLUME" ]; then
    echo "ERROR: Network Volume not mounted at $NETVOLUME"
    exit 1
fi

# Check models exist
if [ ! -f "$NETVOLUME/models/diffusion_models/flux-2-klein-base-9b-fp8.safetensors" ]; then
    echo "ERROR: Klein model not found. Run setup_netvolume.sh first."
    exit 1
fi

echo "Creating symlinks..."
rm -rf /ComfyUI/models/diffusion_models
rm -rf /ComfyUI/models/text_encoders
rm -rf /ComfyUI/models/vae

ln -sf $NETVOLUME/models/diffusion_models /ComfyUI/models/diffusion_models
ln -sf $NETVOLUME/models/text_encoders /ComfyUI/models/text_encoders
ln -sf $NETVOLUME/models/vae /ComfyUI/models/vae

echo "Symlinks created!"

# Model verification
echo "Verifying models..."
check_model() {
    if [ -f "$1" ]; then
        echo "  [OK] $(basename $1)"
    else
        echo "  [MISSING] $1"
        return 1
    fi
}

check_model "$NETVOLUME/models/diffusion_models/flux-2-klein-base-9b-fp8.safetensors"
check_model "$NETVOLUME/models/text_encoders/qwen_3_8b_fp8mixed.safetensors"
check_model "$NETVOLUME/models/vae/flux2-vae.safetensors"

# SageAttention2++ 활성화
export SAGEATTENTION_ENABLED=1
echo "SageAttention: ENABLED (RTX 5090 SM120 - SageAttention2++ kernels)"

# Start ComfyUI
echo "Starting ComfyUI with SageAttention2++..."
python /ComfyUI/main.py --listen --use-sage-attention &

# Wait for ComfyUI
echo "Waiting for ComfyUI..."
max_wait=180
wait_count=0
while [ $wait_count -lt $max_wait ]; do
    if curl -s http://127.0.0.1:8188/ > /dev/null 2>&1; then
        echo "ComfyUI is ready!"
        break
    fi
    sleep 2
    wait_count=$((wait_count + 2))
done

if [ $wait_count -ge $max_wait ]; then
    echo "Error: ComfyUI failed to start"
    exit 1
fi

echo "Starting handler..."
exec python handler.py
