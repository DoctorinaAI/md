#!/bin/zsh
# Runs the on-device benchmarks and saves the results with their environment.
#
#   tool/device_bench.sh <macos|device-id> <out-dir> [label]
#
# Environment:
#   SUITE  all (default), stages, frames, scroll, code or parse.
#
# The ios/, android/ and macos/ runners are generated once and gitignored. They need the
# network client entitlement: flutter drive talks to the app over the VM service.
set -eu

device=${1:?device id}
out=${2:?output directory}
label=${3:-run}
cd "${0:A:h}/.."
mkdir -p "$out"

if [[ ! -d macos || ! -d ios || ! -d android ]]; then
  flutter create --platforms=macos,ios,android --org dev.plugfox \
    --project-name md_benchmark_compare . >/dev/null
  # The app template; the benchmarks bring their own entry points.
  rm -f lib/main.dart test/widget_test.dart
  for f in macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements; do
    /usr/libexec/PlistBuddy -c \
      'Add :com.apple.security.network.client bool true' "$f" 2>/dev/null || true
  done
fi
commit=$(git rev-parse --short HEAD)
[[ -z $(git status --porcelain -- ../lib) ]] || commit="$commit+dirty"

{
  echo "label: $label"
  echo "commit: $commit"
  echo "date: $(date -u +%FT%TZ)"
  flutter --version --machine | tr -d '\n'
  echo
  flutter pub deps --style=compact 2>/dev/null |
    grep -E '^- (flutter_md|flutter_markdown|gpt_markdown|markdown) ' || true
  if [[ $device == macos ]]; then
    system_profiler SPHardwareDataType | grep -E 'Model Identifier|Chip|Memory'
    sw_vers -productVersion
  elif adb -s "$device" get-state >/dev/null 2>&1; then
    for p in ro.product.manufacturer ro.product.model ro.soc.model \
      ro.build.version.release ro.build.version.sdk; do
      echo "$p: $(adb -s "$device" shell getprop "$p")"
    done
    adb -s "$device" shell cat /proc/meminfo | head -1
  else
    xcrun devicectl device info details --device "$device" 2>/dev/null |
      grep -E 'Marketing Name|osVersionNumber|CPU Count' || true
  fi
} >"$out/$label.env.txt"

run() {
  local target=$1 name=$2
  shift 2
  rm -f build/integration_response_data.json
  flutter drive --profile -d "$device" --no-pub \
    --driver=test_driver/perf_driver.dart --target="$target" "$@" \
    >"$out/$label.$name.log" 2>&1
  cp build/integration_response_data.json "$out/$label.$name.json"
}

run integration_test/device_bench_test.dart device \
  --dart-define=SUITE="${SUITE:-all}"
echo "done: $out/$label"
