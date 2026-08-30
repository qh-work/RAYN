#!/bin/bash
set -euo pipefail
# Supplements tvOS tests without launching CoreSimulator. Fixtures never ship.
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_output="$(mktemp -d "${TMPDIR:-/tmp}/rayn-core.XXXXXX")"
cd "$repo_root"
core_sources=(
  RAYN/Models/WeatherModels.swift
  RAYN/App/AppConfiguration.swift
  RAYN/Shared/DateFormatting.swift
  RAYN/Shared/Localization.swift
  RAYN/Shared/PerformanceMonitor.swift
  RAYN/VisualEffects/WeatherTheme.swift
)
for source in RAYN/Services/*.swift; do
  case "$source" in *LocationService.swift) continue ;; esac
  core_sources+=("$source")
done
if [[ "${1:-}" == "--tvos-typecheck" ]]; then
  xcrun --sdk appletvos swiftc -swift-version 5 -typecheck \
    -target arm64-apple-tvos27.0 \
    -sdk "$(xcrun --sdk appletvos --show-sdk-path)" \
    -module-cache-path "$test_output/modules" \
    "${core_sources[@]}" RAYN/Features/Broadcast/RadarTileMapView.swift
  printf 'tvOS provider and MapKit typecheck passed.\n'
  exit 0
fi
xcrun --sdk macosx swiftc -swift-version 5 \
  -target "$(uname -m)-apple-macosx26.0" \
  -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
  -module-cache-path "$test_output/modules" \
  "${core_sources[@]}" Scripts/CoreChecks.swift -o "$test_output/checks"
"$test_output/checks"
printf 'Core check artifacts: %s\n' "$test_output"
