# Model List & Recommendations

This document lists recommended models and provides guidance on choosing the right model for your hardware.

## Quick Reference

| Model | Parameters | Size | RAM | VRAM | Use Case |
|-------|------------|------|-----|------|----------|
| llama3.2:1b | 1B | ~2GB | 4GB | 2GB | Fast, simple tasks |
| llama3.2:3b | 3B | ~4GB | 8GB | 4GB | General purpose |
| phi3:mini | 3.8B | ~3GB | 8GB | 4GB | Reasoning, code |
| mistral:7b | 7B | ~8GB | 16GB | 6GB | High quality chat |
| llama3.1:8b | 8B | ~10GB | 16GB | 8GB | Balanced performance |
| codellama:7b | 7B | ~8GB | 16GB | 6GB | Code generation |
| llama3.1:13b | 13B | ~15GB | 32GB | 12GB | Complex reasoning |
| llama3.1:70b | 70B | ~45GB | 64GB | 48GB | Best quality |

## Model Families

### Meta Llama 3.x

**Llama 3.2 (Latest, Efficient):**
- `llama3.2:1b` - Ultra-fast, good for simple tasks
- `llama3.2:3b` - Best balance of speed and quality

**Llama 3.1 (Powerful):**
- `llama3.1:8b` - Great for most tasks
- `llama3.1:13b` - Better reasoning
- `llama3.1:70b` - Near-GPT-4 quality

### Mistral AI

- `mistral:7b` - Excellent quality/size ratio
- `mixtral:8x7b` - Mixture of Experts, high quality

### Microsoft Phi-3

- `phi3:mini` - Small but capable, good for reasoning
- `phi3:medium` - Better quality, still efficient

### Code Models

- `codellama:7b` - Code generation and explanation
- `codellama:13b` - Better code understanding
- `deepseek-coder:6.7b` - Specialized for code

### Embedding Models (RAG)

- `nomic-embed-text` - General purpose embeddings
- `mxbai-embed-large` - High quality embeddings
- `all-minilm` - Lightweight embeddings

## Hardware Recommendations

### By RAM

| RAM | Recommended Models |
|-----|-------------------|
| 8GB | llama3.2:1b, phi3:mini, gemma2:2b |
| 16GB | llama3.2:3b, mistral:7b, llama3.1:8b |
| 32GB | llama3.1:13b, codellama:13b, qwen2.5:14b |
| 64GB | llama3.1:70b-q4, command-r:35b |
| 128GB | llama3.1:70b, mixtral:8x7b |

### By GPU VRAM

| VRAM | Recommended Models |
|------|-------------------|
| 4GB | llama3.2:1b, phi3:mini |
| 6GB | llama3.2:3b |
| 8GB | mistral:7b, llama3.1:8b |
| 12GB | llama3.1:13b (quantized) |
| 16GB | llama3.1:13b, codellama:13b |
| 24GB | llama3.1:70b-q4 |
| 48GB | llama3.1:70b |

### Apple Silicon

| Chip | Recommended Models |
|------|-------------------|
| M1/M2 8GB | llama3.2:1b, phi3:mini |
| M1/M2 16GB | llama3.2:3b, mistral:7b |
| M1/M2 24GB | llama3.1:8b |
| M2 Ultra 64GB | llama3.1:13b, qwen2.5:14b |
| M2 Ultra 96GB | llama3.1:70b-q4 |
| M3 Max 128GB | llama3.1:70b |

## Model Variants

### Quantization

Models can be quantized to reduce memory usage:

| Quantization | Size Reduction | Quality Impact |
|--------------|---------------|----------------|
| Q8_0 | 25% | Minimal |
| Q6_K | 35% | Slight |
| Q5_K_M | 40% | Moderate |
| Q4_K_M | 50% | Noticeable |
| Q3_K_M | 60% | Significant |

Specify quantization when pulling:
```bash
ollama pull llama3.1:70b-q4
```

### Instruct vs Base

- **Instruct** (default): Fine-tuned for chat/QA
- **Base**: For further fine-tuning

Most models default to instruct variants.

## Model Management

### Pull a Model

```bash
# Pull latest model
ollama pull llama3.2:3b

# Pull specific version
ollama pull llama3.2:3b-instruct

# Pull quantized
ollama pull llama3.1:70b-q4
```

### List Installed Models

```bash
ollama list
# or
./models/download-models.sh installed
```

### Delete a Model

```bash
ollama rm llama3.2:1b
# or
./models/download-models.sh delete llama3.2:1b
```

### Get Model Info

```bash
ollama show llama3.2:3b
```

## Use Case Recommendations

### General Chat & Q&A
- Best: `llama3.2:3b` (fast) or `mistral:7b` (quality)
- Alternative: `llama3.1:8b`

### Code Generation
- Best: `codellama:7b` or `deepseek-coder:6.7b`
- Alternative: `phi3:mini` (smaller)

### Reasoning & Analysis
- Best: `llama3.1:70b` (if hardware allows)
- Alternative: `llama3.1:13b` or `mixtral:8x7b`

### Summarization
- Best: `mistral:7b` or `llama3.2:3b`

### Embeddings (RAG)
- Best: `nomic-embed-text`
- Alternative: `mxbai-embed-large`

### Multilingual
- Best: `qwen2.5:7b` or `llama3.1:8b`

## Performance Benchmarks

Approximate tokens/second on reference hardware:

| Model | RTX 4090 | M2 Ultra | RTX 3080 | CPU (16 cores) |
|-------|----------|----------|----------|----------------|
| llama3.2:1b | 150+ | 100+ | 80+ | 20-30 |
| llama3.2:3b | 100+ | 70+ | 50+ | 10-20 |
| mistral:7b | 60+ | 40+ | 30+ | 5-10 |
| llama3.1:13b | 30+ | 20+ | 15+ | 2-5 |
| llama3.1:70b | 8+ | 5+ | - | - |

*Values are approximate and vary by prompt length and settings.*

## Updating Models

Models are updated periodically. Pull again to update:

```bash
ollama pull llama3.2:3b
```

Check for updates: [Ollama Model Library](https://ollama.com/library)