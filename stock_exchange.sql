-- Удаление таблиц и типов (при наличии)
drop table if EXISTS users, user_verification_docs, assets, asset_prices, portfolios, portfolio_transacrions, orders, trades CASCADE;
drop type if EXISTS document_type, transaction_type, order_type, order_status;

-- Таблица пользователей
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    hash_password TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP with time zone DEFAULT now()
);

-- Тип документов
CREATE TYPE document_type AS ENUM (
    'passport',
    'national_id',
    'drivers_license',
    'others'
);

-- Документы верификации пользователей
CREATE TABLE user_verification_docs (
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
    CHECK (date_of_expiry >= date_of_issue)
);
ALTER TABLE user_verification_docs ADD FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE;

-- Таблица активов
CREATE TABLE assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    symbol VARCHAR(10) NOT NULL UNIQUE
);

-- Таблица цен активов
CREATE TABLE asset_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP with time zone DEFAULT now()
);
CREATE INDEX idx_asset_prices_asset_id ON asset_prices (asset_id);
CREATE INDEX idx_asset_prices_created_at ON asset_prices (created_at);
ALTER TABLE asset_prices ADD FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE;

-- Таблица портфелей
CREATE TABLE portfolios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    amount NUMERIC(38, 18) NOT NULL,
    available_amount NUMERIC(38, 18) NOT NULL,
    CHECK (amount >= 0),
    CHECK (available_amount >= 0),
    UNIQUE (user_id, asset_id)
);
CREATE INDEX idx_portfolios_user_id ON portfolios (user_id);
CREATE INDEX idx_portfolios_asset_id ON portfolios (asset_id);
ALTER TABLE portfolios ADD FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT;
ALTER TABLE portfolios ADD FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE RESTRICT;

-- Таблица транзакций портфелей
CREATE TYPE transaction_type AS ENUM (
    'buy',
    'sell',
    'fee'
);
CREATE TABLE portfolio_transacrions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_id UUID NOT NULL,
    transaction_type transaction_type NOT NULL,
    balance_before NUMERIC(38, 18) NOT NULL,
    balance_after NUMERIC(38, 18) NOT NULL,
    amount NUMERIC(38, 18) NOT NULL,
    created_at TIMESTAMP with time zone DEFAULT now(),
    CHECK (amount >= 0),
    CHECK (balance_before >= 0),
    CHECK (balance_after >= 0)
);
CREATE INDEX idx_portfolio_transactions_portfolio_id ON portfolio_transacrions (portfolio_id);
CREATE INDEX idx_portfolio_transactions_transaction_type ON portfolio_transacrions (transaction_type);
CREATE INDEX idx_portfolio_transaction_created_at ON portfolio_transacrions (created_at);
ALTER TABLE portfolio_transacrions ADD FOREIGN KEY (portfolio_id) REFERENCES portfolios (id) ON DELETE CASCADE;

-- Таблица заказов
CREATE TYPE order_type AS ENUM (
    'buy',
    'sell'
);
CREATE TYPE order_status AS ENUM (
    'pending',
    'completed',
    'cancelled'
);
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    order_type order_type NOT NULL,
    order_status order_status NOT NULL,
    amount NUMERIC(38, 18) NOT NULL,
    filled_amount NUMERIC(38, 18) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    CHECK (amount > 0),
    CHECK (filled_amount >= 0),
    CHECK (filled_amount <= amount),
    CHECK (price >= 0)
);
create index idx_orders_user_id on orders (user_id);
create index idx_orders_asset_id on orders (asset_id);
create index idx_orders_price on orders (price);
create index idx_orders_order_type on orders (order_type);
create index idx_orders_order_status on orders (order_status);
create index idx_orders_order_type_asset_id_price on orders (order_type, asset_id, price);
CREATE index idx_orders_order_status_asset_id on orders (order_status, asset_id);
ALTER TABLE orders ADD FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT;
ALTER TABLE orders ADD FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE RESTRICT;

