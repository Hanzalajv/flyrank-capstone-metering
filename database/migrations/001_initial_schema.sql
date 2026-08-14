CREATE TABLE plans (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    api_call_limit INTEGER NOT NULL CHECK (api_call_limit >= 0),
    ai_token_limit INTEGER NOT NULL CHECK (ai_token_limit >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    plan_id INTEGER NOT NULL REFERENCES plans(id),
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255) UNIQUE,
    status VARCHAR(50) NOT NULL,
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TABLE usage_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    usage_type VARCHAR(50) NOT NULL,
    quantity BIGINT NOT NULL CHECK (quantity > 0),
    idempotency_key VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT usage_events_type_check
        CHECK (usage_type IN ('api_call', 'ai_token')),

    CONSTRAINT usage_events_idempotency_unique
        UNIQUE (tenant_id, idempotency_key)
);


CREATE TABLE stripe_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stripe_event_id VARCHAR(255) NOT NULL UNIQUE,
    event_type VARCHAR(255) NOT NULL,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE INDEX idx_usage_events_tenant_created
    ON usage_events (tenant_id, created_at);

CREATE INDEX idx_usage_events_tenant_type_created
    ON usage_events (tenant_id, usage_type, created_at);

CREATE INDEX idx_subscriptions_tenant
    ON subscriptions (tenant_id);