drop table if EXISTS users, user_verification_docs, assets, asset_prices, portfolios, portfolio_transacrions, orders, trades CASCADE;
drop type if EXISTS document_type, transaction_type, order_type, order_status;














CREATE Table users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    hash_password TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP with time zone DEFAULT now()
);





















CREATE TYPE document_type AS ENUM (
    'passport',
    'national_id',
    'drivers_license',
    'others'
);



CREATE Table user_verification_docs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    given_name TEXT NOT NULL,
    surname TEXT NOT NULL,
    document_type document_type NOT NULL,
    document_number TEXT NOT NULL,
    is_male BOOLEAN NOT NULL,
    issued_by TEXT NOT NULL,
    date_of_issue DATE NOT NULL,
    date_of_expiry DATE NOT NULL,
    issuing_state TEXT NOT NULL,
    Check (date_of_expiry >= date_of_issue)
)




ALTER Table user_verification_docs ADD FOREIGN KEY (user_id) REFERENCES users (id) on delete cascade;



















CREATE Table assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    symbol VARCHAR(10) NOT NULL UNIQUE
)






















CREATE Table asset_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP with time zone DEFAULT now()
);

create INDEX idx_asset_prices_asset_id ON asset_prices (asset_id);
create INDEX idx_asset_prices_created_at ON asset_prices (created_at);
create index idx_asset_prices_created_at_asset_id on asset_prices (created_at, asset_id);




ALTER Table asset_prices ADD FOREIGN KEY (asset_id) REFERENCES assets (id) On DELETE CASCADE;




























CREATE Table portfolios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    amount Numeric(38, 18) NOT NULL,
    available_amount Numeric(38, 18) NOT NULL,
    Check (amount >= 0),
    Check (available_amount >= 0),
    UNIQUE (user_id, asset_id)
)

CREATE INDEX idx_portfolios_user_id ON portfolios (user_id);
CREATE INDEX idx_portfolios_asset_id ON portfolios (asset_id);





ALTER Table portfolios ADD FOREIGN KEY (user_id) REFERENCES users (id) On DELETE RESTRICT;
ALTER Table portfolios ADD FOREIGN KEY (asset_id) REFERENCES assets (id) On DELETE RESTRICT;



















CREATE type transaction_type as Enum (
    'buy',
    'sell',
    'fee'
);

CREATE Table portfolio_transacrions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_id UUID NOT NULL,
    transaction_type transaction_type NOT NULL,
    balance_before Numeric(38, 18) NOT NULL,
    balance_after Numeric(38, 18) NOT NULL,
    amount NUMERIC(38, 18) NOT NULL,
    created_at TIMESTAMP with time zone DEFAULT now(),
    Check (amount >= 0),
    Check (balance_before >= 0),
    Check (balance_after >= 0)
)

CREATE INDEX idx_portfolio_transactions_portfolio_id ON portfolio_transacrions (portfolio_id);
CREATE INDEX idx_portfolio_transactions_transaction_type ON portfolio_transacrions (transaction_type);
CREATE INDEX idx_portfolio_transaction_created_at ON portfolio_transacrions (created_at);




ALTER Table portfolio_transacrions ADD FOREIGN KEY (portfolio_id) REFERENCES portfolios (id) On DELETE CASCADE;






























create type order_type as Enum (
    'buy',
    'sell'
);

CREATE type order_status as Enum (
    'pending',
    'completed',
    'cancelled'
);

CREATE table orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    order_type order_type NOT NULL,
    order_status order_status NOT NULL,
    amount NUMERIC(38, 18) NOT NULL,
    filled_amount NUMERIC(38, 18) NOT NULL,
    price NUMERIC(10, 2) NOT NULL
    CHECK (amount > 0),
    CHECK (filled_amount >= 0),
    CHECK (filled_amount <= amount),
    CHECK (price >= 0)
)

create index idx_orders_user_id on orders (user_id);
create index idx_orders_asset_id on orders (asset_id);
create index idx_orders_price on orders (price);
create index idx_orders_order_type on orders (order_type);
create index idx_orders_order_status on orders (order_status);
create index idx_orders_order_type_asset_id_price on orders (order_type, asset_id, price);
CREATE index idx_orders_order_status_asset_id on orders (order_status, asset_id);





ALTER Table orders ADD FOREIGN KEY (user_id) REFERENCES users (id) On DELETE RESTRICT;
ALTER Table orders ADD FOREIGN KEY (asset_id) REFERENCES assets (id) On DELETE RESTRICT;
































CREATE Table trades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buy_order_id UUID NOT NULL,
    sell_order_id UUID NOT NULL,
    trade_amount NUMERIC(38, 18) NOT NULL,
    traded_at TIMESTAMP with time zone DEFAULT now(),
    check (trade_amount > 0)
)

create index idx_trades_buy_order_id on trades (buy_order_id);
create index idx_trades_sell_order_id on trades (sell_order_id);
create index idx_trades_created_at on trades (traded_at);



ALTER Table trades ADD FOREIGN KEY (buy_order_id) REFERENCES orders (id) On DELETE RESTRICT;
ALTER Table trades ADD FOREIGN KEY (sell_order_id) REFERENCES orders (id) On DELETE RESTRICT;