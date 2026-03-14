# LLM Local Deploy - Makefile

.PHONY: help install start stop restart status logs pull list clean gpu-check

# Default target
help:
	@echo ""
	@echo "LLM Local Deploy - Available Commands"
	@echo "======================================"
	@echo ""
	@echo "  make install      One-line installation"
	@echo "  make start        Start all services"
	@echo "  make stop         Stop all services"
	@echo "  make restart      Restart all services"
	@echo "  make status       Show service status"
	@echo "  make logs         View logs (follow mode)"
	@echo "  make pull MODEL=  Pull a model (e.g., make pull MODEL=llama3.2:3b)"
	@echo "  make list         List installed models"
	@echo "  make gpu-check    Detect GPU capabilities"
	@echo "  make clean        Remove all data (models, chats, etc.)"
	@echo ""

# Installation
install:
	@./scripts/install.sh

# Start services
start:
	@./scripts/start.sh

# Stop services
stop:
	@./scripts/stop.sh

# Restart services
restart: stop start

# Show status
status:
	@echo "Service Status:"
	@docker compose ps 2>/dev/null || echo "Services not running"
	@echo ""
	@if curl -s http://localhost:${OLLAMA_PORT:-11434}/api/tags > /dev/null 2>&1; then \
		echo "Ollama API: ✓ Running"; \
		echo ""; \
		echo "Installed models:"; \
		curl -s http://localhost:${OLLAMA_PORT:-11434}/api/tags | (command -v jq > /dev/null && jq -r '.models[].name' || grep -o '"name":"[^"]*"' | cut -d'"' -f4) 2>/dev/null; \
	else \
		echo "Ollama API: ✗ Not running"; \
	fi
	@echo ""
	@if curl -s http://localhost:${WEBUI_PORT:-3000}/health > /dev/null 2>&1; then \
		echo "Open WebUI: ✓ Running"; \
	else \
		echo "Open WebUI: ✗ Not running"; \
	fi

# View logs
logs:
	docker compose logs -f

# Pull a model
pull:
ifndef MODEL
	@echo "Usage: make pull MODEL=<model-name>"
	@echo "Example: make pull MODEL=llama3.2:3b"
else
	@./models/download-models.sh pull $(MODEL)
endif

# List models
list:
	@./models/download-models.sh installed

# GPU check
gpu-check:
	@./scripts/detect-gpu.sh

# Clean up
clean:
	@echo "⚠️  This will delete all data (models, chats, embeddings)"
	@read -p "Continue? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker compose down -v; \
		docker volume rm ollama_data webui_data chroma_data 2>/dev/null || true; \
		rm -rf data/; \
		echo "✓ All data removed"; \
	else \
		echo "Cancelled"; \
	fi

# Quick start (for development)
dev: start
	@echo ""
	@echo "Services started!"
	@echo "Web UI: http://localhost:3000"
	@echo "API:    http://localhost:11434"