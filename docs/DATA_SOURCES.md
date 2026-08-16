# 数据服务与替换边界

RAYN 不把“精度高”理解成永远正确。天气预测、雷达观测和海浪模型有不同的时间尺度与覆盖边界，应用必须同时展示真实时间、来源配置和无覆盖状态，不能把缺失值补成看起来合理的数字。

## 当前实现

| 能力 | 默认实现 | 数据类型 | 重要限制 |
| --- | --- | --- | --- |
| 天气预报 | Open-Meteo Forecast API | 当前、逐小时、10 天、日出日落、风、UV | 预报模型并非气象站实况；定位坐标会影响网格结果；免费接口限非商业用途并采用 CC BY 4.0 |
| 空气质量 | Open-Meteo Air Quality API | AQI、PM2.5、PM10、O₃、NO₂、SO₂、CO | 空气质量是模型/监测融合结果，不能当作本地传感器读数；沿用同一服务许可 |
| 海况 | Open-Meteo Marine API | 波高、波向、周期、风浪、涌浪 | 近岸或陆地点可能没有海浪模型网格；无值时保留“未覆盖”，不借用远海坐标；沿用同一服务许可 |
| 雷达 | RainViewer Weather Maps API | 历史雷达帧，若接口提供则附带临近趋势帧 | 仅在实际雷达覆盖区域显示有效回波；免费公共服务没有 SLA |

## 公共展示城市验证

2026 年 8 月 16 日的发布前实时抽查使用了北京、上海、纽约、深圳、伦敦和温哥华六组公共坐标。Open-Meteo Forecast 与 Air Quality 均为六地返回了当前值、未来 10 日预报和空气质量字段。地址搜索适配器还会把这些城市的常见中英文名称规范化，并附加国家过滤，避免把“伦敦”解析到加拿大安大略省或把“纽约”解析到其他同名地点。

雷达不能按城市永久承诺覆盖。RainViewer 在中国、美国、加拿大和英国运营覆盖，但具体坐标仍可能遇到站点空洞、延迟、维护或公共接口中断。海况更加依赖海洋模型网格：本次抽查中纽约、深圳和温哥华返回了海况值，北京、上海和伦敦的所测网格没有返回当前海况字段。RAYN 每次刷新都按实际响应决定是否显示海况，不把这次抽查结果写成永久城市规则。

## WeatherKit 替换路径

`AppleWeatherKitProvider` 已经实现了 `ForecastProvider` 转换边界。启用步骤：

1. 在 `ProviderConfiguration.swift` 将 `forecastSource` 改为 `.weatherKit`。
2. 在自己的 Apple Developer App ID 中启用 WeatherKit capability，并用对应签名构建 tvOS 应用。
3. 保留 `WeatherKitForecastProvider.swift` 到 `WeatherSnapshot` 的转换；不要让 View 直接读取 WeatherKit 的 `Weather`、`HourWeather` 或 `DayWeather`。
4. 根据 WeatherKit 的归因要求在正式发行版本补充 Apple Weather 和相关气象机构归因。

WeatherKit 原生 Swift API 提供当前、分钟级降水、逐小时、逐日预报和天气警报；它需要 capability 和有效开发者配置。仓库只包含适配器，不包含任何开发者密钥。

## 雷达候选方案

### RainViewer（当前默认）

RainViewer 的公开 Weather Maps API 返回最近约两小时、十分钟间隔的雷达元数据和瓦片路径；接口也可能返回临近趋势帧。RAYN 将服务返回的瓦片模板放进 `RadarFrame.tileURLTemplate`，地图视图不依赖 RainViewer 的 JSON 结构。

RainViewer 免费公共 API 适用于个人、教育和小型社区项目，要求在应用中显示可见归因，并且不保证服务可用性。若项目未来商业化、流量增大或需要 SLA，应联系 RainViewer 或更换为自有/商业雷达服务。

Open-Meteo 免费接口当前要求非商业用途、CC BY 4.0 归因，并限制为每天 10,000 次、每小时 5,000 次和每分钟 600 次调用。项目若加入广告、订阅或用于商业产品，不能继续默认依赖免费接口，应改用其商业套餐或替换 Provider。

### NOAA NEXRAD / MRMS（区域适配候选）

NOAA 的 NEXRAD 和 MRMS 适合美国区域，数据质量和官方来源更适合美国用户。它们的服务协议、时间维度和地图格式与 RainViewer 不同，因此不能把 NOAA URL 直接塞进当前 RainViewer 瓦片类；应新增 `NOAARadarProvider`，输出同一个 `RadarSnapshot` 和 `RadarFrame.tileURLTemplate`，并根据经纬度只在美国覆盖范围内启用。

### DWD Open Data（区域适配候选）

德国气象局 DWD 提供官方雷达合成和站点雷达开放数据。它更适合德国/中欧区域，但常见数据是 RADOLAN、HDF5 或二进制网格，需要独立的解码、投影和瓦片服务层，不能在客户端假设它与 RainViewer 使用同一格式。

### 中国区域

中国区域应优先接入能够公开授权、稳定提供时间序列和瓦片/网格的官方或商业服务。不能通过抓取网页图片、登录后的私人接口或未授权镜像来声称“实时准确”。在没有合规稳定接口时，雷达页应显示无覆盖，而不是显示一张与当前位置无关的图。

## 参考链接

- [Apple WeatherKit](https://developer.apple.com/documentation/weatherkit/)
- [WeatherKit REST API](https://developer.apple.com/documentation/weatherkitrestapi)
- [Create a WeatherKit Services ID and private key](https://developer.apple.com/help/account/capabilities/create-a-services-identifier-and-private-key-for-weatherkit/)
- [RainViewer Weather Maps API](https://www.rainviewer.com/api/weather-maps-api.html)
- [RainViewer API terms and attribution](https://www.rainviewer.com/api.html)
- [Open-Meteo terms, limits and privacy](https://open-meteo.com/en/terms)
- [NOAA NEXRAD MapServer](https://gis.ncdc.noaa.gov/arcgis/rest/services/cdo/nexrad/MapServer)
- [DWD Open Data radar directory](https://opendata.dwd.de/weather/radar/)
