import SwiftUI

/// A single composited weather atmosphere keeps the animated backdrop from
/// competing with tvOS focus and glass composition on A12 hardware. The
/// weather state and native display cadence are unchanged; only the number of
/// simultaneously animated SwiftUI subtrees is reduced.
struct DynamicSkyView: View {
    let theme: WeatherTheme
    let isDay: Bool
    let intensity: DynamicIntensity
    let reduceMotion: Bool
    let lightningEnabled: Bool

    private var animatesAtmosphere: Bool {
        !reduceMotion && (
            theme == .clearNight ||
            theme.cloudDensity > 0 ||
            theme.hasRain ||
            theme.hasSnow ||
            theme.hasFog ||
            theme.hasHaze ||
            theme.hasHail ||
            theme == .freezingRain ||
            (theme == .storm && lightningEnabled)
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: theme.colors(isDay: isDay),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if theme == .clearDay {
                    // The clear-day glow is static; removing an otherwise
                    // empty display-link update saves work on an idle home
                    // screen without changing the visual identity.
                    SunGlowLayer()
                }

                if animatesAtmosphere {
                    TimelineView(.animation) { context in
                        WeatherAtmosphereCanvas(
                            theme: theme,
                            intensity: intensity,
                            lightningEnabled: lightningEnabled,
                            phase: context.date.timeIntervalSinceReferenceDate
                        )
                    }
                } else if reduceMotion {
                    WeatherAtmosphereCanvas(
                        theme: theme,
                        intensity: intensity,
                        lightningEnabled: false,
                        phase: 0
                    )
                }

                LinearGradient(
                    colors: [.black.opacity(0.03), .black.opacity(0.26)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
            .frame(width: geometry.size.width + 8, height: geometry.size.height + 8)
            .clipped()
        }
        .ignoresSafeArea()
    }
}

private struct SunGlowLayer: View {
    var body: some View {
        GeometryReader { geometry in
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.yellow.opacity(0.32), .orange.opacity(0.10), .clear],
                        center: .center,
                        startRadius: 2,
                        endRadius: max(180, geometry.size.height * 0.42)
                    )
                )
                .frame(width: geometry.size.height * 0.92, height: geometry.size.height * 0.92)
                .position(x: geometry.size.width * 0.78, y: geometry.size.height * 0.15)
        }
        .allowsHitTesting(false)
    }
}

