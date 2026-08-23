import ClockKit
import Foundation

public final class PipComplicationDataSource: NSObject, CLKComplicationDataSource {
    public func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        let snapshot = WatchSurfaceSnapshotReader().read()
        let template = makeTemplate(for: complication.family, snapshot: snapshot)
        handler(template.map { CLKComplicationTimelineEntry(date: Date(), complicationTemplate: $0) })
    }

    public func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void
    ) {
        handler(makeTemplate(for: complication.family, snapshot: nil))
    }

    public func getNextRequestedUpdateDate(
        withHandler handler: @escaping (Date?) -> Void
    ) {
        handler(Date().addingTimeInterval(15 * 60))
    }

    private func makeTemplate(
        for family: CLKComplicationFamily,
        snapshot: PipSnapshot?
    ) -> CLKComplicationTemplate? {
        let count = snapshot?.todayCompletedCount ?? 0
        let countText = CLKSimpleTextProvider(text: "\(count)")
        let labelText = CLKSimpleTextProvider(text: snapshot == nil ? "Pip" : "Today")

        switch family {
        case .circularSmall:
            return CLKComplicationTemplateCircularSmallSimpleText(textProvider: countText)
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularStackText(
                line1TextProvider: labelText,
                line2TextProvider: countText
            )
        case .graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "Pip"),
                body1TextProvider: CLKSimpleTextProvider(text: "Today \(count)"),
                body2TextProvider: CLKSimpleTextProvider(text: snapshot == nil ? "Unavailable" : "Completed")
            )
        default:
            return nil
        }
    }
}
