CREATE TABLE IF NOT EXISTS accounts (
  id          SERIAL PRIMARY KEY,
  holder      TEXT           NOT NULL,
  account_num TEXT           NOT NULL UNIQUE,
  type        TEXT           NOT NULL,
  balance     NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
  created_at  TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS transactions (
  id          SERIAL PRIMARY KEY,
  account_id  INTEGER        NOT NULL REFERENCES accounts(id),
  type        TEXT           NOT NULL,
  amount      NUMERIC(15, 2) NOT NULL,
  description TEXT           NOT NULL,
  occurred_at TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS transfers (
  id              SERIAL PRIMARY KEY,
  from_account_id INTEGER        NOT NULL REFERENCES accounts(id),
  to_account_id   INTEGER        NOT NULL REFERENCES accounts(id),
  amount          NUMERIC(15, 2) NOT NULL,
  memo            TEXT           NOT NULL DEFAULT '',
  status          TEXT           NOT NULL DEFAULT 'completed',
  initiated_at    TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);
