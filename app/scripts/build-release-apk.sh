#!/usr/bin/env bash
# Build a signed-debug-key release APK with the model URL from app/.env
# baked in as a Dart compile-time constant. Output lands at:
#   build/app/outputs/flutter-apk/app-release.apk

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$APP_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE — copy .env.example to .env and fill it in." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -z "${GEMMA_MODEL_URL:-}" ]]; then
  echo "GEMMA_MODEL_URL is not set in $ENV_FILE." >&2
  exit 1
fi

cd "$APP_DIR"
flutter build apk --release \
  --dart-define=GEMMA_MODEL_URL="$GEMMA_MODEL_URL" \
  "$@"

OUT="build/app/outputs/flutter-apk/app-release.apk"
if [[ -f "$OUT" ]]; then
  SIZE="$(du -h "$OUT" | awk '{print $1}')"
  echo
  echo "Built $OUT ($SIZE)"
fi
