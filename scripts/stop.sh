#!/bin/bash
#
# LLM Local Deploy - Stop Services
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
info() { msg "ℹ️  $1" "$BLUE"; }

# Stop services
stop_services() {
    info "Stopping services..."

    # Stop all compose services
    docker compose down 2>/dev/null || true

    # Also stop with GPU overlay if it was used
    docker compose -f docker-compose.yml -f docker-compose.gpu.yml down 2>/dev/null || true

    # And RAG overlay
    docker compose -f docker-compose.yml -f docker-compose.rag.yml down 2>/dev/null || true

    success "Services stopped"
}

# Optional: Clean up volumes
cleanup() {
    if [[ "${1:-}" == "--clean" ]]; then
        read -p "This will delete all data (models, chats, embeddings). Continue? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Removing volumes..."
            docker compose down -v 2>/dev/null || true
            docker volume rm ollama_data webui_data chroma_data 2>/dev/null || true
            success "All data removed"
        fi
    fi
}

# Main
main() {
    msg ""
    msg "🛑 Stopping LLM Local Deploy..." "$BLUE"
    msg ""

    stop_services
    cleanup "$@"

    echo ""
    msg "Services stopped. Run ./scripts/start.sh to start again." "$GREEN"
    echo ""
}

main "$@"