#!/bin/bash
#
# LLM Local Deploy - One-Line Installer
# Usage: curl -fsSL https://.../install.sh | bash
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
msg() {
    echo -e "${2:-$BLUE}$1${NC}"
}

error() {
    msg "❌ ERROR: $1" "$RED"
    exit 1
}

success() {
    msg "✅ $1" "$GREEN"
}

warn() {
    msg "⚠️  $1" "$YELLOW"
}

info() {
    msg "ℹ️  $1" "$BLUE"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos" ;;
        Linux*)     echo "linux" ;;
        CYGWIN*|MINGW*|MSYS*)    echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

# Check system requirements
check_requirements() {
    info "Checking system requirements..."

    # Check Docker
    if ! command_exists docker; then
        error "Docker is not installed. Please install Docker first:\n  https://docs.docker.com/get-docker/"
    fi
    success "Docker is installed"

    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        error "Docker Compose is not available. Please install Docker Compose:\n  https://docs.docker.com/compose/install/"
    fi
    success "Docker Compose is available"

    # Check Docker is running
    if ! docker info &> /dev/null; then
        error "Docker is not running. Please start Docker and try again."
    fi
    success "Docker daemon is running"

    # Check system resources
    local total_ram
    if [[ "$(detect_os)" == "macos" ]]; then
        total_ram=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    else
        total_ram=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024)}')
    fi

    if [[ $total_ram -lt 8 ]]; then
        warn "Low memory detected (${total_ram}GB). Recommended: 16GB+ for 7B models, 32GB+ for 13B models."
    else
        success "System has ${total_ram}GB RAM"
    fi

    # Check disk space (use awk instead of bc for portability)
    local available_disk
    available_disk=$(df -BG . | awk 'NR==2 {gsub(/G/,"",$4); print $4}')
    if [[ ${available_disk:-0} -lt 20 ]]; then
        warn "Low disk space (${available_disk}GB). Recommended: 50GB+ for multiple models."
    else
        success "Available disk space: ${available_disk}GB"
    fi
}

# Detect GPU
detect_gpu() {
    info "Detecting GPU..."

    GPU_TYPE="none"
    GPU_VRAM=0

    # Check for NVIDIA GPU
    if command_exists nvidia-smi; then
        if nvidia-smi &> /dev/null; then
            GPU_TYPE="nvidia"
            GPU_VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1 | awk '{print int($1/1024)}')
            success "NVIDIA GPU detected with ${GPU_VRAM}GB VRAM"
            return
        fi
    fi

    # Check for Apple Silicon
    if [[ "$(detect_os)" == "macos" ]]; then
        if sysctl -n machdep.cpu.brand_string | grep -q "Apple"; then
            GPU_TYPE="apple_silicon"
            # Estimate unified memory
            local total_mem
            total_mem=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
            GPU_VRAM=$total_mem
            success "Apple Silicon detected with ${GPU_VRAM}GB unified memory"
            return
        fi
    fi

    warn "No GPU detected. CPU-only mode will be used (slower inference)."
}

# Recommend model based on hardware
recommend_model() {
    local model="llama3.2:3b"

    if [[ "$GPU_TYPE" == "nvidia" ]]; then
        if [[ $GPU_VRAM -ge 24 ]]; then
            model="llama3.1:13b"
        elif [[ $GPU_VRAM -ge 12 ]]; then
            model="mistral:7b"
        elif [[ $GPU_VRAM -ge 6 ]]; then
            model="llama3.2:3b"
        else
            model="llama3.2:1b"
        fi
    elif [[ "$GPU_TYPE" == "apple_silicon" ]]; then
        if [[ $GPU_VRAM -ge 32 ]]; then
            model="llama3.1:13b"
        elif [[ $GPU_VRAM -ge 16 ]]; then
            model="mistral:7b"
        else
            model="llama3.2:3b"
        fi
    else
        model="llama3.2:1b"
    fi

    echo "$model"
}

# Download project files
download_files() {
    info "Downloading project files..."

    # If we're in the repo, skip download
    if [[ -f "docker-compose.yml" ]]; then
        success "Already in project directory"
        return
    fi

    # Clone or download
    if command_exists git; then
        git clone https://github.com/anthropics/llm-local-deploy.git 2>/dev/null || \
        git clone https://github.com/your-username/llm-local-deploy.git 2>/dev/null || \
        error "Failed to clone repository. Please download manually from GitHub."
        cd llm-local-deploy || error "Failed to enter project directory"
    else
        error "Git not found. Please install git or download manually from GitHub."
    fi

    success "Project files downloaded"
}

# Setup environment
setup_env() {
    info "Setting up environment..."

    if [[ ! -f ".env" ]]; then
        cp .env.example .env
        success "Created .env file from template"
    else
        warn ".env already exists, skipping"
    fi
}

# Pull Docker images
pull_images() {
    info "Pulling Docker images (this may take a few minutes)..."

    local compose_files="-f docker-compose.yml"

    if [[ "$GPU_TYPE" == "nvidia" ]]; then
        compose_files="$compose_files -f docker-compose.gpu.yml"
    fi

    docker compose $compose_files pull

    success "Docker images pulled"
}

# Download default model
download_model() {
    local model
    model=$(recommend_model)

    info "Downloading recommended model: $model"
    info "This may take several minutes depending on model size..."

    # Start ollama temporarily to pull model
    docker compose up -d ollama

    # Wait for ollama to be ready
    local max_attempts=30
    local attempt=1
    while ! curl -s http://localhost:11434/api/tags > /dev/null; do
        if [[ $attempt -eq $max_attempts ]]; then
            error "Ollama did not start within expected time"
        fi
        sleep 2
        ((attempt++))
    done

    # Pull the model
    docker exec ollama ollama pull "$model"

    success "Model $model downloaded"

    # Stop ollama for now
    docker compose down
}

# Print success message
print_success() {
    echo ""
    msg "🎉 Installation complete!" "$GREEN"
    echo ""
    msg "Quick Start:" "$BLUE"
    echo "  ./scripts/start.sh        # Start services"
    echo "  ./scripts/stop.sh         # Stop services"
    echo "  ./models/download-models.sh list    # List available models"
    echo ""
    msg "Access:" "$BLUE"
    echo "  Web UI:     http://localhost:3000"
    echo "  Ollama API: http://localhost:11434"
    echo ""
    msg "Recommended model for your hardware:" "$YELLOW"
    local model
    model=$(recommend_model)
    echo "  $model"
    echo ""
}

# Main installation flow
main() {
    msg ""
    msg "═══════════════════════════════════════════════════════" "$BLUE"
    msg "      LLM Local Deploy - One-Click Installation      " "$BLUE"
    msg "═══════════════════════════════════════════════════════" "$BLUE"
    msg ""

    check_requirements
    detect_gpu
    download_files
    setup_env
    pull_images

    # Ask if user wants to download default model
    read -p "$(echo -e ${YELLOW}Download recommended model now? [Y/n]: ${NC})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        download_model
    fi

    print_success
}

# Run main function
main "$@"