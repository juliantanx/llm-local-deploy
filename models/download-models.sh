#!/bin/bash
#
# LLM Local Deploy - Model Management
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

msg() { echo -e "${2:-$BLUE}$1${NC}"; }
error() { msg "❌ ERROR: $1" "$RED"; exit 1; }
success() { msg "✅ $1" "$GREEN"; }
warn() { msg "⚠️  $1" "$YELLOW"; }
info() { msg "ℹ️  $1" "$BLUE"; }

OLLAMA_HOST="${OLLAMA_HOST:-localhost:11434}"
API_URL="http://${OLLAMA_HOST}/api"

# Check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        warn "jq is not installed. Installing via curl fallback..."
        return 1
    fi
    return 0
}

# Check if Ollama is running
check_ollama() {
    if ! curl -s "${API_URL}/tags" > /dev/null 2>&1; then
        error "Ollama is not running. Start services first: ./scripts/start.sh"
    fi
}

# List available models
list_models() {
    echo ""
    msg "═══════════════════════════════════════" "$BLUE"
    msg "       Available Models in Library      " "$BLUE"
    msg "═══════════════════════════════════════" "$BLUE"
    echo ""

    msg "Small Models (1-3B parameters):" "$GREEN"
    echo "  llama3.2:1b      - Meta Llama 3.2 1B (fast, ~2GB)"
    echo "  llama3.2:3b      - Meta Llama 3.2 3B (balanced, ~4GB)"
    echo "  phi3:mini        - Microsoft Phi-3 Mini (fast, ~3GB)"
    echo "  gemma2:2b        - Google Gemma 2 2B (~2GB)"
    echo ""

    msg "Medium Models (7-14B parameters):" "$GREEN"
    echo "  mistral:7b       - Mistral 7B (excellent quality, ~8GB)"
    echo "  llama3.1:8b      - Meta Llama 3.1 8B (~10GB)"
    echo "  codellama:7b     - Code Llama 7B (code-focused, ~8GB)"
    echo "  qwen2.5:7b       - Qwen 2.5 7B (~8GB)"
    echo "  llama3.1:13b     - Meta Llama 3.1 13B (~15GB)"
    echo ""

    msg "Large Models (70B+ parameters):" "$GREEN"
    echo "  llama3.1:70b     - Meta Llama 3.1 70B (~45GB)"
    echo "  mixtral:8x7b     - Mixtral 8x7B MoE (~50GB)"
    echo "  command-r:35b    - Command R 35B (~25GB)"
    echo ""

    msg "Embedding Models (for RAG):" "$GREEN"
    echo "  nomic-embed-text - Nomic Embed Text (~600MB)"
    echo "  mxbai-embed-large - Mixed Bread Large (~1GB)"
    echo "  all-minilm       - All-MiniLM (~100MB)"
    echo ""

    msg "Usage: ./models/download-models.sh pull <model-name>" "$YELLOW"
    echo ""
}

# List installed models
list_installed() {
    check_ollama

    echo ""
    msg "═══════════════════════════════════════" "$BLUE"
    msg "         Installed Models               " "$BLUE"
    msg "═══════════════════════════════════════" "$BLUE"
    echo ""

    if check_jq; then
        local models
        models=$(curl -s "${API_URL}/tags" | jq -r '.models[] | "\(.name)|\(.size / 1024 / 1024 / 1024 | floor)GB|\(.details.parameter_size // "unknown")|\(.modified_at)"' 2>/dev/null)

        if [[ -z "$models" ]]; then
            warn "No models installed"
            echo ""
            msg "Pull a model: ./models/download-models.sh pull llama3.2:3b" "$YELLOW"
            return
        fi

        printf "  %-25s %-10s %-15s %s\n" "MODEL" "SIZE" "PARAMS" "MODIFIED"
        printf "  %-25s %-10s %-15s %s\n" "-----" "----" "------" "--------"

        while IFS='|' read -r name size params modified; do
            printf "  %-25s %-10s %-15s %s\n" "$name" "$size" "$params" "$(echo "$modified" | cut -d'T' -f1)"
        done <<< "$models"
    else
        # Fallback without jq
        local response
        response=$(curl -s "${API_URL}/tags")
        if echo "$response" | grep -q '"models"'; then
            echo "$response" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | while read -r name; do
                echo "  • $name"
            done
        else
            warn "No models installed or unable to parse response"
            msg "Pull a model: ./models/download-models.sh pull llama3.2:3b" "$YELLOW"
        fi
    fi

    echo ""
}

