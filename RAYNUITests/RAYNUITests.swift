import XCTest

final class RAYNUITests: XCTestCase {
    private var app: XCUIApplication!
    private let remote = XCUIRemote.shared

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testDailyForecastSupportsRemoteSelectionAndDetail() throws {
        launch(scene: "daily")
        guard app.staticTexts["延展预报"].waitForExistence(timeout: 30) else {
            throw XCTSkip("实时天气服务未能在测试时限内返回数据")
        }

        let firstDay = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH '第 1 天'")
        ).firstMatch
        XCTAssertTrue(firstDay.waitForExistence(timeout: 3))
        XCTAssertTrue(waitForFocus(on: firstDay), "10 天页面应默认聚焦第一天")
        keepScreenshot(named: "10-day-list")

        remote.press(.down)
        remote.press(.down)
        remote.press(.down)

        let fourthDay = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH '第 4 天'")
        ).firstMatch
        XCTAssertTrue(fourthDay.waitForExistence(timeout: 3))
        XCTAssertTrue(waitForFocus(on: fourthDay), "向下三次应聚焦第 4 天")

        remote.press(.select)
        XCTAssertTrue(
            app.staticTexts["第 4 天详细天气"].waitForExistence(timeout: 3),
            "确定键应打开第 4 天详情"
        )
        XCTAssertTrue(waitForFocus(on: app.buttons["收起"]), "详情页应把焦点放在明确的返回按钮上")
        keepScreenshot(named: "day-4-detail")

        remote.press(.menu)
        XCTAssertTrue(app.staticTexts["延展预报"].waitForExistence(timeout: 3))
        XCTAssertTrue(waitForFocus(on: fourthDay), "返回列表后应恢复到第 4 天")

        for ordinal in 5...10 {
            remote.press(.down)
            let day = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH %@", "第 \(ordinal) 天")
            ).firstMatch
            XCTAssertTrue(waitForFocus(on: day), "向下移动时应稳定聚焦第 \(ordinal) 天")
        }
        keepScreenshot(named: "10-day-last-row-focus")

        for ordinal in stride(from: 9, through: 1, by: -1) {
            remote.press(.up)
            let day = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH %@", "第 \(ordinal) 天")
            ).firstMatch
            XCTAssertTrue(waitForFocus(on: day), "向上移动时应稳定聚焦第 \(ordinal) 天")
        }

        remote.press(.menu)
        XCTAssertTrue(app.staticTexts["当前天气"].waitForExistence(timeout: 3), "列表页按返回应回到主天气")
    }

    func testHourlyDailyAndRadarSceneHandoffRemainsResponsive() throws {
        launch(scene: "hourly")
        guard app.staticTexts["趋势预报"].waitForExistence(timeout: 30) else {
            throw XCTSkip("实时天气服务未能在测试时限内返回数据")
        }

        let dailyTab = app.buttons["未来10天"]
        XCTAssertTrue(dailyTab.waitForExistence(timeout: 3))
        XCTAssertTrue(focusNavigationButton(titled: "未来10天"))
        remote.press(.select)
        XCTAssertTrue(app.staticTexts["延展预报"].waitForExistence(timeout: 3))

        let radarTab = app.buttons["降水雷达"]
        XCTAssertTrue(radarTab.waitForExistence(timeout: 3))
        XCTAssertTrue(focusNavigationButton(titled: "降水雷达"))
        remote.press(.select)
        XCTAssertTrue(app.staticTexts["雷达监测"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["环境"].exists, "雷达切换期间不应错误提交空气质量场景")
        keepScreenshot(named: "radar-scene")
    }

    func testRepeatedTraversalAcrossAllScenesKeepsAppAlive() throws {
        launch(scene: "current")
        guard app.staticTexts["当前天气"].waitForExistence(timeout: 30) else {
            throw XCTSkip("实时天气服务未能在测试时限内返回数据")
        }

        let astronomyTitle = astronomyNavigationTitle
        let forward = [
            ("此刻", "当前天气"),
            ("24小时", "趋势预报"),
            ("未来10天", "延展预报"),
            ("降水雷达", "雷达监测"),
            ("空气质量", "环境"),
            (astronomyTitle, "未来7天月相")
        ]

        for pass in 0..<3 {
            let route = pass.isMultiple(of: 2) ? forward : Array(forward.reversed())
            for (title, marker) in route {
                XCTAssertTrue(focusNavigationButton(titled: title), "应能聚焦 \(title)")
                remote.press(.select)
                XCTAssertTrue(
                    app.staticTexts[marker].waitForExistence(timeout: 3),
                    "切换到 \(title) 后应显示对应页面"
                )
                XCTAssertEqual(app.state, .runningForeground, "连续切换时应用不应退出")
            }
        }

        keepScreenshot(named: "scene-traversal-stress")
    }

    func testSettingsButtonOpensFullScreenControls() throws {
        launch(scene: "daily")
        guard app.staticTexts["延展预报"].waitForExistence(timeout: 30) else {
            throw XCTSkip("实时天气服务未能在测试时限内返回数据")
        }

        XCTAssertFalse(app.staticTexts["自动轮播"].exists, "主页不应常驻显示自动轮播注释")
        XCTAssertTrue(focusNavigationButton(titled: astronomyNavigationTitle))
        keepScreenshot(named: "navigation-focus-safe-area")
        remote.press(.up)

        let settingsButton = app.buttons["设置"]
        XCTAssertTrue(waitForFocus(on: settingsButton), "导航栏向上应能到达设置按钮")
        remote.press(.select)

        XCTAssertTrue(app.staticTexts["演播室设置"].waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.descendants(matching: .any)["自动轮播天气场景"].exists,
            "设置页应提供明确的自动轮播开关"
        )
        keepScreenshot(named: "full-screen-settings")

        remote.press(.menu)
        XCTAssertTrue(app.staticTexts["延展预报"].waitForExistence(timeout: 3))
    }

    func testAstronomyShowsSunMoonAndOnlyUsesMarineSpaceWhenAvailable() throws {
        launch(scene: "astronomy")
        guard app.staticTexts["未来7天月相"].waitForExistence(timeout: 30) else {
            throw XCTSkip("实时天气服务未能在测试时限内返回数据")
        }

        XCTAssertTrue(app.staticTexts["太阳"].exists)
        XCTAssertTrue(app.staticTexts["月相"].exists)
        let marineSummary = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "海况 ·")
        ).firstMatch
        let titleWithMarine = app.staticTexts["日照、月相与海况"]
        let titleWithoutMarine = app.staticTexts["日照与月相"]

        XCTAssertNotEqual(
            titleWithMarine.exists,
            titleWithoutMarine.exists,
            "日月页应且仅应显示一个与数据状态匹配的标题"
        )
        XCTAssertEqual(
            titleWithMarine.exists,
            marineSummary.exists,
            "页面标题和海况摘要应同时随真实海况数据出现或隐藏"
        )
        keepScreenshot(named: titleWithMarine.exists ? "astronomy-with-marine-strip" : "astronomy-inland")
    }

    private func launch(scene: String) {
        app.launchArguments = ["--rayn-scene=\(scene)"]
        app.launch()
    }

    private func waitForFocus(on element: XCUIElement, timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "hasFocus == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func focusNavigationButton(titled targetTitle: String) -> Bool {
        let titles = ["此刻", "24小时", "未来10天", "降水雷达", "空气质量", astronomyNavigationTitle]
        let target = app.buttons[targetTitle]
        if target.hasFocus { return true }

        // Forecast content owns focus by default. Move upward into the full-
        // width navigation focus section, then traverse the tabs exactly as a
        // Siri Remote user does.
        for _ in 0..<3 where focusedNavigationIndex(in: titles) == nil {
            remote.press(.up)
        }
        if focusedNavigationIndex(in: titles) == nil {
            for _ in 0..<3 where focusedNavigationIndex(in: titles) == nil {
                remote.press(.down)
            }
        }

        guard let currentIndex = focusedNavigationIndex(in: titles),
              let targetIndex = titles.firstIndex(of: targetTitle) else { return false }
        let distance = targetIndex - currentIndex
        if distance > 0 {
            for _ in 0..<distance { remote.press(.right) }
        } else if distance < 0 {
            for _ in 0..<(-distance) { remote.press(.left) }
        }
        return waitForFocus(on: target)
    }

    private func focusedNavigationIndex(in titles: [String]) -> Int? {
        titles.firstIndex { app.buttons[$0].hasFocus }
    }

    private var astronomyNavigationTitle: String {
        app.buttons["日月海况"].exists ? "日月海况" : "日照月相"
    }

    private func keepScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
