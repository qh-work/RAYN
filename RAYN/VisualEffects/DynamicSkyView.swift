import SwiftUI

struct DynamicSkyView: View {
    let theme: WeatherTheme
    let isDay: Bool
    let intensity: DynamicIntensity
    let reduceMotion: Bool
    let lightningEnabled: Bool

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(paused: reduceMotion)) { context in
                let seconds = context.date.timeIntervalSinceReferenceDate
                let drift = reduceMotion ? 0 : sin(seconds / 18) * 3
                ZStack {
                    LinearGradient(colors: theme.colors(isDay: isDay), startPoint: .topLeading, endPoint: .bottomTrailing)

                    if !isDay {
                        StarField(count: intensity == .low ? 28 : 58, phase: seconds)
                    }
                    if theme == .clearDay {
                        SunGlowLayer(phase: seconds)
                    }
                    if theme.cloudDensity > 0 {
                        CloudLayer(phase: seconds, density: theme.cloudDensity)
                    }
                    if theme.hasRain {
                        RainLayer(count: intensity.particleCount, phase: seconds, strength: theme.rainStrength)
                    }
                    if theme.hasSnow {
                        SnowLayer(count: intensity.particleCount, phase: seconds)
                    }
                    if theme.hasFog {
                        FogLayer(phase: seconds)
                    }
                    if theme.hasHaze {
                        HazeLayer(phase: seconds)
                    }
                    if theme.hasHail {
                        HailLayer(count: max(12, intensity.particleCount / 2), phase: seconds)
                    }
                    if theme == .freezingRain {
                        IceSparkleLayer(count: max(10, intensity.particleCount / 3), phase: seconds)
                    }
                    if theme == .storm && lightningEnabled && !reduceMotion {
                        LightningLayer(phase: seconds)
                    }

                    LinearGradient(colors: [.black.opacity(0.03), .black.opacity(0.26)], startPoint: .top, endPoint: .bottom)
                        .allowsHitTesting(false)
                }
                .frame(width: geometry.size.width + 8, height: geometry.size.height + 8)
                .offset(x: drift, y: drift / 2)
            }
        }
        .ignoresSafeArea()
    }
}

private struct SunGlowLayer: View {
    let phase: TimeInterval

    var body: some View {
        GeometryReader { geometry in
            let drift = CGFloat(sin(phase / 30) * 18)
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
                .position(x: geometry.size.width * 0.78 + drift, y: geometry.size.height * 0.15)
        }
        .allowsHitTesting(false)
    }
}

private struct StarField: View {
    let count: Int
    let phase: TimeInterval

    var body: some View {
        Canvas { context, size in
            for index in 0..<count {
                let x = CGFloat((index * 71 + 19) % 1000) / 1000 * size.width
                let y = CGFloat((index * 137 + 31) % 630) / 630 * size.height * 0.72
                let twinkle = 0.30 + 0.22 * abs(sin(phase / 2.5 + Double(index)))
                let radius = CGFloat(1 + index % 3)
                let rect = CGRect(x: x, y: y, width: radius, height: radius)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(twinkle)))
            }
        }
        .allowsHitTesting(false)
    }
}

private struct CloudLayer: View {
    let phase: TimeInterval
    let density: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                cloudCluster(width: geometry.size.width * 0.58, height: 170, opacity: 0.17)
                    .position(x: geometry.size.width * 0.20 + CGFloat(sin(phase / 24) * 18), y: geometry.size.height * 0.20)
                cloudCluster(width: geometry.size.width * 0.45, height: 132, opacity: 0.13)
                    .position(x: geometry.size.width * 0.73 + CGFloat(cos(phase / 29) * 22), y: geometry.size.height * 0.34)
                cloudCluster(width: geometry.size.width * 0.76, height: 190, opacity: 0.10)
                    .position(x: geometry.size.width * 0.50 + CGFloat(sin(phase / 35) * 15), y: geometry.size.height * 0.72)
            }
        }
        .blur(radius: 5)
        .opacity(density)
        .allowsHitTesting(false)
    }

    private func cloudCluster(width: CGFloat, height: CGFloat, opacity: Double) -> some View {
        ZStack {
            Ellipse().fill(.white.opacity(opacity)).frame(width: width * 0.8, height: height * 0.45)
            Ellipse().fill(.white.opacity(opacity * 1.25)).frame(width: width * 0.34, height: height * 0.65).offset(x: -width * 0.22, y: -height * 0.08)
            Ellipse().fill(.white.opacity(opacity * 1.1)).frame(width: width * 0.42, height: height * 0.74).offset(x: width * 0.16, y: -height * 0.12)
        }
    }
}

private struct RainLayer: View {
    let count: Int
    let phase: TimeInterval
    let strength: Double

