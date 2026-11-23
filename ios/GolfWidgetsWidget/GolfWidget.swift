import SwiftUI
import WidgetKit

struct GolfEntry: TimelineEntry {
    let date: Date
}

struct GolfTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> GolfEntry { GolfEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (GolfEntry) -> Void) {
        completion(GolfEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GolfEntry>) -> Void) {
        let now = Date()
        completion(Timeline(entries: [GolfEntry(date: now)],
                            policy: .after(now.addingTimeInterval(15 * 60))))
    }
}

struct GolfSportWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GolfSportWidget", provider: GolfTimelineProvider()) { entry in
            GolfCardView(design: GolfDesign.preset(theme: "sport"), date: entry.date)
                .containerBackground(for: .widget) {
                    Color(golfHex: GolfDesign.preset(theme: "sport").background)
                }
        }
        .configurationDisplayName("Golf deportivo")
        .description("Diseño deportivo para Golf 7.5.")
        .supportedFamilies([.systemSmall])
        .containerBackgroundRemovable(false)
    }
}

struct GolfCustomWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GolfCustomWidget", provider: GolfTimelineProvider()) { entry in
            GolfCardView(design: GolfDesign.preset(theme: "custom"), date: entry.date)
                .containerBackground(for: .widget) {
                    Color(golfHex: GolfDesign.preset(theme: "custom").background)
                }
        }
        .configurationDisplayName("Golf personalizado")
        .description("Diseño totalmente personalizable.")
        .supportedFamilies([.systemSmall])
        .containerBackgroundRemovable(false)
    }
}

@main
struct GolfWidgetsBundle: WidgetBundle {
    var body: some Widget {
        GolfSportWidget()
        GolfCustomWidget()
        GolfLiveActivityWidget()
    }
}
