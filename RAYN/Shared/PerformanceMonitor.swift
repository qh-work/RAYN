import os

/// Shared Instruments signposts for the interactions that historically cost
/// the most on A12 Apple TV hardware. The signposts are inert when collection
/// is disabled and contain no location or weather payloads.
enum RAYNPerformance {
    private static let signposter = OSSignposter(
        subsystem: "com.rayn.weather.tv",
        category: "Performance"
    )
    private static let logger = Logger(
        subsystem: "com.rayn.weather.tv",
        category: "Performance"
    )

    static func beginSceneTransition(from: BroadcastScene, to: BroadcastScene) -> OSSignpostIntervalState {
        logger.debug("Scene transition: \(from.rawValue, privacy: .public) -> \(to.rawValue, privacy: .public)")
        return signposter.beginAnimationInterval("Scene Transition")
    }

    static func endSceneTransition(_ state: OSSignpostIntervalState) {
        signposter.endInterval("Scene Transition", state)
    }

    static func beginRefresh(force: Bool) -> OSSignpostIntervalState {
        logger.debug("Weather refresh, forced: \(force, privacy: .public)")
        return signposter.beginInterval("Weather Refresh")
    }

    static func endRefresh(_ state: OSSignpostIntervalState) {
        signposter.endInterval("Weather Refresh", state)
    }

    static func radarMapReady() {
        signposter.emitEvent("Radar Map Ready")
    }

    static func radarFramePresented() {
        signposter.emitEvent("Radar Frame Presented")
    }
}
