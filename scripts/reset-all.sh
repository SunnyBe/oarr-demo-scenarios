#!/usr/bin/env bash
# Resets all services: clinic and bank.
# Use this before a full demo run to start from a clean state.
set -euo pipefail

echo "reset.step all_services_down"
docker compose down -v >/dev/null 2>&1

echo "reset.step all_services_up"
docker compose up --build -d >/dev/null 2>&1

echo "reset.step wait_for_clinic"
for _ in {1..30}; do
  if curl -sS http://localhost:3100/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "reset.step wait_for_bank"
for _ in {1..30}; do
  if curl -sS http://localhost:3101/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "reset.complete true"
