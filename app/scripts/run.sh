#!/usr/bin/env bash
# Run ChalkLens in development with values from app/.env injected as
# Dart compile-time constants. Pass extra flutter run flags after `--`.
#
#   ./scripts/run.sh
#   ./scripts/run.sh -d <device-id>
#   ./scripts/run.sh --release

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$APP_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE — copy .env.example to .env and fill it in." >&2
  exit 1
fi

# Load .env without exporting nothing; only known keys are forwarded.
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -z "${GEMMA_MODEL_URL:-}" ]]; then
  echo "GEMMA_MODEL_URL is not set in $ENV_FILE." >&2
  exit 1
fi

cd "$APP_DIR"
exec flutter run \
  --dart-define=GEMMA_MODEL_URL="$GEMMA_MODEL_URL" \
  "$@"
