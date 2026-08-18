# Astronomy visual refresh

Date: 2026-08-18

## User-visible changes

- Reworked the moon card around a soft, spherical moon treatment: the unlit hemisphere remains visible as earthshine, the illuminated region has a feathered terminator, and a restrained procedural surface texture replaces the old flat crescent.
- Replaced the horizontal daylight capsule with an event-led sunrise/sunset composition. The card now presents the next solar event prominently, draws the daytime arc with the current sun position, and repeats both endpoint times below the graph.
- Moved page-level supporting detail to the right side of the header and gave the astronomy title its own measured row. This prevents the title and detail from being painted under the glass cards on large TV layouts.
- Reduced internal spacing and preview sizes only where needed so both astronomy cards finish before the persistent live-data ticker.

## Design reference

The layout was compared against the macOS Weather astronomy cards available in the local Weather app. The implementation uses native SwiftUI drawing and SF Symbols; it does not copy Apple-owned image assets.

## Validation

- Built successfully with Xcode beta 27A5237l and the tvOS 27.0 Simulator SDK.
- Installed and visually checked the astronomy scene on the Apple TV 4K (3rd generation) tvOS 27 simulator using a fixed Beijing capture location.
- Verified that the astronomy title, solar arc, moon phase details, seven-day phase strip, and bottom ticker are all visible without card or text clipping.
- Kept the change provider-neutral: the visuals consume the existing sunrise, sunset, moonrise, moonset, phase, and daily forecast model fields.
