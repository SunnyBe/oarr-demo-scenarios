#!/usr/bin/env bash
# Resets only the bank (financial) database and service.
# Does not affect the clinic service or other infrastructure.
set -euo pipefail

echo "reset.step bank_down"
docker compose rm -sfv bank-service bank-db >/dev/null 2>&1 || true

echo "reset.step bank_up"
docker compose up --build -d bank-service >/dev/null 2>&1

echo "reset.step wait_for_health"
for _ in {1..30}; do
  if curl -sS http://localhost:3101/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "reset.complete true"
