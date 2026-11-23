import SwiftUI

// Cuadro deportivo de iPhone. Escala visual 0–6.000 RPM, no régimen seguro del motor.
// Las cifras mostradas proceden de ELMReading (OBD real) o del modo DEMO etiquetado.
private enum SportColors {
    static let background = Color(red: 0.025, green: 0.040, blue: 0.065)
    static let panel = Color(red: 0.060, green: 0.095, blue: 0.130)
    static let line = Color(red: 0.16, green: 0.23, blue: 0.29)
    static let red = Color(red: 0.95, green: 0.23, blue: 0.26)
    static let muted = Color(red: 0.57, green: 0.66, blue: 0.74)
}

private enum RPMScale {
    static let maximum = 6000.0
    static let redlineDisplay = 5000.0
}

private struct DialArc: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let bounded = max(0, min(1, progress))
        guard bounded > 0 else { return Path() }
        let side = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = side * 0.437
        let segments = max(1, Int(180 * bounded))
        var result = Path()
        for index in 0...segments {
            let degrees = 220 + 280 * bounded * Double(index) / Double(segments)
            let radians = degrees * .pi / 180
            let point = CGPoint(x: center.x + radius * sin(radians),
                                y: center.y - radius * cos(radians))
            if index == 0 { result.move(to: point) } else { result.addLine(to: point) }
        }
        return result
    }
}

struct PerformanceRPMDial: View {
    let rpm: Double?

    private func position(for degrees: Double, radius: CGFloat, side: CGFloat) -> CGPoint {
        let radians = degrees * .pi / 180
        return CGPoint(x: side / 2 + radius * sin(radians),
                       y: side / 2 - radius * cos(radians))
    }

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let progress = max(0, min(1, (rpm ?? 0) / RPMScale.maximum))
            ZStack {
                DialArc(progress: 1)
                    .stroke(SportColors.line, style: StrokeStyle(lineWidth: max(7, side * 0.055), lineCap: .round))
                DialArc(progress: progress)
                    .stroke(SportColors.red, style: StrokeStyle(lineWidth: max(7, side * 0.055), lineCap: .round))

                ForEach(0..<31, id: \.self) { tick in
                    let angle = 220 + 280 * Double(tick) / 30
                    let major = tick.isMultiple(of: 5)
                    Capsule()
                        .fill(tick >= 25 ? SportColors.red : SportColors.muted)
                        .frame(width: major ? 2.4 : 1.2, height: major ? side * 0.056 : side * 0.028)
                        .rotationEffect(.degrees(angle))
                        .position(position(for: angle, radius: side * 0.361, side: side))
                }

                ForEach(0...6, id: \.self) { number in
                    let angle = 220 + 280 * Double(number) / 6
                    Text(String(number))
                        .font(.system(size: max(10, side * 0.053), weight: .bold, design: .rounded))
                        .foregroundStyle(number >= 5 ? SportColors.red : SportColors.muted)
                        .position(position(for: angle, radius: side * 0.280, side: side))
                }

                VStack(spacing: 2) {
                    Text(rpm.map { String(format: "%.1f", $0 / 1000.0) } ?? "—")
                        .font(.system(size: side * 0.225, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("× 1000 RPM")
                        .font(.system(size: max(8, side * 0.045), weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(SportColors.muted)
                }
            }
            .frame(width: side, height: side)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Revoluciones del motor")
        .accessibilityValue(rpm.map { "\(Int($0)) revoluciones por minuto" } ?? "Sin datos")
    }
}

struct PerformanceDashboard: View {
    let readings: ELMReading
    let connected: Bool
    let demo: Bool
    let status: String

    var body: some View {
        GeometryReader { dimensions in
            let wide = dimensions.size.width > dimensions.size.height && dimensions.size.width > 550
            VStack(spacing: wide ? 7 : 10) {
                HStack(spacing: 8) {
                    Text("GOLF")
                        .foregroundStyle(.white)
                    Text("PERFORMANCE")
                        .foregroundStyle(SportColors.red)
                    Spacer(minLength: 5)
                    Text(demo ? "SIMULADO" : (connected ? "OBDII · BLE" : "SIN CONEXIÓN"))
                        .font(.system(size: wide ? 10 : 9, weight: .black))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background((demo ? Color.orange : (connected ? Color.green : SportColors.red)).opacity(0.18))
                        .clipShape(Capsule())
                }
                .font(.system(size: wide ? 14 : 13, weight: .black, design: .rounded))
                .tracking(0.8)

                if wide {
                    HStack(spacing: 8) {
                        rpmPanel
                        speedPanel
                        telemetryPanel
                    }
                } else {
                    HStack(spacing: 8) {
                        rpmPanel
                        speedPanel
                    }
                    telemetryPanel
                        .frame(height: 115)
                }
                HStack(spacing: 8) {
                    Circle()
                        .fill(connected ? Color.green : (demo ? Color.orange : SportColors.red))
                        .frame(width: 6, height: 6)
                    Text(status)
                        .lineLimit(1)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(SportColors.muted)
                    Spacer(minLength: 4)
                    Text("ESCALA RPM · 0–6.000")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(SportColors.muted)
                }
            }
            .padding(wide ? 10 : 12)
            .background(SportColors.background)
            .foregroundStyle(.white)
        }
    }

    private var rpmPanel: some View {
        VStack(spacing: 1) {
            Text("MOTOR / RPM")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(SportColors.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            PerformanceRPMDial(rpm: readings.rpm)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SportColors.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var speedPanel: some View {
        VStack(spacing: 3) {
            Text("VELOCIDAD / OBD")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(SportColors.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
            Text(readings.speedKmh.map { String(Int($0.rounded())) } ?? "—")
                .font(.system(size: 63, weight: .black, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.48)
            Text("KM/H")
                .font(.system(size: 12, weight: .heavy))
                .tracking(2)
                .foregroundStyle(SportColors.muted)
            Spacer(minLength: 0)
            Text("GOLF 7.5 · 1.6 TDI")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(SportColors.red)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(9)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SportColors.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var telemetryPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TELEMETRÍA / ECU")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(SportColors.muted)
            telemetryRow("REFRIGERANTE", readings.coolantC, "°C")
            telemetryRow("CARGA MOTOR", readings.loadPercent, "%")
            telemetryRow("PRESIÓN MAP", readings.mapKPa, "kPa")
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SportColors.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func telemetryRow(_ label: String, _ value: Double?, _ units: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(SportColors.muted)
            Spacer(minLength: 2)
            Text(value.map { String(Int($0.rounded())) } ?? "—")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .monospacedDigit()
            Text(units)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(SportColors.muted)
        }
    }
}

struct FullScreenPerformanceDashboard: View {
    @ObservedObject var model: PerformanceModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack {
                    Text("1.6 TDI · PANEL DEPORTIVO")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.gray)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Label("Cerrar", systemImage: "xmark.circle.fill")
                            .font(.caption.weight(.semibold))
                    }
                    .tint(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 5)

                PerformanceDashboard(readings: model.readings,
                                     connected: model.isConnected,
                                     demo: model.demo,
                                     status: model.status)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(SportColors.background)
            .preferredColorScheme(.dark)
        }
    }
}
