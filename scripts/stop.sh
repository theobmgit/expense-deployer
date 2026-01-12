#!/usr/bin/env bash
# expense-deployer/scripts/stop.sh
# Stop all services

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "Stopping Expense Tracker services..."
docker compose down

echo "Services stopped."
echo ""
echo "Note: Data volumes are preserved. Use 'make clean' to remove them."
