#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
PROJECT="$ROOT/PerformanceLab/AttributedTextPerformance.xcodeproj"
SCHEME="AttributedTextPerformance"
RESULTS="${PERFORMANCE_RESULTS_DIR:-$ROOT/PerformanceResults}/$(date +%Y%m%d-%H%M%S)"
DERIVED_DATA="$RESULTS/DerivedData"
DEVICE="${PERFORMANCE_DEVICE:-iPhone 17 Pro}"
INSTRUMENTS_DEVICE_NAME="${PERFORMANCE_INSTRUMENTS_DEVICE_NAME:-}"
INSTRUMENTS_TIME_LIMIT="${INSTRUMENTS_DURATION:-15}"
if [[ "$INSTRUMENTS_TIME_LIMIT" != *[[:alpha:]] ]]; then
  INSTRUMENTS_TIME_LIMIT="${INSTRUMENTS_TIME_LIMIT}s"
fi
mkdir -p "$RESULTS"
[[ -n "$INSTRUMENTS_DEVICE_NAME" ]] || {
  print -u2 "Set PERFORMANCE_INSTRUMENTS_DEVICE_NAME to the connected iPhone name shown by 'xcrun xctrace list devices'."
  exit 2
}

UDID=$(xcrun simctl list devices available | awk -v device="$DEVICE" '$0 ~ device { print; exit }' | sed -nE 's/.*\(([A-F0-9-]{36})\).*/\1/p')
[[ -n "$UDID" ]] || { print -u2 "Simulator '$DEVICE' was not found."; exit 2; }
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b

# XCTest metrics provide regression-aware duration/CPU/memory samples in the xcresult bundle.
xcodebuild test -project "$PROJECT" -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$RESULTS/PerformanceTests.xcresult"

xcrun xcresulttool get test-results metrics --path "$RESULTS/PerformanceTests.xcresult" \
  > "$RESULTS/xctest-metrics.json" 2>/dev/null || true

xcodebuild build -project "$PROJECT" -scheme "$SCHEME" -sdk iphoneos -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=YES >/dev/null
APP_PATH="$DERIVED_DATA/Build/Products/Release-iphoneos/AttributedTextPerformance.app"
xcrun devicectl device install app --device "$INSTRUMENTS_DEVICE_NAME" "$APP_PATH" >/dev/null
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist")
EXECUTABLE_NAME=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_PATH/Info.plist")
xcrun devicectl device process launch --device "$INSTRUMENTS_DEVICE_NAME" "$BUNDLE_ID" \
  -performanceScenario >/dev/null
INSTRUMENTS_DEVICE="$INSTRUMENTS_DEVICE_NAME"
INSTRUMENTS_ATTACH="$EXECUTABLE_NAME"

# Keep the complete .trace artifact: it is the authoritative source for Time Profiler analysis.
# Keep xctrace in the foreground: Instruments must own the terminal session while
# it finalizes the trace, otherwise it can leave an incomplete package behind.
xcrun xctrace record --no-prompt --template 'Time Profiler' --device "$INSTRUMENTS_DEVICE" --attach "$INSTRUMENTS_ATTACH" \
  --time-limit "$INSTRUMENTS_TIME_LIMIT" --output "$RESULTS/TimeProfiler.trace"

xcrun xctrace export --input "$RESULTS/TimeProfiler.trace" --toc > "$RESULTS/TimeProfiler-toc.xml"
[[ -s "$RESULTS/TimeProfiler-toc.xml" ]] || {
  print -u2 "Instruments produced an incomplete trace; no Time Profiler report was exported."
  exit 1
}
print "Performance artifacts: $RESULTS"
