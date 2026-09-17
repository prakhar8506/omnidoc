#!/usr/bin/env bash
# Run Health Companion against local Supabase (must already be started).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! curl -sf "http://127.0.0.1:54321/auth/v1/health" >/dev/null 2>&1; then
  echo "Starting local Supabase..."
  supabase start
fi

# Ensure functions are served (best-effort)
if ! curl -sf -X OPTIONS "http://127.0.0.1:54321/functions/v1/health-ai-chat" >/dev/null 2>&1; then
  echo "Starting Edge Functions in background..."
  nohup supabase functions serve --env-file supabase/.env.local --no-verify-jwt \
    > /tmp/hc-functions.log 2>&1 &
  sleep 2
fi

DEVICE_ARG="${1:-}"
if [[ "$(uname -s)" == "Darwin" ]]; then
  ENV_FILE="env/local.json"
else
  ENV_FILE="env/local.json"
fi

# Prefer Android emulator env when targeting android
if [[ "${DEVICE_ARG}" == *"android"* ]] || [[ "${DEVICE_ARG}" == *"-d"* && "$*" == *"emulator"* ]]; then
  ENV_FILE="env/local.android.json"
fi

echo "Using $ENV_FILE"
exec flutter run --dart-define-from-file="$ENV_FILE" "$@"
