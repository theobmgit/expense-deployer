#!/usr/bin/env bash
# expense-deployer/scripts/logs.sh
# View service logs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Parse arguments
SERVICE="${1:-}"
FOLLOW="${2:--f}"

if [ -z "$SERVICE" ]; then
    # All services
    docker compose logs $FOLLOW
else
    docker compose logs $FOLLOW "$SERVICE"
fi
