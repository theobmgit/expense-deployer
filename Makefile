# expense-deployer/Makefile
# Common automation targets

.PHONY: help setup up down restart logs logs-php logs-engine logs-queue \
        migrate migrate-fresh seed shell shell-php shell-engine shell-db \
        build rebuild clean test test-php test-engine status ps \
        health db-cli redis-cli

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
NC := \033[0m

help: ## Show this help message
	@echo "$(CYAN)Expense Tracker - Docker Compose Orchestration$(NC)"
	@echo ""
	@echo "$(GREEN)Usage:$(NC) make [target]"
	@echo ""
	@echo "$(YELLOW)Setup & Lifecycle:$(NC)"
	@grep -E '^(setup|up|down|restart|build|rebuild|clean):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Logs & Monitoring:$(NC)"
	@grep -E '^(logs|logs-php|logs-engine|logs-queue|status|ps|health):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Database & Migrations:$(NC)"
	@grep -E '^(migrate|migrate-fresh|seed|db-cli|redis-cli):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Shell Access:$(NC)"
	@grep -E '^(shell|shell-php|shell-engine|shell-db):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Testing:$(NC)"
	@grep -E '^(test|test-php|test-engine):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2}'

# =============================================================================
# Setup & Lifecycle
# =============================================================================

setup: ## First-time setup (creates .env, builds images, runs migrations)
	@./scripts/setup.sh

up: ## Start all services
	@./scripts/start.sh

down: ## Stop all services
	@./scripts/stop.sh

restart: down up ## Restart all services

build: ## Build all Docker images
	docker compose build

rebuild: ## Force rebuild all images (no cache)
	docker compose build --no-cache --parallel

clean: ## Stop services, remove volumes and networks (WARNING: deletes data!)
	docker compose down -v --remove-orphans
	@docker network rm expense-network 2>/dev/null || true
	@echo "$(RED)All data volumes and networks removed!$(NC)"

# =============================================================================
# Logs & Monitoring
# =============================================================================

logs: ## Follow logs from all services
	docker compose logs -f

logs-php: ## Follow PHP/nginx logs
	docker compose logs -f php nginx

logs-engine: ## Follow expense-engine logs
	docker compose logs -f expense-engine

logs-queue: ## Follow queue worker logs
	docker compose logs -f queue-worker

status: ## Show status of all services
	@echo "$(CYAN)Service Status:$(NC)"
	@docker compose ps -a

ps: status ## Alias for status

health: ## Check health of all services
	@echo "$(CYAN)Health Check:$(NC)"
	@echo ""
	@echo "API Health:"
	@curl -s http://localhost:8000/health 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "  API not responding"
	@echo ""
	@echo "Container Health:"
	@docker compose ps --format "table {{.Name}}\t{{.Status}}"

# =============================================================================
# Database & Migrations
# =============================================================================

migrate: ## Run Laravel migrations
	docker compose exec php php artisan migrate

migrate-fresh: ## Drop all tables and re-run migrations (WARNING: deletes data!)
	@echo "$(RED)WARNING: This will delete all data!$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	docker compose exec php php artisan migrate:fresh

seed: ## Run database seeders
	docker compose exec php php artisan db:seed

db-cli: ## Open PostgreSQL CLI
	docker compose exec postgres psql -U expense_user -d expense_tracker

redis-cli: ## Open Redis CLI
	docker compose exec redis redis-cli

# =============================================================================
# Shell Access
# =============================================================================

shell: shell-php ## Open shell in PHP container (default)

shell-php: ## Open shell in PHP container
	docker compose exec php sh

shell-engine: ## Open shell in expense-engine container
	docker compose exec expense-engine sh

shell-db: ## Open shell in PostgreSQL container
	docker compose exec postgres sh

# =============================================================================
# Testing
# =============================================================================

test: test-php ## Run all tests

test-php: ## Run PHP/Laravel tests
	docker compose exec php php artisan test

test-engine: ## Run C++ tests (note: tests run during build)
	@echo "C++ tests are executed during the build process"
