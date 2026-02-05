# XiCON Poster Maker I2I - RTX 5090

Flux 2 Klein 9B 기반 2단계 이미지-투-이미지 파이프라인

## Features

- **Stage 1**: 입력 이미지 → 매거진 커버 + 타이포그래피
- **Stage 2**: 매거진 커버 → 투명 봉투 패키징
- **RTX 5090 최적화**: CUDA 12.8 + SageAttention2++
- **Network Volume**: Klein Gated 모델 인증 문제 해결

## Requirements

- RunPod Account
- RTX 5090 GPU (BLACKWELL_24)
- Network Volume "XiCON" (최소 20GB)

## Quick Start

### 1. Network Volume 설정 (최초 1회)

```bash
# RunPod Pod에서 실행
./setup_netvolume.sh

# Klein 모델은 HuggingFace 인증 필요
huggingface-cli login
```

### 2. Docker 빌드 & 푸시

```bash
docker build --platform linux/amd64 -t blendx/xicon-poster-maker-i2i:5090 .
docker push blendx/xicon-poster-maker-i2i:5090
```

### 3. RunPod Serverless 배포

1. RunPod Console → Serverless → New Endpoint
2. Custom Image: `blendx/xicon-poster-maker-i2i:5090`
3. GPU: RTX 5090 (BLACKWELL_24)
4. Network Volume: XiCON → `/runpod-volume`

## API Usage

```json
{
  "input": {
    "image_url": "https://example.com/portrait.jpg",
    "width": 1024,
    "height": 1472,
    "steps": 20,
    "cfg": 5,
    "seed": 42,
    "output_stage": "final"
  }
}
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| image_url | string | required | 입력 이미지 URL |
| image_base64 | string | - | Base64 이미지 (대안) |
| width | int | 1024 | 출력 너비 |
| height | int | 1472 | 출력 높이 |
| steps | int | 20 | 샘플링 스텝 |
| cfg | float | 5 | CFG Scale |
| seed | int | 0 | 시드 (0=랜덤) |
| output_stage | string | final | stage1, final, both |

## License

MIT License
