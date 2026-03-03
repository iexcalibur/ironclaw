# Local Bootstrap (Fresh Machine)

This is the one-time setup flow for a new local system where you already have:

- project checkout (`codex/link-origin`)
- `.env` ready
- Docker Desktop installed
- PostgreSQL installed

## One-command bootstrap

```bash
make bootstrap
```

What it does:

1. validates `.env`, Docker daemon, Rust toolchain
2. installs `wasm32-wasip2` target
3. installs `wasm-tools` (if missing)
4. runs `make setup` (DB init + Telegram channel build)
5. builds `ironclaw-worker:latest` from `Dockerfile.worker`
6. ensures sandbox vars are set in `.env`:
   - `SANDBOX_ENABLED=true`
   - `SANDBOX_IMAGE=ironclaw-worker:latest`
   - `SANDBOX_AUTO_PULL=false`

After bootstrap:

```bash
make run
```

## Manual equivalent commands

```bash
rustup target add wasm32-wasip2
cargo install wasm-tools --locked
make setup
docker build -f Dockerfile.worker -t ironclaw-worker:latest .
```

Then ensure `.env` contains:

```env
SANDBOX_ENABLED=true
SANDBOX_IMAGE=ironclaw-worker:latest
SANDBOX_AUTO_PULL=false
```

Then start:

```bash
make run
```

