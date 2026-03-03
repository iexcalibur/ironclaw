SHELL := /bin/bash
export PATH := $(HOME)/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:/opt/homebrew/opt/postgresql@15/bin:/usr/local/opt/postgresql@15/bin:$(PATH)

CARGO ?= $(shell command -v cargo 2>/dev/null || echo "$(HOME)/.cargo/bin/cargo")
WASM_TOOLS ?= $(shell command -v wasm-tools 2>/dev/null || echo "$(HOME)/.cargo/bin/wasm-tools")

.PHONY: help check-env check-tools db-init build-telegram setup run status pairing pair-approve

help:
	@echo "Targets:"
	@echo "  make setup         Prepare DB + Telegram channel build artifacts"
	@echo "  make run           One-click start (loads .env and runs IronClaw)"
	@echo "  make status        Show IronClaw status using current .env"
	@echo "  make pairing       List pending Telegram pairing requests"
	@echo "  make pair-approve CODE=ABC12345  Approve Telegram pairing code"
	@echo "  make db-init       Ensure database and pgvector extension exist"

check-env:
	@test -f .env || (echo "Missing .env. Create it first."; exit 1)

check-tools:
	@test -x "$(CARGO)" || (echo "cargo not found. Install Rust: https://rustup.rs"; exit 1)
	@command -v psql >/dev/null 2>&1 || (echo "psql not found. Install PostgreSQL client tools."; exit 1)
	@command -v createdb >/dev/null 2>&1 || (echo "createdb not found. Install PostgreSQL client tools."; exit 1)
	@command -v ngrok >/dev/null 2>&1 || (echo "ngrok not found. Install ngrok CLI."; exit 1)
	@test -x "$(WASM_TOOLS)" || (echo "wasm-tools not found. Install with: $(CARGO) install wasm-tools --locked"; exit 1)

db-init: check-env
	@set -a; source .env; set +a; \
	psql postgres -v ON_ERROR_STOP=1 -c "SELECT 1 FROM pg_database WHERE datname='ironclaw'" | grep -q 1 || createdb ironclaw; \
	psql "$$DATABASE_URL" -v ON_ERROR_STOP=1 -c "CREATE EXTENSION IF NOT EXISTS vector;"

build-telegram:
	@./channels-src/telegram/build.sh

setup: check-env check-tools db-init build-telegram
	@echo "Setup complete. Run: make run"

run: check-env check-tools build-telegram
	@set -a; source .env; set +a; \
	"$(CARGO)" run -- --no-onboard run

status: check-env
	@set -a; source .env; set +a; \
	"$(CARGO)" run -- --no-onboard status

pairing: check-env
	@set -a; source .env; set +a; \
	"$(CARGO)" run -- --no-onboard pairing list telegram

pair-approve: check-env
	@if [ -z "$(CODE)" ]; then \
		echo "Usage: make pair-approve CODE=ABC12345"; \
		exit 1; \
	fi
	@set -a; source .env; set +a; \
	"$(CARGO)" run -- --no-onboard pairing approve telegram "$(CODE)"
