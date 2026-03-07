#!/usr/bin/env bash
set -euo pipefail

echo "reset.step compose_down_with_volumes"
docker compose down -v >/dev/null

echo "reset.step compose_up_build_detached"
docker compose up --build -d >/dev/null

echo "reset.step wait_for_health"
for _ in {1..30}; do
  if curl -sS http://localhost:3000/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "reset.complete true"
