# Expense Deployer Implementation Plan

## Overview

Create Docker Compose orchestration for the expense-tracker microservices architecture, enabling single-command startup of all services with proper health checks, networking, and development workflow.

## Directory Structure

```
expense-deployer/
├── docker-compose.yml              # Main orchestration
├── docker-compose.override.yml     # Development overrides
├── .env.example                    # Environment template
├── .gitignore
├── Makefile                        # Automation targets
├── README.md                       # Documentation
└── scripts/
    ├── setup.sh                    # First-time setup
    ├── start.sh                    # Start services
    ├── stop.sh                     # Stop services
    ├── logs.sh                     # View logs
    ├── migrate.sh                  # Run migrations
    ├── test.sh                     # Run tests
    └── init-db.sql                 # PostgreSQL init
```

## Implementation Steps

### Step 1: Create docker-compose.yml

**File:** `/Users/tubui/projects/expense-tracker/expense-deployer/docker-compose.yml`

Services to define:
- **postgres** - PostgreSQL 15-alpine, health check with `pg_isready`
- **redis** - Redis 7-alpine, health check with `redis-cli ping`
- **expense-engine** - Build from `../expense-engine`, ports 50051 (gRPC) and 9090 (metrics)
- **php** - Build from `../expense-api/docker/php/Dockerfile`
- **nginx** - nginx:alpine, port 8000:80, mount nginx config from expense-api
- **queue-worker** - Same image as php, runs `php artisan queue:work`

Service dependency chain:
```
postgres (healthy) → redis (healthy) → expense-engine (healthy) → php → nginx
                                                                     → queue-worker
```

### Step 2: Create docker-compose.override.yml

**File:** `/Users/tubui/projects/expense-tracker/expense-deployer/docker-compose.override.yml`

Development overrides:
- Mount source code for hot reload: `../expense-api:/var/www/html`
- Enable debug mode: `APP_DEBUG=true`, `LOG_LEVEL=debug`
- Enable gRPC reflection for testing
- Exclude vendor directory from mount

### Step 3: Create .env.example

**File:** `/Users/tubui/projects/expense-tracker/expense-deployer/.env.example`

Variables needed:
- `APP_NAME`, `APP_ENV`, `APP_DEBUG`, `APP_KEY`, `APP_URL`
- `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`, `DB_PORT_EXTERNAL`
- `REDIS_PASSWORD`, `REDIS_PORT_EXTERNAL`
- `GRPC_TIMEOUT`, `GRPC_RETRY_ATTEMPTS`, `GRPC_PORT_EXTERNAL`
- `API_PORT`, `ENGINE_METRICS_PORT`
- `RATE_LIMIT_PER_MINUTE`, `SUPPORTED_CURRENCIES`

### Step 4: Create scripts/init-db.sql

**File:** `/Users/tubui/projects/expense-tracker/expense-deployer/scripts/init-db.sql`

- Create UUID extension
- Create `transactions_engine` table for C++ direct access
- Create indexes for user_id, date, category
- Grant permissions to expense_user

### Step 5: Create automation scripts

**Files in `/Users/tubui/projects/expense-tracker/expense-deployer/scripts/`:**

| Script | Purpose |
|--------|---------|
| `setup.sh` | Check prerequisites, create .env, build images, run migrations |
| `start.sh` | Start services in dependency order |
| `stop.sh` | Stop all services |
| `logs.sh` | View logs (all or specific service) |
| `migrate.sh` | Run Laravel migrations |
| `test.sh` | Run PHP and/or C++ tests |

### Step 6: Create Makefile

**File:** `/Users/tubui/projects/expense-tracker/expense-deployer/Makefile`

Targets:
- `help` - Show all targets
- `setup` - First-time setup
- `up` / `down` / `restart` - Lifecycle management
- `logs` / `logs-php` / `logs-engine` / `logs-queue` - Log viewing
- `migrate` / `migrate-fresh` / `seed` - Database operations
- `shell` / `shell-php` / `shell-engine` / `db-cli` / `redis-cli` - Container access
- `test` / `test-php` - Run tests
- `build` / `rebuild` / `clean` - Image management
- `status` / `health` - Monitoring

### Step 7: Create .gitignore

**File:** `/Users/tubui/projects/expense-tracker/expense-deployer/.gitignore`

Ignore: `.env`, `.env.local`, `*.log`, `.DS_Store`, IDE files

### Step 8: Create README.md

**File:** `/Users/tubui/projects/expense-tracker/expense-deployer/README.md`

Contents:
- Architecture diagram
- Prerequisites (Docker 24.x+, sibling repos)
- Quick start guide
- Services table with ports
- Common commands reference
- Configuration guide
- Development workflow (hot reload, rebuilding C++)
- Troubleshooting section

## Key Configuration Details

### Health Checks

| Service | Command | Interval | Retries | Start Period |
|---------|---------|----------|---------|--------------|
| postgres | `pg_isready -U expense_user -d expense_tracker` | 5s | 5 | 10s |
| redis | `redis-cli ping` | 5s | 5 | 5s |
| expense-engine | TCP check on port 50051 | 10s | 5 | 30s |
| nginx | `wget http://localhost/health` | 10s | 3 | 10s |

### Port Mappings

| Service | Host:Container | Purpose |
|---------|----------------|---------|
| nginx | 8000:80 | PHP API |
| postgres | 5432:5432 | Database (dev access) |
| redis | 6379:6379 | Cache (dev access) |
| expense-engine | 50051:50051 | gRPC |
| expense-engine | 9090:9090 | Metrics |

### Named Volumes

- `expense-postgres-data` - PostgreSQL persistence
- `expense-redis-data` - Redis persistence
- `expense-php-storage` - Laravel storage
- `expense-engine-data` - Engine data directory

### Network

- Bridge network: `expense-network`
- All services on same network for DNS-based service discovery
- Services reference each other by container name (postgres, redis, expense-engine)

## Verification

After implementation, verify:

1. **Single command startup:**
   ```bash
   make up
   # or: docker compose up -d
   ```

2. **Health check passes:**
   ```bash
   curl http://localhost:8000/health
   # Expected: {"status":"ok","services":{"database":"ok","redis":"ok","grpc":"ok"}}
   ```

3. **All services running:**
   ```bash
   docker compose ps
   # All containers should show "healthy" or "running"
   ```

4. **Logs viewable:**
   ```bash
   make logs
   ```

5. **Clean shutdown:**
   ```bash
   make down
   ```

6. **Data persists:**
   ```bash
   make up
   # Data should still exist after restart
   ```

## Files to Create (in order)

1. `docker-compose.yml`
2. `docker-compose.override.yml`
3. `.env.example`
4. `.gitignore`
5. `scripts/init-db.sql`
6. `scripts/setup.sh` (chmod +x)
7. `scripts/start.sh` (chmod +x)
8. `scripts/stop.sh` (chmod +x)
9. `scripts/logs.sh` (chmod +x)
10. `scripts/migrate.sh` (chmod +x)
11. `scripts/test.sh` (chmod +x)
12. `Makefile`
13. `README.md`
