import Foundation

struct ChartAxisCalculator {
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
}
