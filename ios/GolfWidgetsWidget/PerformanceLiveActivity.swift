import SwiftUI
import WidgetKit
import ActivityKit

struct GolfLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GolfPerformanceAttributes.self) { context in
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text("GOLF PERFORMANCE")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.red)
                    Spacer(minLength: 0)
                    Text("1.6 TDI · OBD")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.gray)
                }
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(context.state.rpm.map { String($0) } ?? "—")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .monospacedDigit()
                        Text("RPM · ESCALA 0–6.000")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.gray)
                    }
                    Spacer(minLength: 5)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(context.state.speedKmh.map { String($0) } ?? "—")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .monospacedDigit()
                        Text("KM/H")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.gray)
                    }
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(context.state.coolantC.map { "\($0)°" } ?? "—")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                        Text("REFRIG.")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.gray)
                    }
                }
                ProgressView(value: min(6000.0, max(0, Double(context.state.rpm ?? 0))), total: 6000)
                    .tint(.red)
                HStack {
                    Text("ZONA ROJA VISUAL: 5.000+")
                    Spacer()
                    Text(context.state.updated, style: .time)
                }
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.gray)
            }
            .foregroundStyle(.white)
            .padding(10)
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(.red)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("\(context.state.rpm.map { String($0) } ?? "—") rpm")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.speedKmh.map { String($0) } ?? "—") km/h")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Golf Performance · OBD2").font(.caption)
                }
            } compactLeading: {
                Text("\(context.state.rpm.map { String($0) } ?? "—")")
            } compactTrailing: {
                Text("\(context.state.speedKmh.map { String($0) } ?? "—")")
            } minimal: {
                Image(systemName: "car.fill")
            }
        }
    }
}
