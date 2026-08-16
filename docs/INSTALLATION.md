# Install RAYN Weather on Apple TV

RAYN Weather is distributed as source code. There is currently no universal signed IPA, App Store listing, or TestFlight build. Each person installs the app with their own Apple Account so no maintainer certificate, device identifier, or private signing material needs to be shared.

## What you need

- A Mac running Xcode 27 beta or newer with the tvOS 27 SDK.
- An Apple TV running tvOS 27, on the same network as the Mac.
- Any personal Apple Account added to Xcode. Paid Apple Developer Program membership is not required for installation on your own device.
- Internet access for the live weather and radar providers.

The default provider configuration uses Open-Meteo and RainViewer. It does not require WeatherKit or a WeatherKit entitlement.

## Install with a free Apple Account

1. Clone the repository or download its source archive:

   ```bash
   git clone https://github.com/qh-work/RAYN.git
   ```

2. Open `RAYN.xcodeproj` in Xcode.
3. Open **Xcode > Settings > Accounts**, add your Apple Account, and let Xcode create a **Personal Team**.
4. Select the blue `RAYN` project, choose the `RAYN` app target, then open **Signing & Capabilities**.
5. Leave **Automatically manage signing** enabled and select your Personal Team.
6. If Xcode reports that the bundle identifier is unavailable, replace `com.rayn.weather.tv` with a unique identifier such as `com.example.raynweather`. This changes only your local build.
7. Pair the Apple TV:
   - Connect the Mac and Apple TV to the same network.
   - On Apple TV, open **Settings > Remotes and Devices > Remote App and Devices**.
   - In Xcode, open **Window > Devices and Simulators** (or Device Hub), select the discovered Apple TV, choose Pair, and enter the code displayed on the television.
   - tvOS does not use a separate Developer Mode switch. Pairing through Xcode exposes the required developer settings automatically.
8. Select the `RAYN` scheme and the paired Apple TV as the run destination, then choose **Product > Run**.

Xcode builds, signs, installs, and launches **RAYN Weather**. A simulator build does not require an Apple Account or device signing.

## Free-account limits

Apple currently applies these Personal Team limits:

- App IDs expire after 7 days.
- Registered devices expire after 7 days.
- Up to 3 devices and up to 3 installed development apps per device.
- The provisioning profile expires after 7 days, after which the app must be built and installed again from Xcode.

These limits are controlled by Apple, not by this repository.

## Permanent or public distribution

App Store, TestFlight, Ad Hoc, and other long-lived signed distribution require an appropriate Apple Developer Program membership, certificates, provisioning, and compliance review. The repository intentionally contains none of those private assets. An unsigned or maintainer-signed IPA would not give arbitrary Apple TVs a safe, permanent installation path.

## Troubleshooting

- **No Team appears:** add an Apple Account in Xcode Settings and accept any current Apple developer agreement shown by Xcode.
- **Bundle identifier unavailable:** use a unique reverse-domain identifier for your local build.
- **Apple TV is not discovered:** confirm both devices are on the same network, leave the Apple TV pairing screen open, and unpair stale Mac connections if necessary.
- **The app stopped opening after a week:** select the Apple TV in Xcode and run the project again to renew the free profile.
- **WeatherKit signing error:** keep `forecastSource` set to `.openMeteo`; WeatherKit is an optional adapter and is not required by the default build.

## 中文快速说明

你不需要购买 Apple Developer Program 会员即可把 RAYN Weather 安装到自己的 Apple TV。用免费 Apple 账号登录 Xcode，在项目的 **Signing & Capabilities** 中选择 **Personal Team**，将 Bundle Identifier 改成自己的唯一值，然后把 Mac 与 Apple TV 放在同一网络中完成配对并按运行键即可。

免费签名有效期为 7 天，过期后需要再次用 Xcode 构建安装；它不是 App Store 或 TestFlight 的替代方案。Apple TV 没有单独的 Developer Mode 开关，通过 Xcode 配对后会自动出现开发所需设置。

## Apple references

- [Developer account and Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [Run an app on a simulated or physical device](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)
- [Pair an Apple TV with Xcode](https://help.apple.com/xcode/mac/current/en.lproj/devbc48d1bad.html)
- [Developer Mode behavior, including tvOS](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)
