import XCTest
@testable import InternetSpeed

final class ChartAxisCalculatorTests: XCTestCase {
    
    func testCalculateStrideUnder10Minutes() {
        let duration: TimeInterval = 5 * 60 // 5 minutes
        let result = ChartAxisCalculator.calculateStride(duration: duration)
        XCTAssertEqual(result.component, .minute)
        XCTAssertEqual(result.count, 2)
    }

    func testCalculateStride15Minutes() {
        let duration: TimeInterval = 15 * 60 // 15 minutes (> 10)
        let result = ChartAxisCalculator.calculateStride(duration: duration)
        XCTAssertEqual(result.component, .minute)
        XCTAssertEqual(result.count, 5)
    }

    func testCalculateStride45Minutes() {
        let duration: TimeInterval = 45 * 60 // 45 minutes (> 30)
        let result = ChartAxisCalculator.calculateStride(duration: duration)
        XCTAssertEqual(result.component, .minute)
        XCTAssertEqual(result.count, 15)
    }

    func testCalculateStride90Minutes() {
        let duration: TimeInterval = 90 * 60 // 1.5 hours (> 60m)
        let result = ChartAxisCalculator.calculateStride(duration: duration)
        XCTAssertEqual(result.component, .minute)
        XCTAssertEqual(result.count, 30)
    }

    func testCalculateStride3Hours() {
        let duration: TimeInterval = 3 * 3600 // 3 hours (> 2h)
        let result = ChartAxisCalculator.calculateStride(duration: duration)
        XCTAssertEqual(result.component, .hour)
        XCTAssertEqual(result.count, 1)
    }

    func testCalculateStride8Hours() {
        let duration: TimeInterval = 8 * 3600 // 8 hours (> 4h)
        let result = ChartAxisCalculator.calculateStride(duration: duration)
        XCTAssertEqual(result.component, .hour)
        XCTAssertEqual(result.count, 2)
    }

    func testCalculateStride24Hours() {
        let duration: TimeInterval = 24 * 3600 // 24 hours (> 12h)
        let result = ChartAxisCalculator.calculateStride(duration: duration)
        XCTAssertEqual(result.component, .hour)
        XCTAssertEqual(result.count, 4)
    }
}
