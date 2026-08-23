import Foundation

public struct SessionConfiguration: Equatable, Sendable {
    public let liftDuration: Int
    public let releaseDuration: Int
    public let repetitionCount: Int

    public init() {
        liftDuration = 3
        releaseDuration = 3
        repetitionCount = 8
    }

    public var totalDuration: Int {
        (liftDuration + releaseDuration) * repetitionCount
    }
}
