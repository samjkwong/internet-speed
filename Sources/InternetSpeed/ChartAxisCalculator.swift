import Foundation

struct ChartAxisCalculator {
    /// Returns the ideal calendar component and interval count based on duration
    static func calculateStride(duration: TimeInterval) -> (component: Calendar.Component, count: Int) {
        let minutes = duration / 60
        
        if minutes > 12 * 60 {
            return (.hour, 4)
        } else if minutes > 4 * 60 {
            return (.hour, 2)
        } else if minutes > 2 * 60 {
            return (.hour, 1)
        } else if minutes > 60 {
            return (.minute, 30)
        } else if minutes > 30 {
            return (.minute, 15)
        } else if minutes > 10 {
            return (.minute, 5)
        } else {
            return (.minute, 2)
        }
    }

    /// Returns rounded Date values for x-axis ticks that fall on clean boundaries
    /// (e.g. :00, :15, :30, :45 for minute-based intervals).
    static func roundedAxisDates(from startDate: Date, to endDate: Date) -> [Date] {
        let duration = endDate.timeIntervalSince(startDate)
        guard duration > 0 else { return [] }
        
        let stride = calculateStride(duration: duration)
        let calendar = Calendar.current
        
        // Round start down to the nearest stride boundary
        var startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
        startComponents.second = 0
        
        if stride.component == .hour {
            startComponents.minute = 0
            if let hour = startComponents.hour {
                startComponents.hour = (hour / stride.count) * stride.count
            }
        } else {
            if let minute = startComponents.minute {
                startComponents.minute = (minute / stride.count) * stride.count
            }
        }
        
        guard let firstTick = calendar.date(from: startComponents) else { return [] }
        
        let ceiledEnd = calendar.date(byAdding: stride.component, value: stride.count, to: endDate) ?? endDate
        var tick = calendar.date(byAdding: stride.component, value: -stride.count, to: firstTick) ?? firstTick
        
        var dates: [Date] = []
        while tick <= ceiledEnd {
            dates.append(tick)
            
            guard let nextTick = calendar.date(byAdding: stride.component, value: stride.count, to: tick) else { break }
            if nextTick == tick { break } // Stop infinite loops if date math fails
            tick = nextTick
        }
        
        return dates
    }
}
