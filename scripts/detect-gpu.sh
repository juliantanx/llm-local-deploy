#!/bin/bash
#
# LLM Local Deploy - GPU Detection Utility
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

msg() { echo -e "${2:-$BLUE}$1${NC}"; }
success() { msg "✅ $1" "$GREEN"; }
warn() { msg "⚠️  $1" "$YELLOW"; }
info() { msg "ℹ️  $1" "$BLUE"; }

# Detect NVIDIA GPU
detect_nvidia() {
    if ! command -v nvidia-smi &> /dev/null; then
        return 1
    fi

    if ! nvidia-smi &> /dev/null; then
        return 1
    fi

    return 0
}

# Detect Apple Silicon
detect_apple_silicon() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        return 1
    fi

    if ! sysctl -n machdep.cpu.brand_string 2>/dev/null | grep -q "Apple"; then
        return 1
    fi

    return 0
}

# Get NVIDIA GPU info
get_nvidia_info() {
    echo "GPU_TYPE=nvidia"

    local gpu_name
    gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
    echo "GPU_NAME=$gpu_name"

    local vram
    vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
    local vram_gb=$((vram / 1024))
    echo "GPU_VRAM_GB=$vram_gb"

    local driver
    driver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
    echo "GPU_DRIVER=$driver"

    local cuda
    cuda=$(nvidia-smi --query-gpu=cuda_version --format=csv,noheader | head -1)
    echo "CUDA_VERSION=$cuda"
}

# Get Apple Silicon info
get_apple_silicon_info() {
    echo "GPU_TYPE=apple_silicon"

    local chip
    chip=$(sysctl -n machdep.cpu.brand_string)
    echo "GPU_NAME=$chip"

    local total_mem
    total_mem=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    echo "GPU_VRAM_GB=$total_mem"
    echo "GPU_MEMORY_TYPE=Unified"

    # Detect chip generation
    if echo "$chip" | grep -q "M3"; then
        echo "GPU_GENERATION=M3"
    elif echo "$chip" | grep -q "M2"; then
        echo "GPU_GENERATION=M2"
    elif echo "$chip" | grep -q "M1"; then
        echo "GPU_GENERATION=M1"
    fi
}

# Print summary
print_summary() {
    echo ""
    msg "═══════════════════════════════════════" "$BLUE"
    msg "         GPU Detection Results         " "$BLUE"
    msg "═══════════════════════════════════════" "$BLUE"
    echo ""

    if detect_nvidia; then
        msg "NVIDIA GPU Detected" "$GREEN"
        echo ""
        get_nvidia_info | while read -r line; do
            echo "  $line"
        done
        echo ""
        success "GPU acceleration will be used for model inference"
    elif detect_apple_silicon; then
        msg "Apple Silicon Detected" "$GREEN"
        echo ""
        get_apple_silicon_info | while read -r line; do
            echo "  $line"
        done
        echo ""
        success "Metal acceleration will be used for model inference"
    else
        warn "No GPU Detected"
        echo ""
        echo "  GPU_TYPE=none"
        echo ""
        warn "Running in CPU-only mode (slower inference)"
    fi

    echo ""
}

# Output for scripts
output_env() {
    if detect_nvidia; then
        get_nvidia_info
    elif detect_apple_silicon; then
        get_apple_silicon_info
    else
        echo "GPU_TYPE=none"
    fi
}

# Main
main() {
    case "${1:-}" in
        --env)
            output_env
            ;;
        *)
            print_summary
            ;;
    esac
}

main "$@"