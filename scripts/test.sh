#!/usr/bin/env bash
# expense-deployer/scripts/test.sh
# Run test suites

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

TARGET="${1:-all}"

case "$TARGET" in
    php|api)
        echo "Running PHP/Laravel tests..."
        docker compose exec php php artisan test
        ;;
    engine|cpp)
        echo "Running C++ tests..."
        echo "Note: C++ tests are run during the build process"
        ;;
    all)
        echo "Running all tests..."
        echo ""
        echo "=== PHP Tests ==="
        docker compose exec php php artisan test || true
        echo ""
        ;;
    *)
        echo "Usage: $0 [php|engine|all]"
        echo ""
        echo "Options:"
        echo "  php, api    Run PHP/Laravel tests"
        echo "  engine, cpp Run C++ tests (during build)"
        echo "  all         Run all tests (default)"
        exit 1
        ;;
esac
