# CLAUDE.md

XiCON Poster Maker I2I - RTX 5090 Serverless Package

## Project Overview

XiCON Poster Maker I2I - Flux 2 Klein 9B 기반 2단계 I2I 파이프라인
- Stage 1: 매거진 커버 + 타이포그래피 오버레이
- Stage 2: 투명 봉투 패키징
- **Ada (RTX 4090/L40/L40S) + Blackwell (RTX 5090) 지원**
- **Network Volume 방식** (Klein Gated 모델 인증 해결)

## Key Specifications

| Component | Version |
|-----------|---------|
| Base Image | nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04 |
| PyTorch | 2.8+ (cu128) |
| CUDA | **12.8 (Required)** |
| Target GPU | Ada (SM89) + Blackwell (SM120) |
| SageAttention | 2.2+ (auto-detected per GPU) |
| Docker Tag | `blendx/xicon-poster-maker-i2i:5090` |

## Build & Deploy Commands

```bash
# Build Docker image (must use linux/amd64 for RunPod)
docker build --platform linux/amd64 -t blendx/xicon-poster-maker-i2i:5090 .

# Push to Docker Hub
docker push blendx/xicon-poster-maker-i2i:5090

# RunPod Serverless에서 Custom Image로 배포
# GPU: RTX 5090 (BLACKWELL_24)
# Network Volume: XiCON (/runpod-volume)
```

## File Structure

```
├── .runpod/
│   ├── hub.json           # RunPod Hub 설정
│   └── tests.json         # 테스트 설정
├── Dockerfile             # CUDA 12.8 + PyTorch cu128 + SageAttention 2.2+
├── entrypoint.sh          # Network Volume symlink + SageAttention2++
├── handler.py             # RunPod handler (노드 ID 매핑)
├── setup_netvolume.sh     # Network Volume 모델 다운로드
├── config.ini             # ComfyUI Manager 설정
├── XiCON_Poster_Maker_I2I_api.json  # ComfyUI workflow
├── CLAUDE.md              # AI 개발 가이드
├── README.md              # 사용자 문서
└── .gitignore             # Git 제외 파일
```

## handler.py Node ID Mapping

```python
# LoadImage
prompt["2"]["inputs"]["image"] = image_path

# Stage 1 Parameters (User-Settable)
prompt["11:74"]["inputs"]["text"] = prompt_stage1      # Positive prompt
prompt["11:62"]["inputs"]["steps"] = steps             # Steps
prompt["11:63"]["inputs"]["cfg"] = cfg                 # CFG
prompt["11:73"]["inputs"]["noise_seed"] = seed         # Seed
prompt["11:66"]["inputs"]["width"] = width             # Width
prompt["11:66"]["inputs"]["height"] = height           # Height

# Stage 2 Parameters
prompt["15:74"]["inputs"]["text"] = prompt_stage2      # Positive prompt
prompt["15:62"]["inputs"]["steps"] = steps             # Steps
prompt["15:63"]["inputs"]["cfg"] = cfg                 # CFG
prompt["15:73"]["inputs"]["noise_seed"] = seed         # Seed
# Note: Stage 2 width/height는 GetImageSize 노드(15:81)를 통해
# Stage 1 출력에서 자동 상속됨. 직접 설정 불가.

# Output nodes
# "12" = Stage 1 SaveImage
# "16" = Stage 2 (Final) SaveImage
```

## Network Volume Structure (XiCON)

```
/runpod-volume/
└── models/
    ├── diffusion_models/
    │   └── flux-2-klein-base-9b-fp8.safetensors  (~9GB, Gated)
    ├── text_encoders/
    │   └── qwen_3_8b_fp8mixed.safetensors        (~8GB)
    └── vae/
        └── flux2-vae.safetensors                 (~300MB)
```

**Total: ~17.3GB**

## API Input Format

```json
{
  "input": {
    "image_url": "https://example.com/image.jpg",
    "prompt_stage1": "Magazine cover prompt...",
    "prompt_stage2": "Envelope packaging prompt...",
    "width": 1024,
    "height": 1472,
    "steps": 20,
    "cfg": 5,
    "seed": 0,
    "output_stage": "final"
  }
}
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Network Volume not found | 볼륨 미연결 | RunPod에서 XiCON 볼륨 연결 |
| Klein model not found | 모델 미다운로드 | `setup_netvolume.sh` 실행 |
| CUDA error: no kernel image | 지원 안 되는 GPU | Ada(SM89) 또는 Blackwell(SM120) GPU 필요 |
| SageAttention 오류 | 버전 불일치 | sageattention>=2.2.0 확인 |

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 5090-v1.0.0 | 2026-02-06 | RTX 5090 + CUDA 12.8 + Network Volume 초기 릴리스 |
