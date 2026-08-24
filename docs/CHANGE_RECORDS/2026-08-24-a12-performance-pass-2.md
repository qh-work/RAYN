# A12 performance pass 2

Date: 2026-08-24
Target: tvOS 27, Apple TV 4K (2nd generation, A12)

## Scope

This pass addresses the remaining theoretical sources of focus and scene-switch contention. The requested validation scope excludes physical installation and on-device installation testing.

## Findings and changes

- `GlassCard` no longer creates a backdrop material or a default shadow for every 4K card. It keeps the glass hierarchy with a static tinted gradient and border; detached shadows are opt-in for future surfaces that genuinely need them.
- `DynamicSkyView` now separates static clouds, fog, haze, and stars from animated precipitation and lightning. The animated pass keeps the system display-linked cadence; it is rendered into a 75% surface and upscaled because atmospheric particles do not need full-resolution edges.
- The initial refresh plan requests only forecast and air quality. Radar and marine data remain real provider responses but are requested on entry to those scenes, and a pending-source queue prevents a rapid remote action from dropping a request while another refresh is active.
- Radar prefetch is limited to 13 nearest tiles and four concurrent network/image-cache operations. The map still owns visible tile loading, the memory cache remains capped at 32 MB, and no disk/startup cache or synthetic echo is introduced.
- Swift Charts was removed from the hourly and air-quality hot paths. Asynchronous Canvas renderers retain discrete temperature, feels-like, rain probability, wind-speed, AQI bars, labels, and accessibility summaries without rebuilding a chart tree for each focus step.
- Astronomy glows now use gradients and translucent strokes instead of blur and shadow filters. The location title and radar container also no longer create redundant offscreen shadows.
- Scene handoff waits were reduced from 90/45 ms to 70/24 ms while keeping the outgoing scene faded before the next heavy hierarchy is inserted.

## Verification

- `xcodebuild build-for-testing` completed for the generic tvOS destination with Xcode 27 beta, tvOS 27 SDK, and signing disabled.
- `ruby scripts/validate-localizations.rb` and `git diff --check` are part of the release gate for this pass.
- The tvOS simulator remained shut down and no physical Apple TV install/launch/capture was performed, as requested.
- An Instruments attempt disconnected after approximately 1.9 seconds; no frame-rate number is treated as a valid measurement from that incomplete trace.

## Data integrity

No demo weather, synthetic radar, private location, or startup weather cache was added. The performance changes reduce when and where real provider work is scheduled; they do not replace provider values or lower the radar animation cadence.
