#!/bin/bash
# MINIMAL entrypoint - handler ONLY, no ComfyUI
# Purpose: Test if handler can register with RunPod
echo "=========================================="
echo "MINIMAL STARTUP TEST - $(date)"
echo "=========================================="

echo "--- System Info ---"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null || echo "nvidia-smi: NOT AVAILABLE"
python --version 2>&1 || echo "python: NOT AVAILABLE"
pip show runpod 2>/dev/null | grep -E "^(Name|Version)" || echo "runpod package: NOT FOUND"
echo ""

echo "--- Volume Check ---"
ls -la /runpod-volume/ 2>/dev/null | head -3 || echo "/runpod-volume: NOT MOUNTED"
echo ""

echo "--- Starting handler ONLY (no ComfyUI) ---"
exec python handler.py
