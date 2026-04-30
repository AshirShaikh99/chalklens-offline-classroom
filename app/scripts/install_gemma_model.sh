#!/usr/bin/env bash
set -euo pipefail

MODEL_PATH="${1:-/Users/ashirshaikh/Downloads/gemma-4-E2B-it.litertlm}"
TARGET="${2:-auto}"
DEVICE_ID="${3:-}"
MODEL_NAME="gemma-4-E2B-it.litertlm"
ANDROID_PACKAGE="com.chalklens.app"
IOS_BUNDLE_ID="com.chalklens.app"

if [[ ! -f "$MODEL_PATH" ]]; then
  echo "Model file not found: $MODEL_PATH" >&2
  exit 1
fi

install_ios_simulator() {
  local container
  container="$(xcrun simctl get_app_container booted "$IOS_BUNDLE_ID" data)"
  mkdir -p "$container/Documents"
  cp "$MODEL_PATH" "$container/Documents/$MODEL_NAME"
  echo "Installed model to iOS simulator Documents: $container/Documents/$MODEL_NAME"
}

install_ios_device() {
  if [[ -z "$DEVICE_ID" ]]; then
    echo "A physical iPhone requires a device id/name as the third argument." >&2
    echo "Find it with: xcrun devicectl list devices" >&2
    echo "Then run: ./scripts/install_gemma_model.sh $MODEL_PATH ios-device <device-id-or-name>" >&2
    exit 1
  fi

  xcrun devicectl device copy to \
    --device "$DEVICE_ID" \
    --source "$MODEL_PATH" \
    --destination "Documents/$MODEL_NAME" \
    --domain-type appDataContainer \
    --domain-identifier "$IOS_BUNDLE_ID" \
    --timeout 1800

  echo "Installed model to iPhone app Documents/$MODEL_NAME"
}

install_android() {
  adb shell "run-as $ANDROID_PACKAGE mkdir -p app_flutter" >/dev/null
  adb exec-out "run-as $ANDROID_PACKAGE sh -c 'cat > app_flutter/$MODEL_NAME'" < "$MODEL_PATH"
  echo "Installed model to Android app_flutter/$MODEL_NAME"
}

case "$TARGET" in
  ios-sim)
    install_ios_simulator
    ;;
  ios-device)
    install_ios_device
    ;;
  android)
    install_android
    ;;
  auto)
    if xcrun simctl get_app_container booted "$IOS_BUNDLE_ID" data >/dev/null 2>&1; then
      install_ios_simulator
    elif command -v adb >/dev/null && adb shell "run-as $ANDROID_PACKAGE pwd" >/dev/null 2>&1; then
      install_android
    else
      echo "No installed iOS simulator or Android app found." >&2
      echo "Run the app once, then retry:" >&2
      echo "  ./scripts/install_gemma_model.sh $MODEL_PATH ios-sim" >&2
      echo "  ./scripts/install_gemma_model.sh $MODEL_PATH ios-device <device-id-or-name>" >&2
      echo "  ./scripts/install_gemma_model.sh $MODEL_PATH android" >&2
      exit 1
    fi
    ;;
  *)
    echo "Unknown target: $TARGET. Use auto, ios-sim, ios-device, or android." >&2
    exit 1
    ;;
esac
