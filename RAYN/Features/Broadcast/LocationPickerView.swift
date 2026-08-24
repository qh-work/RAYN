import SwiftUI

struct LocationPickerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Namespace private var locationFocusScope
    let openSettings: () -> Void

    private var availableSavedLocations: [SavedLocation] {
        var locations = appState.savedLocations
        if !appState.settings.useCurrentLocation,
           appState.selectedLocation.id != SavedLocation.currentPlaceholder.id,
           !locations.contains(where: { $0.id == appState.selectedLocation.id }) {
            locations.insert(appState.selectedLocation, at: 0)
        }
        return locations
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x101F30), Color(hex: 0x334B5C)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 30) {
                HStack(alignment: .center, spacing: 22) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Cities & Location")
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                        Text(appState.selectedLocation.name)
                            .font(.system(size: 25, weight: .medium, design: .rounded))
                            .opacity(0.62)
                    }

                    Spacer()

                    Button(action: openSettings) {
                        Label("Settings", systemImage: "gearshape.fill")
                            .font(.system(size: 23, weight: .bold, design: .rounded))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.glass)
                    .focusAdaptiveGlassForeground()

                    Button("Done", action: { dismiss() })
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 13)
                        .buttonStyle(.glassProminent)
                        .tint(.cyan)
                        .focusAdaptiveGlassForeground()
                }

                GlassCard(cornerRadius: 34) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            Text("Current Location")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .opacity(0.62)

                            locationButton(
                                title: String(localized: "Current Location"),
                                subtitle: appState.settings.useCurrentLocation ? appState.selectedLocation.name : "",
                                symbol: "location.fill",
                                isSelected: appState.settings.useCurrentLocation
                            ) {
                                dismiss()
                                appState.chooseCurrentLocation()
                            }

                            if !availableSavedLocations.isEmpty {
                                Text("Saved Locations")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .opacity(0.62)
                                    .padding(.top, 8)

                                LazyVGrid(
                                    columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)],
                                    spacing: 18
                                ) {
                                    ForEach(availableSavedLocations) { location in
                                        locationButton(
                                            title: location.name,
                                            subtitle: location.subtitle,
                                            symbol: "mappin.and.ellipse",
                                            isSelected: !appState.settings.useCurrentLocation && location.id == appState.selectedLocation.id
                                        ) {
                                            dismiss()
                                            appState.chooseLocation(location)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(10)
                    }
                    .scrollClipDisabled()
                }
            }
            .padding(.horizontal, 100)
            .padding(.vertical, 70)
        }
        .preferredColorScheme(.dark)
        .focusScope(locationFocusScope)
        .onExitCommand { dismiss() }
    }

    private func locationButton(
        title: String,
        subtitle: String,
        symbol: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: symbol)
                    .font(.system(size: 31, weight: .semibold))
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .opacity(0.58)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 18)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .buttonStyle(.glass)
        .tint(isSelected ? .cyan : .white)
        .focusAdaptiveGlassForeground()
        .prefersDefaultFocus(isSelected, in: locationFocusScope)
        .accessibilityValue(isSelected ? String(localized: "Selected") : "")
    }
}
