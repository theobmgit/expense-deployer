#!/usr/bin/env bash
# expense-deployer/scripts/migrate.sh
# Run Laravel migrations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "Running Laravel migrations..."

# Check if PHP container is running
if ! docker compose ps php --status running &> /dev/null 2>&1; then
    echo "ERROR: PHP container is not running. Start services first."
    echo "Run: make up"
    exit 1
fi

# Run migrations
docker compose exec php php artisan migrate "$@"

echo ""
echo "Migrations complete."
