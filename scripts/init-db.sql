-- expense-deployer/scripts/init-db.sql
-- PostgreSQL initialization script
-- This runs automatically on first container startup

-- Ensure extensions are available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create transactions table for C++ engine direct access
-- Note: Laravel will manage migrations for its own tables
CREATE TABLE IF NOT EXISTS transactions_engine (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    amount BIGINT NOT NULL,  -- Stored as cents (amount * 100)
    currency VARCHAR(3) NOT NULL,
    description TEXT NOT NULL,
    date DATE NOT NULL,
    category VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    import_batch_id UUID
);

-- Create indexes for C++ engine queries
CREATE INDEX IF NOT EXISTS idx_transactions_engine_user_id ON transactions_engine(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_engine_date ON transactions_engine(date);
CREATE INDEX IF NOT EXISTS idx_transactions_engine_category ON transactions_engine(category);
CREATE INDEX IF NOT EXISTS idx_transactions_engine_batch ON transactions_engine(import_batch_id);

-- Grant permissions to application user
-- Note: The user is already created by POSTGRES_USER env var
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO expense_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO expense_user;

-- Log initialization
DO $$
BEGIN
    RAISE NOTICE 'Database initialization completed successfully';
END $$;