-- Таблица сделок
CREATE TABLE trades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buy_order_id UUID NOT NULL,
    sell_order_id UUID NOT NULL,
    trade_amount NUMERIC(38, 18) NOT NULL,
    traded_at TIMESTAMP with time zone DEFAULT now(),
    CHECK (trade_amount > 0)
);
CREATE INDEX idx_trades_buy_order_id ON trades (buy_order_id);
CREATE INDEX idx_trades_sell_order_id ON trades (sell_order_id);
CREATE INDEX idx_trades_created_at ON trades (traded_at);
ALTER TABLE trades ADD FOREIGN KEY (buy_order_id) REFERENCES orders (id) ON DELETE RESTRICT;
ALTER TABLE trades ADD FOREIGN KEY (sell_order_id) REFERENCES orders (id) ON DELETE RESTRICT;

-- Добавление данных
INSERT INTO users (username, hash_password, email)
VALUES 
  ('user1', 'hash_password1', 'user1@example.com'),
  ('user2', 'hash_password2', 'user2@example.com');

INSERT INTO user_verification_docs (user_id, given_name, surname, document_type, document_number, is_male, issued_by, date_of_issue, date_of_expiry, issuing_state)
VALUES
  (
    (SELECT id FROM users WHERE username = 'user1'),
    'Иван',
    'Иванов',
    'passport',
    '123456789',
    true,
    'ОВД',
    '2020-01-01',
    '2030-01-01',
    'RU'
  ),
  (
    (SELECT id FROM users WHERE username = 'user2'),
    'Мария',
    'Петрова',
    'national_id',
    '987654321',
    false,
    'МВД',
    '2019-05-20',
    '2029-05-20',
    'RU'
  );

INSERT INTO assets (name, symbol)
VALUES 
  ('Bitcoin', 'BTC'),
  ('Ethereum', 'ETH');

INSERT INTO asset_prices (asset_id, price)
VALUES
  (
    (SELECT id FROM assets WHERE symbol = 'BTC'),
    45000.00
  ),
  (
    (SELECT id FROM assets WHERE symbol = 'BTC'),
    45500.00
  ),
  (
    (SELECT id FROM assets WHERE symbol = 'ETH'),
    3000.00
  ),
  (
    (SELECT id FROM assets WHERE symbol = 'ETH'),
    3050.00
  );

INSERT INTO portfolios (user_id, asset_id, amount, available_amount)
VALUES
  (
    (SELECT id FROM users WHERE username = 'user1'),
    (SELECT id FROM assets WHERE symbol = 'BTC'),
    1.5,
    1.5
  ),
  (
    (SELECT id FROM users WHERE username = 'user2'),
    (SELECT id FROM assets WHERE symbol = 'ETH'),
    10,
    8
  );

INSERT INTO portfolio_transacrions (portfolio_id, transaction_type, balance_before, balance_after, amount)
VALUES
  (
    (SELECT id FROM portfolios WHERE user_id = (SELECT id FROM users WHERE username = 'user1') 
      AND asset_id = (SELECT id FROM assets WHERE symbol = 'BTC')),
    'buy',
    0,
    1.5,
    1.5
  ),
  (
    (SELECT id FROM portfolios WHERE user_id = (SELECT id FROM users WHERE username = 'user2') 
      AND asset_id = (SELECT id FROM assets WHERE symbol = 'ETH')),
    'buy',
    0,
    10,
    10
  );

INSERT INTO orders (user_id, asset_id, order_type, order_status, amount, filled_amount, price)
VALUES
  (
    (SELECT id FROM users WHERE username = 'user1'),
    (SELECT id FROM assets WHERE symbol = 'BTC'),
    'buy',
    'pending',
    1.0,
    0,
    45000.00
  ),
  (
    (SELECT id FROM users WHERE username = 'user2'),
    (SELECT id FROM assets WHERE symbol = 'ETH'),
    'sell',
    'pending',
    5.0,
    0,
    3050.00
  );

INSERT INTO trades (buy_order_id, sell_order_id, trade_amount)
VALUES
  (
    (SELECT id FROM orders WHERE user_id = (SELECT id FROM users WHERE username = 'user1') AND order_type = 'buy'),
    (SELECT id FROM orders WHERE user_id = (SELECT id FROM users WHERE username = 'user2') AND order_type = 'sell'),
    0.5
  );
