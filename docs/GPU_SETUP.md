# GPU Setup Guide

This guide covers GPU acceleration for LLM inference, supporting NVIDIA GPUs and Apple Silicon.

## Supported Hardware

| Platform | Backend | Status |
|----------|---------|--------|
| NVIDIA GPU | CUDA | ✅ Fully Supported |
| Apple Silicon (M1/M2/M3/M4) | Metal | ✅ Fully Supported |
| AMD GPU | ROCm | ⚠️ Experimental |
| CPU Only | - | ✅ Supported |

## NVIDIA GPU Setup

### Prerequisites

1. **NVIDIA Driver** - Latest driver for your GPU
2. **NVIDIA Container Toolkit** - For Docker GPU access

### Install NVIDIA Container Toolkit

**Ubuntu/Debian:**
```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

**Other distributions:** See [NVIDIA Container Toolkit docs](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

### Verify GPU Detection

```bash
# Check NVIDIA driver
nvidia-smi

# Run GPU detection script
./scripts/detect-gpu.sh
```

### Start with GPU Support

```bash
# GPU overlay is automatically applied when NVIDIA GPU is detected
./scripts/start.sh

# Or manually:
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

### Multi-GPU Setup

For systems with multiple GPUs, you can specify which GPU(s) to use:

```bash
# Use specific GPU (GPU 0)
CUDA_VISIBLE_DEVICES=0 docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d

# Use multiple GPUs (GPU 0 and 1)
CUDA_VISIBLE_DEVICES=0,1 docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

### GPU Memory Management

Ollama automatically manages GPU memory. Control it via environment variables:

```bash
# In .env file
OLLAMA_GPU_LAYERS=35        # Number of layers to offload to GPU
OLLAMA_NUM_PARALLEL=4       # Max parallel requests
```

## Apple Silicon Setup

Apple Silicon (M1/M2/M3/M4) GPUs are automatically detected and used via Metal.

### Requirements

- Apple Silicon Mac (M1/M2/M3/M4 series)
- macOS 12.3 or later
- Docker Desktop for Mac

### No Additional Setup Needed

Docker Desktop on Apple Silicon automatically passes GPU access to containers:

```bash
# Just start normally - GPU is auto-detected
./scripts/start.sh
```

### Unified Memory

Apple Silicon uses unified memory architecture - the GPU shares system RAM:

| Chip | Max Memory | Recommended Models |
|------|------------|-------------------|
| M1/M2 8GB | 8GB | llama3.2:1b, phi3:mini |
| M1/M2 16GB | 16GB | llama3.2:3b, mistral:7b |
| M1/M2 24GB | 24GB | llama3.1:8b |
| M2 Ultra 64GB | 64GB | llama3.1:13b |
| M2 Ultra 96GB | 96GB | llama3.1:70b-q4 |
| M3 Max 128GB | 128GB | llama3.1:70b |

## AMD GPU (Experimental)

AMD GPU support via ROCm is experimental. See [Ollama Linux docs](https://github.com/ollama/ollama/blob/main/docs/linux.md#amd) for setup instructions.

## Troubleshooting

### NVIDIA: Container Toolkit Not Found

```
Error: could not select device driver "nvidia"
```

**Solution:** Install NVIDIA Container Toolkit (see above).

### NVIDIA: Out of Memory

```
CUDA out of memory
```

**Solutions:**
1. Use a smaller model (e.g., llama3.2:1b instead of llama3.1:8b)
2. Reduce GPU layers: `OLLAMA_GPU_LAYERS=20`
3. Use quantized models (4-bit, 8-bit)

### Apple Silicon: Slow Inference

**Solutions:**
1. Ensure Docker Desktop is updated
2. Check available memory: Activity Monitor → Memory
3. Close other memory-intensive apps

### No GPU Detected

Run the detection script for diagnostics:

```bash
./scripts/detect-gpu.sh
```

## Performance Tips

1. **Use quantized models** for limited VRAM (e.g., llama3.1:70b-q4 instead of llama3.1:70b)
2. **Batch requests** - Ollama supports parallel inference
3. **Pre-load models** - Keep models in memory for faster response

```bash
# Keep model loaded for 30 minutes after last use
OLLAMA_KEEP_ALIVE=30m

# Always keep model loaded
OLLAMA_KEEP_ALIVE=-1
```