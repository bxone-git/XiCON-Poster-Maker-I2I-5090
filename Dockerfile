# PHASE 1: Ultra-minimal handler registration test
# Proves RunPod handler can register and become "ready"
# Once verified, will restore full ComfyUI + CUDA image

FROM python:3.10-slim

ENV PYTHONUNBUFFERED=1

RUN pip install --no-cache-dir runpod

WORKDIR /

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
