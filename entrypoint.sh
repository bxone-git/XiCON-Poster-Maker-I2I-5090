#!/bin/bash
# PHASE 1: Ultra-minimal handler registration test
# No CUDA, no ComfyUI, no models - just runpod handler
echo "=========================================="
echo "HANDLER REGISTRATION TEST - $(date)"
echo "=========================================="
echo "Python: $(python --version 2>&1)"
echo "RunPod: $(pip show runpod 2>/dev/null | grep Version)"
echo ""

# Inline minimal handler - no external dependencies
exec python -c "
import runpod
import json

print('Handler starting...')

def handler(job):
    job_input = job.get('input', {})
    print(f'Job received: {json.dumps(job_input)[:200]}')
    return {
        'status': 'ok',
        'message': 'XiCON Poster Maker handler registration successful',
        'received_keys': list(job_input.keys())
    }

print('Calling runpod.serverless.start()...')
runpod.serverless.start({'handler': handler})
"
