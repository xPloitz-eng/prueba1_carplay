import Foundation
import ActivityKit

struct GolfPerformanceAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var rpm: Int?
        var speedKmh: Int?
        var coolantC: Int?
        var updated: Date
    }

    var name: String
}