# Pull a model
pull_model() {
    check_ollama

    local model="${1:-}"
    if [[ -z "$model" ]]; then
        error "Please specify a model name. Usage: $0 pull <model-name>"
    fi

    info "Pulling model: $model"
    info "This may take several minutes..."

    if check_jq; then
        curl -s "${API_URL}/pull" -d "{\"name\": \"${model}\"}" | while read -r line; do
            if echo "$line" | jq -e '.completed' > /dev/null 2>&1; then
                local completed
                completed=$(echo "$line" | jq -r '.completed')
                local total
                total=$(echo "$line" | jq -r '.total // 0')
                if [[ "$total" != "0" ]]; then
                    local percent=$((completed * 100 / total))
                    printf "\r  Downloading: %d%%" "$percent"
                fi
            elif echo "$line" | jq -e '.status' > /dev/null 2>&1; then
                local status
                status=$(echo "$line" | jq -r '.status')
                printf "\r  Status: %s" "$status"
            fi
        done
    else
        # Fallback without jq - just stream output
        curl -s "${API_URL}/pull" -d "{\"name\": \"${model}\"}" | while read -r line; do
            if echo "$line" | grep -q '"status"'; then
                local status
                status=$(echo "$line" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
                printf "\r  Status: %s" "$status"
            fi
        done
    fi

    echo ""
    success "Model $model pulled successfully"
}

# Delete a model
delete_model() {
    check_ollama

    local model="${1:-}"
    if [[ -z "$model" ]]; then
        error "Please specify a model name. Usage: $0 delete <model-name>"
    fi

    read -p "$(echo -e ${YELLOW}Delete model $model? [y/N]: ${NC})" -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        curl -s -X DELETE "${API_URL}/delete" -d "{\"name\": \"${model}\"}"
        success "Model $model deleted"
    else
        info "Cancelled"
    fi
}

# Show model info
show_info() {
    check_ollama

    local model="${1:-}"
    if [[ -z "$model" ]]; then
        error "Please specify a model name. Usage: $0 info <model-name>"
    fi

    info "Model information for: $model"
    echo ""

    local response
    response=$(curl -s "${API_URL}/show" -d "{\"name\": \"${model}\"}")

    if check_jq; then
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    else
        echo "$response"
    fi
}

# Recommend models based on hardware
recommend() {
    echo ""
    msg "═══════════════════════════════════════" "$BLUE"
    msg "      Recommended Models for You       " "$BLUE"
    msg "═══════════════════════════════════════" "$BLUE"
    echo ""

    # Source GPU detection
    local gpu_info
    gpu_info=$(./scripts/detect-gpu.sh --env 2>/dev/null || echo "GPU_TYPE=none")
    eval "$gpu_info"

    local gpu_type="${GPU_TYPE:-none}"
    local vram="${GPU_VRAM_GB:-0}"

    case "$gpu_type" in
        nvidia)
            msg "NVIDIA GPU detected (${vram}GB VRAM)" "$GREEN"
            echo ""
            if [[ $vram -ge 48 ]]; then
                msg "Recommended:" "$YELLOW"
                echo "  - llama3.1:70b (full precision)"
                echo "  - mixtral:8x7b"
                echo "  - command-r:35b"
            elif [[ $vram -ge 24 ]]; then
                msg "Recommended:" "$YELLOW"
                echo "  - llama3.1:13b"
                echo "  - codellama:13b"
                echo "  - qwen2.5:14b"
            elif [[ $vram -ge 12 ]]; then
                msg "Recommended:" "$YELLOW"
                echo "  - mistral:7b"
                echo "  - llama3.1:8b"
                echo "  - codellama:7b"
            elif [[ $vram -ge 6 ]]; then
                msg "Recommended:" "$YELLOW"
                echo "  - llama3.2:3b"
                echo "  - mistral:7b (may be slow)"
            else
                msg "Recommended:" "$YELLOW"
                echo "  - llama3.2:1b"
                echo "  - phi3:mini"
            fi
            ;;
        apple_silicon)
            msg "Apple Silicon detected (${vram}GB unified memory)" "$GREEN"
            echo ""
            if [[ $vram -ge 64 ]]; then
                msg "Recommended:" "$YELLOW"
                echo "  - llama3.1:70b-q4"
                echo "  - mixtral:8x7b"
            elif [[ $vram -ge 32 ]]; then
                msg "Recommended:" "$YELLOW"
                echo "  - llama3.1:13b"
                echo "  - qwen2.5:14b"
            elif [[ $vram -ge 16 ]]; then
                msg "Recommended:" "$YELLOW"
                echo "  - mistral:7b"
                echo "  - llama3.1:8b"
            else
                msg "Recommended:" "$YELLOW"
                echo "  - llama3.2:3b"
                echo "  - phi3:mini"
            fi
            ;;
        *)
            warn "No GPU detected (CPU-only mode)"
            echo ""
            msg "Recommended (small, fast models):" "$YELLOW"
            echo "  - llama3.2:1b"
            echo "  - phi3:mini"
            echo "  - gemma2:2b"
            echo ""
            warn "Note: CPU inference will be significantly slower"
            ;;
    esac

    echo ""
}

# Help
show_help() {
    echo ""
    msg "LLM Local Deploy - Model Management" "$BLUE"
    echo ""
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  list              List available models in library"
    echo "  installed         List installed models"
    echo "  pull <model>      Download a model"
    echo "  delete <model>    Delete an installed model"
    echo "  info <model>      Show model information"
    echo "  recommend         Get recommendations based on hardware"
    echo "  help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 pull llama3.2:3b"
    echo "  $0 pull nomic-embed-text  # For RAG"
    echo "  $0 delete llama3.2:1b"
    echo ""
}

# Main
main() {
    case "${1:-help}" in
        list)
            list_models
            ;;
        installed|ls)
            list_installed
            ;;
        pull|download)
            pull_model "${2:-}"
            ;;
        delete|rm)
            delete_model "${2:-}"
            ;;
        info|show)
            show_info "${2:-}"
            ;;
        recommend)
            recommend
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $1. Use '$0 help' for usage."
            ;;
    esac
}

main "$@"