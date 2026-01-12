#!/usr/bin/env bash
# expense-deployer/scripts/setup.sh
# First-time setup script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Expense Tracker - First Time Setup"
echo "=========================================="

# Check prerequisites
echo ""
echo "[1/7] Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "ERROR: Docker Compose V2 is not available. Please update Docker."
    exit 1
fi

echo "  - Docker: $(docker --version)"
echo "  - Docker Compose: $(docker compose version --short)"

# Check sibling repositories
echo ""
echo "[2/7] Checking sibling repositories..."

if [ ! -d "$PROJECT_DIR/../expense-api" ]; then
    echo "ERROR: expense-api repository not found at ../expense-api"
    echo "Please clone it: git clone <expense-api-repo> ../expense-api"
    exit 1
fi

if [ ! -d "$PROJECT_DIR/../expense-engine" ]; then
    echo "ERROR: expense-engine repository not found at ../expense-engine"
    echo "Please clone it: git clone <expense-engine-repo> ../expense-engine"
    exit 1
fi

echo "  - expense-api: Found"
echo "  - expense-engine: Found"

# Create .env if not exists
echo ""
echo "[3/7] Setting up environment..."

if [ ! -f "$PROJECT_DIR/.env" ]; then
    cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
    echo "  - Created .env from .env.example"

    # Generate APP_KEY using openssl
    APP_KEY="base64:$(openssl rand -base64 32)"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|APP_KEY=.*|APP_KEY=$APP_KEY|" "$PROJECT_DIR/.env"
    else
        sed -i "s|APP_KEY=.*|APP_KEY=$APP_KEY|" "$PROJECT_DIR/.env"
    fi
    echo "  - Generated APP_KEY"

    echo ""
    echo "  IMPORTANT: Edit .env and set DB_PASSWORD before continuing!"
    read -p "  Press Enter when ready..."
else
    echo "  - .env already exists"
fi

# Validate DB_PASSWORD is set
source "$PROJECT_DIR/.env"
if [ "${DB_PASSWORD:-your_secure_password_here}" = "your_secure_password_here" ]; then
    echo ""
    echo "ERROR: DB_PASSWORD is not set in .env"
    echo "Please edit .env and set a secure password."
    exit 1
fi

# Clean up any existing network with wrong labels
echo ""
echo "[4/7] Preparing Docker network..."

if docker network inspect expense-network &> /dev/null 2>&1; then
    echo "  - Removing existing expense-network (will be recreated by Docker Compose)"
    docker network rm expense-network 2>/dev/null || true
fi
echo "  - Network will be created by Docker Compose"

# Build images
echo ""
echo "[5/7] Building Docker images..."
echo "  This may take several minutes on first run..."

cd "$PROJECT_DIR"
docker compose build --parallel

echo "  - Images built successfully"

# Start infrastructure services first
echo ""
echo "[6/7] Starting infrastructure services..."

docker compose up -d postgres redis
echo "  - Waiting for PostgreSQL to be healthy..."

# Wait for postgres to be ready
timeout=60
counter=0
until docker compose exec -T postgres pg_isready -U expense_user -d expense_tracker &> /dev/null 2>&1; do
    counter=$((counter + 1))
    if [ $counter -gt $timeout ]; then
        echo "ERROR: PostgreSQL failed to start within ${timeout} seconds"
        docker compose logs postgres
        exit 1
    fi
    sleep 1
    printf "."
done
echo ""
echo "  - PostgreSQL is ready"

# Start remaining services and run migrations
echo ""
echo "[7/7] Starting application services and running migrations..."

docker compose up -d expense-engine
echo "  - Waiting for expense-engine to be healthy..."
sleep 10

docker compose up -d php nginx queue-worker
echo "  - Waiting for PHP to be ready..."
sleep 5

# Run migrations
echo "  - Running Laravel migrations..."
docker compose exec -T php php artisan migrate --force 2>/dev/null || {
    echo "  WARNING: Migration failed. You may need to run migrations manually."
    echo "  Run: make migrate"
}

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Start all services:  make up"
echo "View logs:           make logs"
echo "Stop services:       make down"
echo ""
echo "API available at:    http://localhost:8000"
echo "Health check:        http://localhost:8000/health"
echo ""
