# RAYN Weather Design Language

RAYN uses native tvOS materials, SF Symbols, focus behavior, typography, and accessibility settings to create an Apple-platform weather experience without copying private Apple assets.

## Visual hierarchy

- The active location is the page identity. It is a large, isolated leading title in the upper-left broadcast header, readable from a living-room distance and visually separated from navigation and weather content.
- The location title is also the direct city switcher. Its disclosure symbol communicates that current location and saved cities are available without opening Settings.
- A single weather value or status is centered inside its card.
- Peer values are distributed symmetrically with equal visual weight.
- Compact navigation groups are centered when they fit and remain horizontally scrollable when localization makes them wider than the viewport.
- Leading alignment is reserved for prose, alerts, lists, and settings where a stable reading edge improves comprehension.
- Secondary metadata may align to an edge, but it must not compete with the location identity.

## Type and distance

Core type roles live in `RAYNDesign.Typography`. Every size is multiplied by the user's viewing-distance scale, so the hierarchy remains consistent on televisions and projectors of different apparent sizes.

## Materials and focus

- Cards use a native-style static glass surface with continuous corners and restrained borders. Backdrop materials and shadows are reserved for deliberately detached surfaces because a full-screen 4K material pass is expensive during tvOS focus changes.
- Interactive controls use the native tvOS glass button style and adapt their foreground color when focused.
- Reduce Transparency and Increased Contrast remain authoritative accessibility settings.
- Extra stacked blur layers and decorative effects are avoided to preserve smooth focus and scene transitions on Apple TV 4K (2nd generation).

## Maintenance rule

New broadcast components should use the shared roles in `RAYNDesign` and follow the alignment rules above. A new component should not default to a leading-aligned grid merely because it contains multiple labels.
