# Claude Context: Expense Tracker Deployment

This file provides context for Claude sessions working on the expense-tracker project.

## Project Overview

The Expense Tracker is a microservices-based application with three repositories:

```
expense-tracker/
├── expense-api/        # PHP Laravel REST API
├── expense-engine/     # C++ gRPC calculation engine
└── expense-deployer/   # Docker Compose orchestration (this repo)
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      expense-deployer                           │
│                    (Docker Compose)                             │
└─────────────────────────────────────────────────────────────────┘
                              │
    ┌─────────────────────────┼─────────────────────────────┐
    │                         │                             │
    ▼                         ▼                             ▼
┌─────────────┐      ┌─────────────────┐           ┌──────────────┐
│ expense-api │─────▶│ expense-engine  │           │Infrastructure│
│ (PHP 8.4)   │ gRPC │ (C++ gRPC)      │           │              │
│ Laravel     │      │ Port 50051      │           │ - PostgreSQL │
│ Port 8000   │      │ Metrics: 9090   │           │ - Redis      │
└─────────────┘      └─────────────────┘           └──────────────┘
       │                     │                            │
       └─────────────────────┴────────────────────────────┘
                             │
                    ┌────────┴────────┐
                    │   PostgreSQL    │
                    │  (shared DB)    │
                    └─────────────────┘
```

## Services (defined in docker-compose.yml)

| Service | Image/Build | Ports | Purpose |
|---------|-------------|-------|---------|
| postgres | postgres:15-alpine | 5432 | Shared database |
| redis | redis:7-alpine | 6379 | Cache, sessions, queue |
| expense-engine | ../expense-engine/Dockerfile | 50051, 9090 | C++ gRPC service |
| php | ../expense-api/docker/php/Dockerfile | (internal) | PHP-FPM |
| nginx | nginx:alpine | 8000 | Reverse proxy |
| queue-worker | (same as php) | (internal) | Laravel queue |

## Key Files

### expense-deployer (this repo)
- `docker-compose.yml` - Main orchestration, all services
- `docker-compose.override.yml` - Development overrides (hot reload)
- `.env.example` - Environment template
- `Makefile` - Automation (make up, make down, make logs, etc.)
- `scripts/` - Shell scripts for setup, start, stop, migrate, etc.

### expense-api
- `docker/php/Dockerfile` - PHP-FPM container definition
- `docker/nginx/default.conf` - Nginx configuration (mounted by deployer)
- `.env.example` - Laravel env var documentation
- NO docker-compose.yml (removed, handled by deployer)

### expense-engine
- `Dockerfile` - Multi-stage C++ build
- `config/` - Configuration files
- NO docker-compose.yml (removed, handled by deployer)

## Common Commands

```bash
# From expense-deployer directory
make setup       # First-time setup
make up          # Start all services
make down        # Stop services
make logs        # View all logs
make logs-php    # PHP/nginx logs
make logs-engine # C++ engine logs
make migrate     # Run Laravel migrations
make shell       # Shell into PHP container
make db-cli      # PostgreSQL CLI
make test        # Run tests
make rebuild     # Force rebuild images
```

## Environment Variables

Key variables in `.env`:
- `APP_KEY` - Laravel encryption key (required, base64 encoded)
- `DB_PASSWORD` - PostgreSQL password (required)
- `APP_ENV` - Environment (local/production)
- `API_PORT` - API port mapping (default: 8000)

## Health Checks

- API: `GET http://localhost:8000/health`
- Returns: `{"status":"ok","services":{"database":"ok","redis":"ok","grpc":"ok"}}`

## Development Workflow

1. Code changes in expense-api are hot-reloaded (mounted volume)
2. Code changes in expense-engine require rebuild: `docker compose build expense-engine`
3. Database migrations: `make migrate`
4. View logs: `make logs` or `make logs-php`

## History

- Individual docker-compose.yml files were removed from expense-api and expense-engine
- All orchestration consolidated into expense-deployer
- READMEs in sibling repos updated to point to expense-deployer

## Troubleshooting

- If services won't start: `make clean && make setup`
- If PHP errors: `docker compose exec php php artisan cache:clear`
- If gRPC fails: Check expense-engine logs with `make logs-engine`
- Port conflicts: Modify ports in `.env`
