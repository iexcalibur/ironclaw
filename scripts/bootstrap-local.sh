#!/usr/bin/env bash
# One-time local bootstrap for IronClaw on a fresh machine.
#
# Usage:
#   ./scripts/bootstrap-local.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> IronClaw local bootstrap"

if [ ! -f ".env" ]; then
  echo "ERROR: .env not found in $ROOT_DIR"
  echo "Create .env first, then rerun."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found. Install Docker Desktop first."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon is not running. Start Docker Desktop, then rerun."
  exit 1
fi

if ! command -v rustup >/dev/null 2>&1; then
  echo "ERROR: rustup not found. Install Rust from https://rustup.rs"
  exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
  echo "ERROR: cargo not found. Ensure Rust toolchain is installed."
  exit 1
fi

echo "==> Ensuring Rust target: wasm32-wasip2"
rustup target add wasm32-wasip2

if ! command -v wasm-tools >/dev/null 2>&1; then
  echo "==> Installing wasm-tools (one-time)"
  cargo install wasm-tools --locked
fi

echo "==> Running base setup (db + telegram channel build)"
make setup

echo "==> Building sandbox worker image (one-time, can take several minutes)"
docker build -f Dockerfile.worker -t ironclaw-worker:latest .

if grep -q '^SANDBOX_ENABLED=' .env; then
  sed -i.bak 's/^SANDBOX_ENABLED=.*/SANDBOX_ENABLED=true/' .env && rm -f .env.bak
else
  printf '\nSANDBOX_ENABLED=true\n' >> .env
fi

if grep -q '^SANDBOX_IMAGE=' .env; then
  sed -i.bak 's|^SANDBOX_IMAGE=.*|SANDBOX_IMAGE=ironclaw-worker:latest|' .env && rm -f .env.bak
else
  printf 'SANDBOX_IMAGE=ironclaw-worker:latest\n' >> .env
fi

if grep -q '^SANDBOX_AUTO_PULL=' .env; then
  sed -i.bak 's/^SANDBOX_AUTO_PULL=.*/SANDBOX_AUTO_PULL=false/' .env && rm -f .env.bak
else
  printf 'SANDBOX_AUTO_PULL=false\n' >> .env
fi

echo "==> Bootstrap complete"
echo "Next: make run"
