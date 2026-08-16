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
                Text("RAYN").font(.system(size: 16, weight: .black, design: .rounded)).tracking(3).foregroundStyle(.cyan)
                Text("演播室设置").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text("控制数据、轮播、动态效果和收藏城市").font(.system(size: 21, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.62))
            }
            Spacer()
            HStack(spacing: 14) {
                Button {
                    appState.refresh(force: true)
                } label: {
                    Label(appState.isRefreshing ? "更新中" : "立即刷新", systemImage: "arrow.clockwise")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(FocusButtonStyle())
                .foregroundStyle(.white)

                Button(action: { dismiss() }) {
                    Label("完成", systemImage: "checkmark")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
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
        settingsCard(title: "城市与位置", symbol: "location.fill") {
            VStack(alignment: .leading, spacing: 18) {
                Toggle("使用当前位置", isOn: Binding(get: { appState.settings.useCurrentLocation }, set: { value in updateSettings { $0.useCurrentLocation = value } }))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Text("启动时优先读取当前位置；关闭后使用下方设定地址。定位失败时才回退到已保存地址。")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                Text("已保存地址").font(.system(size: 18, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.58))
                HStack(spacing: 12) {
                    ForEach(appState.savedLocations) { location in
                        Button {
                            appState.chooseLocation(location)
                        } label: {
                            HStack(spacing: 9) {
                                Image(systemName: location.id == appState.selectedLocation.id ? "checkmark.circle.fill" : "mappin.circle")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(location.name)
                                    Text(location.administrativeArea).font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.55))
                                }
                            }
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 13)
                            .background(location.id == appState.selectedLocation.id ? .cyan.opacity(0.22) : .white.opacity(0.09), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(FocusButtonStyle())
                        .foregroundStyle(.white)
                    }
                }
                HStack(spacing: 12) {
                    TextField("搜索城市，例如：上海、东京", text: $searchText)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Button {
                        appState.searchLocations(query: searchText)
                    } label: {
                        Label("搜索", systemImage: "magnifyingglass")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(.cyan.opacity(0.24), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(FocusButtonStyle())
                    .foregroundStyle(.white)
                }
                if appState.isSearching {
                    ProgressView("搜索中…")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                }
                if !appState.searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("搜索结果").font(.system(size: 18, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.58))
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
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
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
        settingsCard(title: "演播轮播", symbol: "play.rectangle.fill") {
            VStack(alignment: .leading, spacing: 20) {
                Toggle("自动轮播天气场景", isOn: Binding(get: { appState.settings.automaticRotation }, set: { value in updateSettings { $0.automaticRotation = value } }))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("每页停留时间").font(.system(size: 20, weight: .semibold, design: .rounded))
                        Spacer()
                        Text("\(Int(appState.settings.rotationSeconds)) 秒").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.cyan)
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
                        Text("8–30 秒")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
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
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                }
                Text("启用场景").font(.system(size: 18, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.58))
                HStack(spacing: 12) {
                    ForEach(BroadcastScene.allCases) { scene in
                        let enabled = !appState.settings.hiddenScenes.contains(scene)
                        Button {
                            updateSettings { settings in
                                if enabled { settings.hiddenScenes.insert(scene) } else { settings.hiddenScenes.remove(scene) }
                            }
                        } label: {
                            Label(scene.title, systemImage: enabled ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(enabled ? .white.opacity(0.14) : .white.opacity(0.05), in: Capsule())
                        }
                        .buttonStyle(FocusButtonStyle())
                        .foregroundStyle(enabled ? .white : .white.opacity(0.42))
                    }
                }
            }
        }
    }

    private var displaySection: some View {
        settingsCard(title: "显示与动态", symbol: "sparkles.tv.fill") {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 24) {
                    Picker("温度单位", selection: Binding(get: { appState.settings.temperatureUnit }, set: { value in updateSettings { $0.temperatureUnit = value } })) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Picker("时钟", selection: Binding(get: { appState.settings.clockFormat }, set: { value in updateSettings { $0.clockFormat = value } })) {
                        ForEach(ClockFormat.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Picker("计量单位", selection: Binding(get: { appState.settings.measurementSystem }, set: { value in updateSettings { $0.measurementSystem = value } })) {
                    ForEach(MeasurementSystem.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("观看距离", selection: Binding(get: { appState.settings.viewingDistance }, set: { value in updateSettings { $0.viewingDistance = value } })) {
                    ForEach(ViewingDistance.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("动态效果强度", selection: Binding(get: { appState.settings.dynamicIntensity }, set: { value in updateSettings { $0.dynamicIntensity = value } })) {
                    ForEach(DynamicIntensity.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("减少动态效果", isOn: Binding(get: { appState.settings.reduceMotion }, set: { value in updateSettings { $0.reduceMotion = value } }))
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                Toggle("限制雷电闪烁", isOn: Binding(get: { !appState.settings.lightningEnabled }, set: { value in updateSettings { $0.lightningEnabled = !value } }))
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                Toggle("夜间低亮度模式", isOn: Binding(get: { appState.settings.nightDimMode }, set: { value in updateSettings { $0.nightDimMode = value } }))
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                Toggle("保持屏幕常亮", isOn: Binding(get: { appState.settings.keepScreenAwake }, set: { value in updateSettings { $0.keepScreenAwake = value } }))
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                Text("保持屏幕常亮只会在你主动开启后生效，退出设置或关闭开关后恢复系统默认。")
                    .font(.system(size: 17, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.52))
            }
        }
    }

    private var privacySection: some View {
        settingsCard(title: "隐私说明", symbol: "lock.shield.fill") {
            Text("RAYN 不要求账号登录，不包含广告、分析追踪或后台用户画像。开启“使用当前位置”后，应用才会请求位置权限；天气服务请求只发送用于查询天气的经纬度，不保存位置历史。收藏城市和设置仅保存在本机。")
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.70))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var attributionSection: some View {
        settingsCard(title: "关于与归因", symbol: "info.circle.fill") {
            VStack(alignment: .leading, spacing: 10) {
                Text("天气、空气质量、海况和雷达只在服务实际返回数据时显示；没有覆盖时不会用演示图或假数值替代。")
                ForEach(appState.dataAttributions) { attribution in
                    if let destination = URL(string: attribution.urlString) {
                        Link(destination: destination) {
                            HStack(spacing: 10) {
                                Text(attribution.title)
                                    .fontWeight(.semibold)
                                Text(attribution.detail)
                                    .foregroundStyle(.white.opacity(0.56))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .bold))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.66))
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func settingsCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        GlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: 19) {
                Label(title, systemImage: symbol)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                content()
            }
        }
    }

    private func updateSettings(_ change: (inout AppSettings) -> Void) {
        var next = appState.settings
        change(&next)
        appState.applySettings(next)
    }
}
