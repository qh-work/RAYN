# Physical Apple TV release checklist

Use this checklist for every public RAYN Weather release. Do not commit a personal Development Team, device identifier, provisioning profile, or Apple Account detail.

## Build and data integrity

- [ ] Build the Release configuration with the current tvOS SDK and the maintainer's local signing team.
- [ ] Confirm production startup requests live data and does not fall back to fixtures, a hard-coded city, cached startup weather, or generated radar imagery.
- [ ] Confirm the selected location follows current location first, then the user's saved location.
- [ ] Confirm provider attribution and source-update time remain available in Settings.
- [ ] Confirm missing radar, marine, moonrise, or moonset values remain explicitly unavailable instead of becoming zero or placeholders presented as observations.

## Remote and focus

- [ ] From every root scene, Menu returns to the tvOS Home Screen.
- [ ] Every available day in the 10-day list can receive focus, open details, close with Menu, and restore focus to the same day.
- [ ] Sun and Moon cards can receive focus, open their detail panels, and close with Menu or the visible Close button.
- [ ] Settings opens from the gear, every scene can be enabled or disabled, and scene-order arrows work without trapping focus.
- [ ] Focus enlargement and shadows are not clipped at navigation, hourly, daily, lunar-calendar, or screen-safe-area edges.

## A12 performance path

- [ ] On Apple TV 4K (2nd generation), repeat 24-hour → 10-day → radar → 10-day at least ten times.
- [ ] Record one cold and one warm run with the Scene Transition, Weather Refresh, Radar Map Ready, and Radar Frame Presented signposts.
- [ ] Confirm MapKit initialization does not overlap the outgoing heavy scene and radar frames do not flash through the air-quality page.
- [ ] Confirm radar playback keeps native display cadence unless Reduce Motion is enabled by the user.
- [ ] Confirm memory does not grow continuously over repeated radar loops and controls remain responsive on a slow connection.

## Display and accessibility

- [ ] Check 1080p and 4K output with the normal, near, and far viewing-distance choices.
- [ ] Check a bright television and a projector for readable highlights without oversized fixed icons.
- [ ] Check Reduce Motion, Reduce Transparency, Increased Contrast, and VoiceOver.
- [ ] Confirm current, hourly, air-quality, Sun, and Moon layouts stay above the persistent live ticker without text overlap.

## Public release

- [ ] Run unit tests, the localization validator, and focused remote-navigation UI tests.
- [ ] Capture screenshots with a public city coordinate only; never publish the maintainer's current location.
- [ ] Update `CHANGELOG.md`, `docs/ROADMAP.md`, the media gallery, and a dated change record.
- [ ] Inspect tracked files for credentials, local signing identities, personal paths, generated build products, and private location data.
- [ ] Verify the commit signature, push the signed tag, and check CI before publishing the GitHub release notes.
