#!/usr/bin/env bash
# After you create a hosted Supabase project and log in via CLI:
#   supabase login
#   supabase link --project-ref <ref>
# then run this script to push migrations, deploy functions, and write env/production.json
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! supabase projects list >/dev/null 2>&1; then
  echo "Not logged in. Run: supabase login"
  echo "Then: supabase link --project-ref YOUR_PROJECT_REF"
  exit 1
fi

echo "Pushing database migrations..."
supabase db push

echo "Deploying Edge Functions..."
supabase functions deploy interpret-lab
supabase functions deploy health-ai-chat
supabase functions deploy delete-account

echo "Fetching API keys..."
# Writes production.json without echoing secrets
python3 - <<'PY'
import json, subprocess, os
# supabase projects api / status when linked
try:
  out = subprocess.check_output(['supabase','status','-o','json'], text=True, stderr=subprocess.STDOUT)
except subprocess.CalledProcessError:
  # Linked remote: use secrets from dashboard API via `supabase projects api-keys`
  ref = open('.temp/project-ref').read().strip() if os.path.exists('.temp/project-ref') else ''
  print('Use supabase projects api-keys --project-ref <ref> to populate env/production.json')
  raise SystemExit(0)

print('Local status detected — for remote, run after link:')
print('  supabase projects api-keys --project-ref <REF>')
PY

echo
echo "Set AI secrets (optional but recommended):"
echo "  supabase secrets set OPENAI_API_KEY=sk-...   # or GEMINI_API_KEY=..."
echo
echo "Then build:"
echo "  flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \\"
echo "    --dart-define-from-file=env/production.json"
