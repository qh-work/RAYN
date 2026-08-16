# RAYN 架构与维护指南

这份文档是新维护者或 AI 接手项目时的入口。先理解边界，再改具体页面。

## 1. 先看哪些文件

按下面顺序阅读：

1. `Models/WeatherModels.swift`：跨服务统一的数据模型和业务枚举。
2. `Services/ProviderContracts.swift`：五类数据源协议、归因模型和 `WeatherProviderSuite`。
3. `Services/HTTPClient.swift`：可注入的网络传输边界。
4. `Services/RefreshCoordinator.swift`：并行刷新、失败隔离和退避调度。
5. `Services/*Provider.swift`：每个供应商、每类数据各自独立的请求、DTO 和映射。
6. `Services/ProviderConfiguration.swift`：五类数据服务的唯一切换点。
7. `App/AppState.swift`：启动、当前位置优先级、设置持久化、刷新和遥控器场景切换。
8. `Features/Broadcast/BroadcastView.swift`：大屏壳层、动态背景、场景导航和底部状态条。
9. `Features/Broadcast/SceneViews.swift`：各个天气场景，以及未来 10 天的焦点和详情交互。
10. `VisualEffects/WeatherTheme.swift` 与 `DynamicSkyView.swift`：天气码到视觉情境的映射。

## 2. 唯一数据流

```text
外部服务
  -> Provider
  -> RefreshCoordinator
  -> WeatherSnapshot
  -> View / 动画 / 焦点交互
```

View 不直接访问 URL、JSON 字段或某个供应商的类型。更换服务时，先实现同一个 Provider 协议，再在 `ProviderConfiguration.swift` 切换；不要把服务判断散落到页面里。网络适配器通过 `HTTPClient` 取得数据，测试和下游发行版可替换传输实现，不必改动映射逻辑。

`WeatherSnapshot` 是稳定的内部契约。外部服务可以不同，但页面只读取统一的当前天气、逐小时、逐日、空气质量、雷达、海况和警报字段。`WeatherProviderSuite` 是组合边界，允许天气、空气质量、雷达和海况四类服务分别替换；地址搜索通过独立的 `LocationSearchProvider` 注入。Provider 同时携带 `DataAttribution`，因此“关于与归因”页面不需要知道供应商的具体类型。

## 3. 真实数据不变量

- 启动时如果开启当前位置，状态顺序是 `locating -> loading -> live`；定位失败才尝试已保存地址。
- 天气服务返回当前观测和 10 个日预报点后才进入正式天气快照。必要字段缺失时返回错误，不用温度、降水或雷达回波猜数值。
- 雷达没有帧、没有覆盖或没有地图瓦片时显示无覆盖状态。模拟器不生成程序雷达回波，实体 Apple TV 才显示服务提供的实时瓦片。
- `RefreshCoordinator` 可以保留已有快照用于局部服务失败，但启动路径没有演示 JSON 和天气缓存兜底。
- 每个快照保存 `updatedAt`、`source` 和 `isOffline`，便于后续做可观测性和服务替换。

## 4. 天气视觉规则

`WeatherTheme.from(...)` 是天气情境的单一映射入口。新增天气码时同时更新：

1. `WeatherTheme` 的情境、颜色、云量和粒子开关。
2. `WeatherCodeMapper.description` 和 `symbol`。
3. `DynamicSkyView` 中对应的视觉层（只在确有数据的情境启用）。
4. `RAYNTests` 的天气码测试。

动画只接收 `snapshot.current` 的天气码、昼夜、能见度、降水和风速；不得根据页面标题或演示状态自行改变天气。

## 5. tvOS 遥控器焦点规则

- 场景导航由 `BroadcastView` 处理。
- 未来 10 天卡片由 `DailyForecastScene` 自己管理 `@FocusState`。
- 每张日卡都是独立 `Button`：方向键移动焦点，按确认键打开同一天的 `DailyDetailCard`，返回键收起详情并恢复焦点。
- 新增可操作控件时必须提供 `accessibilityLabel` 或 `accessibilityHint`，并在实体 Apple TV 上验证焦点路径。
- 不要用一个大按钮覆盖整个页面来模拟焦点；大屏交互需要让焦点落在用户实际要选择的对象上。

## 6. 如何替换 Provider

实现过程固定为：

1. 在 `Services/` 新建独立的 Provider 文件。
2. 只在 Provider 内处理请求、解码、单位换算、错误和覆盖范围。
3. 转换成 `WeatherSnapshot` 或对应的子模型。
4. 在 `ProviderConfiguration.swift` 增加一个清晰的枚举分支；若宿主需要运行时选择，则在组合根注入自定义 `WeatherProviderSuite`。
5. 网络型 Provider 从初始化器接收 `HTTPClient`，不要重新引入 `URLSession.shared`。
6. 为天气码、缺字段、服务失败和覆盖为空增加测试。
7. 更新 `docs/DATA_SOURCES.md`，记录更新时间语义、区域限制、授权和归因要求。

WeatherKit 适配器已经独立在 `WeatherKitForecastProvider.swift`。启用它需要开发者账号中的 WeatherKit capability 和自己的签名配置；任何私钥、JWT、Service ID 或用户位置历史都不能提交到仓库。

## 7. 给其他 AI 的修改协议

接手任务时先做四件事：

1. 阅读本文件、`README.md` 和 `docs/DATA_SOURCES.md`。
2. 搜索目标类型的所有引用，确认改动会影响哪些场景和测试。
3. 先改统一模型或 Provider 边界，再改 View；不要在页面里临时拼数据。
4. 完成后运行单元测试、`git diff --check`（若仓库已初始化）并构建 tvOS 27 模拟器；涉及焦点或地图时再检查实体 Apple TV。

禁止事项：

- 不恢复启动演示数据、静态天气 JSON 或假缓存。
- 不为了让页面“看起来有数据”而把缺失值填成 0、20 或固定城市。
- 不把第三方 API key、WeatherKit 私钥或个人签名配置写入源代码。
- 不把服务商 JSON 类型泄漏到 View。
- 不把“模拟器视觉占位”当成真实天气或真实雷达结果。
