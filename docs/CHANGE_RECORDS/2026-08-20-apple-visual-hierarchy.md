# Apple-platform visual hierarchy refresh

Date: 2026-08-20

## Why this changed

The active location was too small to work as the identity of a television weather page. Several reusable information components also defaulted to leading alignment, making cards feel like dashboards: content accumulated on the left while large, unintentional empty areas remained on the right.

## What changed

- Promoted the active location from a 34-point leading label to a 58-point centered page title that still scales with viewing distance.
- Centered the compact scene-navigation group while retaining horizontal scrolling for longer localized labels.
- Centered scene titles while keeping supporting metadata secondary at the trailing edge.
- Changed the shared metric tile from a leading row into a centered symbol, label, and value hierarchy.
- Rebuilt clothing guidance as two balanced centered groups and removed the spreadsheet-like divider.
- Removed the divider between temperature and condition so the hero card reads as one weather composition.
- Added shared typography and radius roles in `RAYNDesign` and documented alignment rules in `docs/DESIGN_SYSTEM.md`.
- Kept native tvOS glass controls, SF Symbols, Reduce Transparency, Increased Contrast, and focus behavior as the platform foundation.

## Verification

- Built successfully with the Xcode beta tvOS 27.0 simulator SDK.
- Installed and launched on the Apple TV 4K (3rd generation) tvOS 27 simulator.
- Visually reviewed the current, 24-hour, and 10-day scenes at a 3840×2160 simulator output size.
- Confirmed that the enlarged location, centered page headers, chart, daily list, focus highlight, and bottom ticker remain visible without overlap.

## Evidence

The refreshed current-weather screenshot is stored at [`../media/screenshots/01-current-weather.png`](../media/screenshots/01-current-weather.png).
