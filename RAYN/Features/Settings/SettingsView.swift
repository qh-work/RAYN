import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    settingsHeader
                    locationsSection
                    broadcastSection
                    displaySection
                    privacySection
                    attributionSection
                }
                .padding(.horizontal, 58)
                .padding(.vertical, 42)
            }
            .background(Color(hex: 0x071226).ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
        .onExitCommand { dismiss() }
    }

    private var settingsHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Settings").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text("Manage data, rotation, visual effects, and saved locations").font(.system(size: 23, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.62))
            }
            Spacer()
            HStack(spacing: 14) {
                Button {
                    appState.refresh(force: true)
                } label: {
                    Label(
                        appState.isRefreshing ? String(localized: "Updating…") : String(localized: "Refresh Now"),
                        systemImage: "arrow.clockwise"
                    )
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(FocusButtonStyle())
                .foregroundStyle(.white)

                Button(action: { dismiss() }) {
                    Label("Done", systemImage: "checkmark")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.cyan.opacity(0.22), in: Capsule())
                }
                .buttonStyle(FocusButtonStyle())
                .foregroundStyle(.white)
            }
        }
    }

    private var locationsSection: some View {
        settingsCard(title: String(localized: "Cities & Location"), symbol: "location.fill") {
            VStack(alignment: .leading, spacing: 18) {
                Toggle("Use Current Location", isOn: Binding(get: { appState.settings.useCurrentLocation }, set: { value in updateSettings { $0.useCurrentLocation = value } }))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                Text("At launch, use the current location first. When disabled, use the location selected below. A saved location is used only if positioning fails.")
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                Text("Saved Locations").font(.system(size: 20, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.58))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 420), spacing: 12)], alignment: .leading, spacing: 12) {
                    ForEach(appState.savedLocations) { location in
                        Button {
                            appState.chooseLocation(location)
                        } label: {
                            HStack(spacing: 9) {
                                Image(systemName: location.id == appState.selectedLocation.id ? "checkmark.circle.fill" : "mappin.circle")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(location.name)
                                    Text(location.administrativeArea).font(.system(size: 17, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.55))
                                }
                            }
                            .font(.system(size: 21, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 13)
                            .background(location.id == appState.selectedLocation.id ? .cyan.opacity(0.22) : .white.opacity(0.09), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(FocusButtonStyle())
                        .foregroundStyle(.white)
                    }
                }
                HStack(spacing: 12) {
                    TextField("Search cities, for example Paris or Tokyo", text: $searchText)
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Button {
                        appState.searchLocations(query: searchText)
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(.cyan.opacity(0.24), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(FocusButtonStyle())
                    .foregroundStyle(.white)
                }
                if appState.isSearching {
                    ProgressView("Searching…")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                }
                if !appState.searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search Results").font(.system(size: 20, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.58))
                        ForEach(appState.searchResults) { location in
                            Button {
                                appState.chooseLocation(location)
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                    Text(location.name)
                                    Text(location.subtitle).foregroundStyle(.white.opacity(0.55))
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(FocusButtonStyle())
                            .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
    }

    private var broadcastSection: some View {
        settingsCard(title: String(localized: "Scene Rotation"), symbol: "play.rectangle.fill") {
            VStack(alignment: .leading, spacing: 20) {
                Toggle("Automatically Rotate Weather Scenes", isOn: Binding(get: { appState.settings.automaticRotation }, set: { value in updateSettings { $0.automaticRotation = value } }))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Time per Scene").font(.system(size: 22, weight: .semibold, design: .rounded))
                        Spacer()
                        Text("\(Int(appState.settings.rotationSeconds)) seconds").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.cyan)
                    }
                    HStack(spacing: 14) {
                        Button {
                            appState.setRotationSeconds(appState.settings.rotationSeconds - 1)
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 52, height: 42)
                        }
                        .buttonStyle(FocusButtonStyle())
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Text("8–30 seconds")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.60))
                        Button {
                            appState.setRotationSeconds(appState.settings.rotationSeconds + 1)
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 52, height: 42)
                        }
                        .buttonStyle(FocusButtonStyle())
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text("Enabled Scenes")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    Spacer()
                    Text("Use the arrows to change the navigation order")
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.52))
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], alignment: .leading, spacing: 14) {
                    ForEach(Array(appState.settings.orderedScenes.enumerated()), id: \.element) { index, scene in
                        let enabled = !appState.settings.hiddenScenes.contains(scene)
                        HStack(spacing: 10) {
                            Button {
                                updateSettings { settings in
                                    if enabled { settings.hiddenScenes.insert(scene) } else { settings.hiddenScenes.remove(scene) }
                                }
                            } label: {
                                Label(scene.title, systemImage: enabled ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 14)
                                    .frame(height: 54)
                                    .background(enabled ? .white.opacity(0.14) : .white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(FocusButtonStyle())
                            .foregroundStyle(enabled ? .white : .white.opacity(0.48))

                            sceneOrderButton(
                                scene: scene,
                                direction: -1,
                                symbol: "arrow.up",
                                label: String(localized: "Earlier"),
                                disabled: index == 0
                            )
                            sceneOrderButton(
                                scene: scene,
                                direction: 1,
                                symbol: "arrow.down",
                                label: String(localized: "Later"),
                                disabled: index == appState.settings.orderedScenes.count - 1
                            )
                        }
                        .padding(8)
                        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            }
        }
    }

    private var displaySection: some View {
        settingsCard(title: String(localized: "Display & Motion"), symbol: "sparkles.tv.fill") {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 24) {
                    Picker("Temperature Unit", selection: Binding(get: { appState.settings.temperatureUnit }, set: { value in updateSettings { $0.temperatureUnit = value } })) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Picker("Clock", selection: Binding(get: { appState.settings.clockFormat }, set: { value in updateSettings { $0.clockFormat = value } })) {
                        ForEach(ClockFormat.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Picker("Measurement System", selection: Binding(get: { appState.settings.measurementSystem }, set: { value in updateSettings { $0.measurementSystem = value } })) {
                    ForEach(MeasurementSystem.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("Viewing Distance", selection: Binding(get: { appState.settings.viewingDistance }, set: { value in updateSettings { $0.viewingDistance = value } })) {
                    ForEach(ViewingDistance.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("Motion Intensity", selection: Binding(get: { appState.settings.dynamicIntensity }, set: { value in updateSettings { $0.dynamicIntensity = value } })) {
                    ForEach(DynamicIntensity.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("Reduce Motion", isOn: Binding(get: { appState.settings.reduceMotion }, set: { value in updateSettings { $0.reduceMotion = value } }))
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                Toggle("Limit Lightning Flashes", isOn: Binding(get: { !appState.settings.lightningEnabled }, set: { value in updateSettings { $0.lightningEnabled = !value } }))
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                Toggle("Low-Brightness Night Mode", isOn: Binding(get: { appState.settings.nightDimMode }, set: { value in updateSettings { $0.nightDimMode = value } }))
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                Toggle("Keep Screen Awake", isOn: Binding(get: { appState.settings.keepScreenAwake }, set: { value in updateSettings { $0.keepScreenAwake = value } }))
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                Text("Keeping the screen awake takes effect only when you enable it. Leaving Settings or turning it off restores the system default.")
                    .font(.system(size: 19, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.52))
            }
        }
    }

    private var privacySection: some View {
        settingsCard(title: String(localized: "Privacy"), symbol: "lock.shield.fill") {
            Text("No account is required. This app contains no ads, analytics tracking, or background profiling. Location permission is requested only after Use Current Location is enabled. Weather requests send only the coordinates needed for the query and do not store location history. Saved locations and settings remain on this Apple TV.")
                .font(.system(size: 21, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.70))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var attributionSection: some View {
        settingsCard(title: String(localized: "About & Attribution"), symbol: "info.circle.fill") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Weather, air quality, marine conditions, and radar appear only when a provider returns real data. Demo imagery or invented values never replace missing coverage.")
                ForEach(appState.dataAttributions) { attribution in
                    if let destination = URL(string: attribution.urlString) {
                        Link(destination: destination) {
                            HStack(spacing: 10) {
                                if let url = attribution.logoURLString.flatMap(URL.init(string:)) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFit()
                                    } placeholder: {
                                        Text(attribution.title)
                                    }
                                    .frame(width: 160, height: 34)
                                }
                                Text(attribution.title)
                                    .fontWeight(.semibold)
                                Text(attribution.detail)
                                    .foregroundStyle(.white.opacity(0.56))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .font(.system(size: 20, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.66))
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func settingsCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        GlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: 19) {
                Label(L10n.string(title), systemImage: symbol)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                content()
            }
        }
    }

    private func sceneOrderButton(
        scene: BroadcastScene,
        direction: Int,
        symbol: String,
        label: String,
        disabled: Bool
    ) -> some View {
        Button {
            updateSettings { settings in
                var order = settings.orderedScenes
                guard let currentIndex = order.firstIndex(of: scene) else { return }
                let destination = currentIndex + direction
                guard order.indices.contains(destination) else { return }
                order.swapAt(currentIndex, destination)
                settings.sceneOrder = order
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .frame(width: 44, height: 44)
                .background(.white.opacity(disabled ? 0.04 : 0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(FocusButtonStyle())
        .foregroundStyle(.white.opacity(disabled ? 0.25 : 0.82))
        .disabled(disabled)
        .accessibilityLabel(Text(verbatim: "\(label): \(scene.title)"))
    }

    private func updateSettings(_ change: (inout AppSettings) -> Void) {
        var next = appState.settings
        change(&next)
        appState.applySettings(next)
    }
}
