#!/usr/bin/env bash
# Resets only the clinic (healthcare) database and service.
# Does not affect the bank service or other infrastructure.
set -euo pipefail

echo "reset.step clinic_down"
docker compose rm -sfv clinic-service clinic-db >/dev/null 2>&1 || true

echo "reset.step clinic_up"
docker compose up --build -d clinic-service >/dev/null 2>&1

echo "reset.step wait_for_health"
for _ in {1..30}; do
  if curl -sS http://localhost:3100/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "reset.complete true"
