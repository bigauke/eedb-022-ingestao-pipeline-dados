#!/usr/bin/env bash
# Wrapper para executar o script de orquestração E2E em sistemas Linux / macOS
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/scripts/run_all.sh" "$@"
