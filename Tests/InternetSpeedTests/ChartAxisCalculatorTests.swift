import XCTest
@testable import InternetSpeed

final class ChartAxisCalculatorTests: XCTestCase {

    // MARK: - calculateStride

    func testCalculateStrideUnder10Minutes() {
        let result = ChartAxisCalculator.calculateStride(duration: 5 * 60)
        XCTAssertEqual(result.component, .minute)
        XCTAssertEqual(result.count, 2)
    }

    func testCalculateStride15Minutes() {
        let result = ChartAxisCalculator.calculateStride(duration: 15 * 60)
        XCTAssertEqual(result.component, .minute)
        XCTAssertEqual(result.count, 5)
    }

    func testCalculateStride45Minutes() {
        let result = ChartAxisCalculator.calculateStride(duration: 45 * 60)
        XCTAssertEqual(result.component, .minute)
        XCTAssertEqual(result.count, 15)
    }

    func testCalculateStride90Minutes() {
        let result = ChartAxisCalculator.calculateStride(duration: 90 * 60)
        XCTAssertEqual(result.component, .minute)
        XCTAssertEqual(result.count, 30)
    }

    func testCalculateStride3Hours() {
        let result = ChartAxisCalculator.calculateStride(duration: 3 * 3600)
        XCTAssertEqual(result.component, .hour)
        XCTAssertEqual(result.count, 1)
    }

    func testCalculateStride8Hours() {
        let result = ChartAxisCalculator.calculateStride(duration: 8 * 3600)
        XCTAssertEqual(result.component, .hour)
        XCTAssertEqual(result.count, 2)
    }

    func testCalculateStride24Hours() {
        let result = ChartAxisCalculator.calculateStride(duration: 25 * 3600)
        XCTAssertEqual(result.component, .hour)
        XCTAssertEqual(result.count, 12, "25 hours should stride by 12 hours based on new logic")
    }

    // MARK: - roundedAxisDates

    func testRoundedDatesSnapToCleanMinuteBoundaries() {
        let calendar = Calendar.current
        // 10:03 to 10:47 — stride should be 15 min, ticks at :45, :00, :15, :30, :45, :00 (padded)
        var start = DateComponents()
        start.year = 2026; start.month = 1; start.day = 1
        start.hour = 10; start.minute = 3
        var end = start
        end.minute = 47

        let dates = ChartAxisCalculator.roundedAxisDates(
            from: calendar.date(from: start)!,
            to: calendar.date(from: end)!
        )

        let minutes = dates.map { calendar.component(.minute, from: $0) }
        // The algorithm pads 1 tick before the floored start, and 1 tick after the ceiled end.
        // Floored start: 10:00. Padded start: 9:45
        // Ceiled end: 11:00. Padded end: 11:00 (since 10:47 <= 11:00 is technically bounded)
        // Wait, ceiledEnd calculation: date(byAdding: 15min, to: 10:47) = 11:02. So while tick <= 11:02.
        // Ticks will be: 9:45, 10:00, 10:15, 10:30, 10:45, 11:00.
        // The minutes will be: [45, 0, 15, 30, 45, 0]
        XCTAssertEqual(minutes, [45, 0, 15, 30, 45, 0])
    }
    
    func testRoundedDatesSnapToCleanHourBoundaries() {
        let calendar = Calendar.current
        // 13:10 to 19:20 — duration is 6h10m (370 min). Stride > 4 hours is (.hour, 2).
        var start = DateComponents()
        start.year = 2026; start.month = 1; start.day = 1
        start.hour = 13; start.minute = 10
        var end = start
        end.hour = 19; end.minute = 20

        let dates = ChartAxisCalculator.roundedAxisDates(
            from: calendar.date(from: start)!,
            to: calendar.date(from: end)!
        )

        let hours = dates.map { calendar.component(.hour, from: $0) }
        // Floored start: 12:00. Padded start: 10:00
        // End is 19:20. Ceiled end is 21:20 (date + 2h).
        // Ticks: 10, 12, 14, 16, 18, 20
        XCTAssertEqual(hours, [10, 12, 14, 16, 18, 20])
        
        let minutes = dates.map { calendar.component(.minute, from: $0) }
        XCTAssertTrue(minutes.allSatisfy { $0 == 0 })
    }

    func testRoundedDatesEmptyForSinglePoint() {
        let now = Date()
        let dates = ChartAxisCalculator.roundedAxisDates(from: now, to: now)
        XCTAssertTrue(dates.isEmpty)
    }
}
