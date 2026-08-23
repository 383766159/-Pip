import Foundation
import WidgetKit

public struct PipWidgetEntry: TimelineEntry {
    public let date: Date
    public let surface: WidgetSurfaceSnapshot

    public init(date: Date, surface: WidgetSurfaceSnapshot) {
        self.date = date
        self.surface = surface
    }
}
