# 🏠 LLM Local Deploy

Run powerful LLMs locally with a single command. Privacy-first, no cloud needed, OpenAI-compatible API.

## Quick Start

```bash
# One-line installation
curl -fsSL https://raw.githubusercontent.com/juliantanx/llm-local-deploy/main/scripts/install.sh | bash

# Or clone and run
git clone https://github.com/juliantanx/llm-local-deploy.git
cd llm-local-deploy
./scripts/install.sh
```

**Prerequisites:**
- [Docker](https://docs.docker.com/get-docker/) (20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2+)
- Optional: [Git](https://git-scm.com/) for cloning

## Why Local LLMs?

| Feature | Local | Cloud |
|---------|-------|-------|
| 🔒 Privacy | Your data never leaves your machine | Data sent to third party |
| 💰 Cost | Free unlimited queries | Pay per token |
| 🚀 Latency | No network delays | Network overhead |
| 🛡️ Control | Own your models | Vendor lock-in |
| 📡 Offline | Works without internet | Requires connection |

## Features

- ✅ **One-command setup** - Get running in under 5 minutes
- ✅ **GPU optimized** - Auto-detect NVIDIA/Apple Silicon
- ✅ **OpenAI compatible** - Drop-in API replacement
- ✅ **Beautiful UI** - Open WebUI with chat interface
- ✅ **RAG ready** - Built-in document knowledge base
- ✅ **Privacy first** - Everything runs locally

## Hardware Requirements

| Model Size | RAM | GPU VRAM | Example Models |
|------------|-----|----------|----------------|
| 1-3B | 8GB | 4GB | llama3.2:1b, phi3:mini |
| 7B | 16GB | 8GB | mistral:7b, llama3.2:3b |
| 13B | 32GB | 16GB | llama3.1:13b, codellama:13b |
| 70B | 64GB | 48GB | llama3.1:70b |

## Usage

### Start Services

```bash
./scripts/start.sh
```

Access:
- **Web UI**: http://localhost:3000
- **API**: http://localhost:11434

### Stop Services

```bash
./scripts/stop.sh
```

### Model Management

```bash
# List available models
./models/download-models.sh list

# Pull a model
./models/download-models.sh pull llama3.2:3b

# List installed models
./models/download-models.sh installed

# Get recommendations for your hardware
./models/download-models.sh recommend
```

### Using Make

```bash
make start       # Start services
make stop        # Stop services
make status      # Check status
make pull MODEL=llama3.2:3b  # Pull model
make logs        # View logs
```

## API Usage

### OpenAI-Compatible API

Works with any OpenAI SDK:

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:11434/v1",
    api_key="ollama"  # Required but unused
)

response = client.chat.completions.create(
    model="llama3.2:3b",
    messages=[
        {"role": "user", "content": "Hello!"}
    ]
)
print(response.choices[0].message.content)
```

### cURL Examples

```bash
# Chat completion
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:3b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'

# List models
curl http://localhost:11434/v1/models

# Generate embeddings
curl http://localhost:11434/api/embeddings \
  -d '{"model": "nomic-embed-text", "prompt": "Hello world"}'
```

See `examples/api-usage/` for more examples.

## RAG (Document Q&A)

Enable knowledge base for your documents:

```bash
# Start with RAG support
ENABLE_RAG=true ./scripts/start.sh

# Pull embedding model
ollama pull nomic-embed-text
```

Upload documents via WebUI → Workspace → Documents.

See [RAG Guide](docs/RAG_GUIDE.md) for details.

## GPU Support

### NVIDIA

1. Install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
2. Run `./scripts/start.sh` (auto-detected)

### Apple Silicon

No additional setup needed - Metal acceleration works automatically.

See [GPU Setup Guide](docs/GPU_SETUP.md) for details.

## Popular Models

| Model | Use Case | Size |
|-------|----------|------|
| llama3.2:3b | General purpose | ~4GB |
| mistral:7b | High quality chat | ~8GB |
| codellama:7b | Code generation | ~8GB |
| nomic-embed-text | Embeddings (RAG) | ~600MB |

See [Model List](docs/MODEL_LIST.md) for full recommendations.

## Project Structure

```
llm-local-deploy/
├── docker-compose.yml       # Core services (Ollama, WebUI)
├── docker-compose.gpu.yml   # NVIDIA GPU overlay
├── docker-compose.rag.yml   # ChromaDB for RAG
├── scripts/
│   ├── install.sh           # One-line installer
│   ├── start.sh             # Start services
│   ├── stop.sh              # Stop services
│   └── detect-gpu.sh        # GPU detection
├── models/
│   └── download-models.sh   # Model management
├── config/
│   ├── ollama.config.json   # Model recommendations
│   └── webui.config.json    # WebUI settings
├── docs/
│   ├── GPU_SETUP.md
│   ├── MODEL_LIST.md
│   └── RAG_GUIDE.md
└── examples/
    └── api-usage/           # API examples
```

## Troubleshooting

### Port Already in Use

```bash
# Change ports in .env
OLLAMA_PORT=11435
WEBUI_PORT=3001
```

### Out of Memory

1. Use a smaller model
2. Reduce GPU layers: `OLLAMA_GPU_LAYERS=20`
3. Use quantized models: `llama3.1:70b-q4`

### Slow Inference

1. Enable GPU (NVIDIA or Apple Silicon)
2. Keep model loaded: `OLLAMA_KEEP_ALIVE=30m`
3. Use smaller model for faster responses

## Contributing

Contributions welcome! Please read the contributing guidelines first.

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [Ollama](https://ollama.ai/) - LLM inference engine
- [Open WebUI](https://github.com/open-webui/open-webui) - Web interface
- [ChromaDB](https://www.trychroma.com/) - Vector database

---

**⭐ Star this repo if you find it useful!**