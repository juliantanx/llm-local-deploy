#!/bin/bash
#
# LLM Local Deploy - cURL API Examples
#

set -e

OLLAMA_HOST="${OLLAMA_HOST:-localhost:11434}"
API_URL="http://${OLLAMA_HOST}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

msg() { echo -e "${BLUE}$1${NC}"; }
warn() { echo -e "${YELLOW}$1${NC}"; }

# Check if Ollama is running
check_ollama() {
    if ! curl -s "${API_URL}/api/tags" > /dev/null 2>&1; then
        warn "⚠️  Ollama is not running. Start services first: ./scripts/start.sh"
        exit 1
    fi
}

echo ""
msg "═══════════════════════════════════════════════════════"
msg "     LLM Local Deploy - cURL API Examples"
msg "═══════════════════════════════════════════════════════"
echo ""

# Check connection
check_ollama

# 1. List Models
msg "1. List installed models:"
echo "   curl ${API_URL}/api/tags"
echo ""
curl -s "${API_URL}/api/tags" | jq '.models[].name' 2>/dev/null || echo "   (No models installed or jq not available)"
echo ""

# 2. Generate Completion
msg "2. Generate completion:"
echo "   curl ${API_URL}/api/generate -d '{\"model\": \"llama3.2:3b\", \"prompt\": \"Hello\", \"stream\": false}'"
echo ""
echo "   Response:"
curl -s "${API_URL}/api/generate" \
    -d '{"model": "llama3.2:3b", "prompt": "Say hello in one word.", "stream": false}' \
    | jq -r '.response' 2>/dev/null || echo "   (Model not installed)"
echo ""

# 3. Chat Completion
msg "3. Chat completion:"
echo "   curl ${API_URL}/api/chat -d '{...}'"
echo ""
echo "   Response:"
curl -s "${API_URL}/api/chat" \
    -d '{
        "model": "llama3.2:3b",
        "messages": [
            {"role": "user", "content": "Say hi"}
        ],
        "stream": false
    }' \
    | jq -r '.message.content' 2>/dev/null || echo "   (Model not installed)"
echo ""

# 4. OpenAI-Compatible API - Chat
msg "4. OpenAI-compatible chat completion:"
echo "   curl ${API_URL}/v1/chat/completions -d '{...}'"
echo ""
echo "   Response:"
curl -s "${API_URL}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "llama3.2:3b",
        "messages": [
            {"role": "user", "content": "What is 2+2?"}
        ],
        "temperature": 0.7,
        "max_tokens": 50
    }' \
    | jq '.choices[0].message.content' 2>/dev/null || echo "   (Model not installed)"
echo ""

# 5. OpenAI-Compatible API - Models
msg "5. OpenAI-compatible list models:"
echo "   curl ${API_URL}/v1/models"
echo ""
curl -s "${API_URL}/v1/models" | jq '.data[].id' 2>/dev/null || echo "   (No models installed)"
echo ""

# 6. Embeddings
msg "6. Generate embeddings (requires nomic-embed-text):"
echo "   curl ${API_URL}/api/embeddings -d '{\"model\": \"nomic-embed-text\", \"prompt\": \"Hello\"}'"
echo ""
echo "   Response dimension:"
curl -s "${API_URL}/api/embeddings" \
    -d '{"model": "nomic-embed-text", "prompt": "Hello, world!"}' \
    | jq '.embedding | length' 2>/dev/null || echo "   (Embedding model not installed)"
echo ""

# 7. Streaming Example
msg "7. Streaming completion (first few chunks):"
echo "   curl ${API_URL}/api/generate -d '{\"model\": \"llama3.2:3b\", \"prompt\": \"Count to 5\"}'"
echo ""
echo "   (Streaming output, showing first 3 lines)"
curl -s "${API_URL}/api/generate" \
    -d '{"model": "llama3.2:3b", "prompt": "Say the numbers 1, 2, 3"}' \
    | head -3 | jq -r '.response' 2>/dev/null || echo "   (Model not installed)"
echo ""

# 8. Pull Model
msg "8. Pull a model (async):"
echo "   curl ${API_URL}/api/pull -d '{\"name\": \"llama3.2:1b\"}'"
echo ""

# 9. Show Model Info
msg "9. Show model information:"
echo "   curl ${API_URL}/api/show -d '{\"name\": \"llama3.2:3b\"}'"
echo ""
if curl -s "${API_URL}/api/tags" | jq -e '.models[] | select(.name == "llama3.2:3b")' > /dev/null 2>&1; then
    curl -s "${API_URL}/api/show" -d '{"name": "llama3.2:3b"}' | jq '{license, modelfile}' 2>/dev/null
else
    echo "   (Model not installed)"
fi
echo ""

msg "═══════════════════════════════════════════════════════"
msg "For more examples, see:"
msg "  - docs/MODEL_LIST.md"
msg "  - https://github.com/ollama/ollama/blob/main/docs/api.md"
msg "═══════════════════════════════════════════════════════"
echo ""