    var body: some View {
        Canvas { context, size in
            for index in 0..<count {
                let baseX = CGFloat((index * 137 + 7) % 1000) / 1000 * size.width
                let baseY = CGFloat((index * 83 + 11) % 700) / 700 * size.height
                let speed = (90 + CGFloat(index % 8) * 18) * CGFloat(strength)
                let y = (baseY + CGFloat(phase.truncatingRemainder(dividingBy: 8)) * speed).truncatingRemainder(dividingBy: size.height + 100) - 80
                var path = Path()
                path.move(to: CGPoint(x: baseX, y: y))
                path.addLine(to: CGPoint(x: baseX - 18 * CGFloat(strength), y: y + (50 + CGFloat(index % 4) * 10) * CGFloat(strength)))
                context.stroke(path, with: .color(.white.opacity(0.16 + strength * 0.10)), lineWidth: CGFloat(1 + index % 2) * CGFloat(strength))
            }
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
    }
}

private struct SnowLayer: View {
    let count: Int
    let phase: TimeInterval

    var body: some View {
        Canvas { context, size in
            for index in 0..<count {
                let baseX = CGFloat((index * 97 + 23) % 1000) / 1000 * size.width
                let baseY = CGFloat((index * 193 + 13) % 800) / 800 * size.height
                let drift = sin(phase / 3 + Double(index)) * 32
                let speed = 28 + CGFloat(index % 7) * 7
                let y = (baseY + CGFloat(phase.truncatingRemainder(dividingBy: 12)) * speed).truncatingRemainder(dividingBy: size.height + 80) - 40
                let radius = CGFloat(2 + index % 5)
                let x = baseX + drift
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)), with: .color(.white.opacity(0.72)))
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FogLayer: View {
    let phase: TimeInterval

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Capsule().fill(.white.opacity(0.13)).frame(width: geometry.size.width * 0.90, height: 150)
                    .offset(x: CGFloat(sin(phase / 17) * 80), y: geometry.size.height * 0.30)
                Capsule().fill(.white.opacity(0.10)).frame(width: geometry.size.width * 0.75, height: 110)
                    .offset(x: CGFloat(cos(phase / 13) * 100), y: geometry.size.height * 0.55)
                Capsule().fill(.white.opacity(0.08)).frame(width: geometry.size.width * 0.88, height: 170)
                    .offset(x: CGFloat(sin(phase / 21) * 120), y: geometry.size.height * 0.78)
            }
            .blur(radius: 28)
        }
        .allowsHitTesting(false)
    }
}

private struct HazeLayer: View {
    let phase: TimeInterval

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle().fill(.orange.opacity(0.10)).frame(height: geometry.size.height * 0.34).offset(y: geometry.size.height * 0.38)
                Capsule().fill(.white.opacity(0.09)).frame(width: geometry.size.width * 0.82, height: 120).offset(x: CGFloat(sin(phase / 22) * 90), y: geometry.size.height * 0.58)
            }
            .blur(radius: 32)
        }
        .allowsHitTesting(false)
    }
}

private struct HailLayer: View {
    let count: Int
    let phase: TimeInterval

    var body: some View {
        Canvas { context, size in
            for index in 0..<count {
                let baseX = CGFloat((index * 149 + 43) % 1000) / 1000 * size.width
                let baseY = CGFloat((index * 97 + 29) % 800) / 800 * size.height
                let speed = 135 + CGFloat(index % 6) * 18
                let y = (baseY + CGFloat(phase.truncatingRemainder(dividingBy: 8)) * speed).truncatingRemainder(dividingBy: size.height + 80) - 40
                let sizeValue = CGFloat(3 + index % 4)
                context.fill(Path(ellipseIn: CGRect(x: baseX, y: y, width: sizeValue, height: sizeValue)), with: .color(.white.opacity(0.68)))
            }
        }
        .allowsHitTesting(false)
    }
}

private struct IceSparkleLayer: View {
    let count: Int
    let phase: TimeInterval

    var body: some View {
        Canvas { context, size in
            for index in 0..<count {
                let x = CGFloat((index * 113 + 17) % 1000) / 1000 * size.width
                let y = CGFloat((index * 173 + 41) % 700) / 700 * size.height
                let opacity = 0.22 + 0.22 * abs(sin(phase / 2.8 + Double(index)))
                let radius = CGFloat(2 + index % 3)
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)), with: .color(.white.opacity(opacity)))
            }
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
    }
}

private struct LightningLayer: View {
    let phase: TimeInterval

    var body: some View {
        let pulse = max(0, sin(phase / 7.5))
        Rectangle()
            .fill(.white.opacity(pulse * pulse * 0.22))
            .blendMode(.screen)
            .allowsHitTesting(false)
    }
}
