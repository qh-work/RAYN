#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_output="$(mktemp -d "${TMPDIR:-/tmp}/rayn-live.XXXXXX")"
trap 'rm -rf "$test_output"' EXIT
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

xcrun --sdk macosx swiftc -swift-version 5 \
  -target "$(uname -m)-apple-macosx26.0" \
  -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
  -module-cache-path "$test_output/modules" \
  "${core_sources[@]}" Scripts/LiveProviderChecks.swift -o "$test_output/checks"
"$test_output/checks"
