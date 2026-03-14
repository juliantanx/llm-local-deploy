#!/bin/bash
#
# LLM Local Deploy - Start Services
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

# Detect GPU type
detect_gpu() {
    if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
        echo "nvidia"
        return
    fi

    if [[ "$(uname -s)" == "Darwin" ]] && sysctl -n machdep.cpu.brand_string 2>/dev/null | grep -q "Apple"; then
        echo "apple_silicon"
        return
    fi

    echo "none"
}

# Build compose command based on detected hardware
build_compose_cmd() {
    local cmd="docker compose"

    # Base compose file
    cmd="$cmd -f docker-compose.yml"

    # GPU overlay
    local gpu_type
    gpu_type=$(detect_gpu)

    if [[ "$gpu_type" == "nvidia" ]]; then
        if [[ -f "docker-compose.gpu.yml" ]]; then
            cmd="$cmd -f docker-compose.gpu.yml"
            info "NVIDIA GPU detected, using GPU acceleration"
        fi
    elif [[ "$gpu_type" == "apple_silicon" ]]; then
        info "Apple Silicon detected, using Metal acceleration"
    else
        warn "No GPU detected, running in CPU-only mode"
    fi

    # RAG overlay if ChromaDB data exists
    if [[ -d "data/chroma" ]] || [[ "${ENABLE_RAG:-false}" == "true" ]]; then
        if [[ -f "docker-compose.rag.yml" ]]; then
            cmd="$cmd -f docker-compose.rag.yml"
            info "RAG support enabled"
        fi
    fi

    echo "$cmd"
}

# Check if services are already running
check_running() {
    if docker compose ps -q 2>/dev/null | grep -q .; then
        warn "Services are already running"
        read -p "Restart services? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose down
        else
            exit 0
        fi
    fi
}

# Wait for services to be healthy
wait_for_services() {
    info "Waiting for services to be healthy..."

    local ollama_port="${OLLAMA_PORT:-11434}"
    local webui_port="${WEBUI_PORT:-3000}"
    local max_wait=120
    local elapsed=0

    while [[ $elapsed -lt $max_wait ]]; do
        if curl -s "http://localhost:${ollama_port}/api/tags" > /dev/null 2>&1; then
            success "Ollama is ready"
            break
        fi
        sleep 2
        ((elapsed+=2))
    done

    if [[ $elapsed -ge $max_wait ]]; then
        error "Ollama failed to start within ${max_wait}s"
    fi

    # Wait for WebUI
    elapsed=0
    while [[ $elapsed -lt $max_wait ]]; do
        if curl -s "http://localhost:${webui_port}/health" > /dev/null 2>&1; then
            success "Open WebUI is ready"
            break
        fi
        sleep 2
        ((elapsed+=2))
    done

    if [[ $elapsed -ge $max_wait ]]; then
        warn "WebUI may still be starting..."
    fi
}

# Main
main() {
    msg ""
    msg "🚀 Starting LLM Local Deploy..." "$BLUE"
    msg ""

    # Check if .env exists
    if [[ ! -f ".env" ]]; then
        warn "No .env file found, creating from template..."
        cp .env.example .env
    fi

    check_running

    # Get compose command
    COMPOSE_CMD=$(build_compose_cmd)

    # Start services
    info "Starting services..."
    $COMPOSE_CMD up -d

    wait_for_services

    echo ""
    msg "🎉 Services are running!" "$GREEN"
    echo ""
    msg "Access points:" "$BLUE"
    echo "  Web UI:     http://localhost:${WEBUI_PORT:-3000}"
    echo "  Ollama API: http://localhost:${OLLAMA_PORT:-11434}"
    echo ""
    msg "Useful commands:" "$BLUE"
    echo "  ./scripts/stop.sh           # Stop services"
    echo "  docker compose logs -f      # View logs"
    echo "  ./models/download-models.sh # Manage models"
    echo ""
}

main "$@"