#!/usr/bin/env bash
# expense-deployer/scripts/start.sh
# Start all services

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "Starting Expense Tracker services..."

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found. Run 'make setup' first."
    exit 1
fi

# Start services in correct order
echo "  - Starting infrastructure (postgres, redis)..."
docker compose up -d postgres redis

echo "  - Waiting for infrastructure to be healthy..."
sleep 5

# Wait for postgres
timeout=30
counter=0
until docker compose exec -T postgres pg_isready -U expense_user -d expense_tracker &> /dev/null 2>&1; do
    counter=$((counter + 1))
    if [ $counter -gt $timeout ]; then
        echo "ERROR: PostgreSQL is not healthy"
        exit 1
    fi
    sleep 1
done

echo "  - Starting gRPC engine..."
docker compose up -d expense-engine

echo "  - Waiting for gRPC engine..."
sleep 10

echo "  - Starting PHP services..."
docker compose up -d php nginx queue-worker

echo ""
echo "All services started!"
echo ""
echo "API:    http://localhost:8000"
echo "Health: http://localhost:8000/health"
echo ""
echo "View logs: make logs"