private struct WeatherAtmosphereCanvas: View {
    let theme: WeatherTheme
    let intensity: DynamicIntensity
    let lightningEnabled: Bool
    let phase: TimeInterval

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            if theme == .clearNight {
                drawStars(&context, size: size)
            }
            if theme.cloudDensity > 0 {
                drawClouds(&context, size: size)
            }
            if theme.hasRain {
                drawRain(&context, size: size)
            }
            if theme.hasSnow {
                drawSnow(&context, size: size)
            }
            if theme.hasFog {
                drawFog(&context, size: size)
            }
            if theme.hasHaze {
                drawHaze(&context, size: size)
            }
            if theme.hasHail {
                drawHail(&context, size: size)
            }
            if theme == .freezingRain {
                drawIceSparkles(&context, size: size)
            }
            if theme == .storm && lightningEnabled {
                drawLightning(&context, size: size)
            }
        }
        .allowsHitTesting(false)
    }

    private var particleCount: Int {
        intensity.particleCount
    }

    private func drawStars(_ context: inout GraphicsContext, size: CGSize) {
        for index in 0..<max(18, particleCount) {
            let x = CGFloat((index * 71 + 19) % 1000) / 1000 * size.width
            let y = CGFloat((index * 137 + 31) % 630) / 630 * size.height * 0.72
            let twinkle = 0.30 + 0.22 * abs(sin(phase / 2.5 + Double(index)))
            let radius = CGFloat(1 + index % 3)
            fillEllipse(
                &context,
                rect: CGRect(x: x, y: y, width: radius, height: radius),
                color: .white.opacity(twinkle)
            )
        }
    }

    private func drawClouds(_ context: inout GraphicsContext, size: CGSize) {
        let density = min(theme.cloudDensity, 1.18)
        drawCloud(
            &context,
            center: CGPoint(
                x: size.width * 0.20 + CGFloat(sin(phase / 24) * 18),
                y: size.height * 0.20
            ),
            width: size.width * 0.58,
            height: 170,
            opacity: 0.17 * density
        )
        drawCloud(
            &context,
            center: CGPoint(
                x: size.width * 0.73 + CGFloat(cos(phase / 29) * 22),
                y: size.height * 0.34
            ),
            width: size.width * 0.45,
            height: 132,
            opacity: 0.13 * density
        )
        drawCloud(
            &context,
            center: CGPoint(
                x: size.width * 0.50 + CGFloat(sin(phase / 35) * 15),
                y: size.height * 0.72
            ),
            width: size.width * 0.76,
            height: 190,
            opacity: 0.10 * density
        )
    }

    private func drawCloud(
        _ context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat,
        opacity: Double
    ) {
        fillEllipse(
            &context,
            rect: CGRect(
                x: center.x - width * 0.40,
                y: center.y - height * 0.225,
                width: width * 0.80,
                height: height * 0.45
            ),
            color: .white.opacity(opacity)
        )
        fillEllipse(
            &context,
            rect: CGRect(
                x: center.x - width * 0.39,
                y: center.y - height * 0.405,
                width: width * 0.34,
                height: height * 0.65
            ),
            color: .white.opacity(opacity * 1.25)
        )
        fillEllipse(
            &context,
            rect: CGRect(
                x: center.x - width * 0.05,
                y: center.y - height * 0.425,
                width: width * 0.42,
                height: height * 0.74
            ),
            color: .white.opacity(opacity * 1.10)
        )
    }

    private func drawRain(_ context: inout GraphicsContext, size: CGSize) {
        let strength = theme.rainStrength
        for index in 0..<particleCount {
            let baseX = CGFloat((index * 71 + 37) % 1000) / 1000 * size.width
            let baseY = CGFloat((index * 83 + 11) % 700) / 700 * size.height
            let speed = (90 + CGFloat(index % 8) * 18) * CGFloat(strength)
            let y = (baseY + CGFloat(phase.truncatingRemainder(dividingBy: 8)) * speed)
                .truncatingRemainder(dividingBy: size.height + 100) - 80
            var path = Path()
            path.move(to: CGPoint(x: baseX, y: y))
            path.addLine(to: CGPoint(x: baseX - 18 * CGFloat(strength), y: y + (50 + CGFloat(index % 4) * 10) * CGFloat(strength)))
            context.stroke(
                path,
                with: .color(.white.opacity(0.16 + strength * 0.10)),
                lineWidth: CGFloat(1 + index % 2) * CGFloat(strength)
            )
        }
    }

    private func drawSnow(_ context: inout GraphicsContext, size: CGSize) {
        for index in 0..<particleCount {
            let baseX = CGFloat((index * 97 + 23) % 1000) / 1000 * size.width
            let baseY = CGFloat((index * 193 + 13) % 800) / 800 * size.height
            let drift = sin(phase / 3 + Double(index)) * 32
            let speed = 28 + CGFloat(index % 7) * 7
            let y = (baseY + CGFloat(phase.truncatingRemainder(dividingBy: 12)) * speed)
                .truncatingRemainder(dividingBy: size.height + 80) - 40
            let radius = CGFloat(2 + index % 5)
            fillEllipse(
                &context,
                rect: CGRect(x: baseX + drift, y: y, width: radius, height: radius),
                color: .white.opacity(0.72)
            )
        }
    }

    private func drawFog(_ context: inout GraphicsContext, size: CGSize) {
        drawHazeBand(&context, size: size, y: 0.30, width: 0.90, height: 150, opacity: 0.13, drift: sin(phase / 17) * 80)
        drawHazeBand(&context, size: size, y: 0.55, width: 0.75, height: 110, opacity: 0.10, drift: cos(phase / 13) * 100)
        drawHazeBand(&context, size: size, y: 0.78, width: 0.88, height: 170, opacity: 0.08, drift: sin(phase / 21) * 120)
    }

    private func drawHaze(_ context: inout GraphicsContext, size: CGSize) {
        let band = CGRect(x: 0, y: size.height * 0.38, width: size.width, height: size.height * 0.34)
        context.fill(Path(band), with: .color(.orange.opacity(0.10)))
        drawHazeBand(&context, size: size, y: 0.58, width: 0.82, height: 120, opacity: 0.09, drift: sin(phase / 22) * 90)
    }

    private func drawHazeBand(
        _ context: inout GraphicsContext,
        size: CGSize,
        y: Double,
        width: Double,
        height: CGFloat,
        opacity: Double,
        drift: Double
    ) {
        let rect = CGRect(
            x: size.width * (0.5 - width / 2) + drift,
            y: size.height * y - height / 2,
            width: size.width * width,
            height: height
        )
        context.fill(Path(roundedRect: rect, cornerRadius: height / 2), with: .color(.white.opacity(opacity)))
    }

    private func drawHail(_ context: inout GraphicsContext, size: CGSize) {
        for index in 0..<max(12, particleCount / 2) {
            let baseX = CGFloat((index * 149 + 43) % 1000) / 1000 * size.width
            let baseY = CGFloat((index * 97 + 29) % 800) / 800 * size.height
            let speed = 135 + CGFloat(index % 6) * 18
            let y = (baseY + CGFloat(phase.truncatingRemainder(dividingBy: 8)) * speed)
                .truncatingRemainder(dividingBy: size.height + 80) - 40
            let sizeValue = CGFloat(3 + index % 4)
            fillEllipse(
                &context,
                rect: CGRect(x: baseX, y: y, width: sizeValue, height: sizeValue),
                color: .white.opacity(0.68)
            )
        }
    }

    private func drawIceSparkles(_ context: inout GraphicsContext, size: CGSize) {
        for index in 0..<max(10, particleCount / 3) {
            let x = CGFloat((index * 113 + 17) % 1000) / 1000 * size.width
            let y = CGFloat((index * 173 + 41) % 700) / 700 * size.height
            let opacity = 0.22 + 0.22 * abs(sin(phase / 2.8 + Double(index)))
            let radius = CGFloat(2 + index % 3)
            fillEllipse(
                &context,
                rect: CGRect(x: x, y: y, width: radius, height: radius),
                color: .white.opacity(opacity)
            )
        }
    }

    private func drawLightning(_ context: inout GraphicsContext, size: CGSize) {
        let pulse = max(0, sin(phase / 7.5))
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(.white.opacity(pulse * pulse * 0.22))
        )
    }

    private func fillEllipse(
        _ context: inout GraphicsContext,
        rect: CGRect,
        color: Color
    ) {
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }
}
