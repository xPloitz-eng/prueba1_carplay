import Foundation
import Combine
import ActivityKit

@MainActor
final class PerformanceModel: ObservableObject {
    @Published var devices: [BLEDevice] = []
    @Published var status = "Desconectado"
    @Published var readings = ELMReading()
    @Published var messages: [String] = []
    @Published var isConnected = false
    @Published var demo = false
    @Published var liveStatus = "No iniciada"
    @Published var liveEnabled = false
    @Published var liveIntervalSeconds = 3
    @Published var host = "192.168.0.10"
    @Published var port = "35000"

    private var transport: ELMTransport?
    private var ble: BLEELMTransport?
    private var queue = ["ATZ", "ATE0", "ATL0", "ATS0", "ATH0", "ATSP0"]
    private var pollIndex = 0
    private let pollCommands = ["010C", "010D", "010C", "0105", "010C", "0104", "010C", "010B", "010F", "0133"]
    private var pending: String?
    private var sentAt: Date = .distantPast
    private var buffer = ""
    private var timer: Timer?
    private var demoTicks = 0
    private var lastLiveSend = Date.distantPast
    private var liveActivity: Activity<GolfPerformanceAttributes>?

    func scanBLE() {
        disconnect()
        let link = BLEELMTransport()
        attach(link)
        ble = link
        link.onDevices = { [weak self] list in self?.devices = list }
        link.scan()
    }

    func connectBLE(_ id: UUID) {
        guard let ble else { status = "Primero pulsa Buscar Bluetooth"; return }
        ble.connect(id: id)
    }

    func connectWiFi() {
        let target = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty, let numericPort = UInt16(port), numericPort > 0 else {
            status = "Introduce IP y puerto válidos"; return
        }
        disconnect()
        let link = WiFiELMTransport()
        attach(link)
        link.connect(host: target, port: numericPort)
    }

    private func attach(_ link: ELMTransport) {
        transport = link
        link.onStatus = { [weak self] message in
            self?.status = message
            self?.log(message)
        }
        link.onReady = { [weak self] in self?.beginSession() }
        link.onData = { [weak self] text in self?.receive(text) }
    }

    private func beginSession() {
        demo = false
        isConnected = true
        readings = ELMReading()
        status = "Inicializando ECU…"
        pending = nil
        buffer = ""
        pollIndex = 0
        queue = ["ATZ", "ATE0", "ATL0", "ATS0", "ATH0", "ATSP0"]
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        tick()
    }

    func startDemo() {
        disconnect()
        demo = true
        isConnected = false
        status = "DEMO — valores simulados"
        readings = ELMReading()
        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.demoStep() }
        }
        demoStep()
    }

    private func demoStep() {
        demoTicks += 1
        let x = Double(demoTicks) / 5
        readings.rpm = 900 + abs(sin(x)) * 1800
        readings.speedKmh = 30 + abs(sin(x / 2)) * 75
        readings.coolantC = 87 + sin(x / 5) * 3
        readings.loadPercent = 25 + abs(sin(x / 3)) * 50
        readings.mapKPa = 95 + abs(sin(x)) * 60
        readings.intakeC = 24
        readings.barometricKPa = 101
        readings.lastUpdate = .now
    }

    private func tick() {
        guard isConnected, !demo, transport != nil else { return }
        if let p = pending {
            let deadline = p == "ATZ" ? 4.0 : 2.0
            if Date().timeIntervalSince(sentAt) > deadline {
                log("Tiempo agotado: \(p)")
                pending = nil
                buffer = ""
            } else { return }
        }
        let next: String
        if !queue.isEmpty { next = queue.removeFirst() }
        else {
            next = pollCommands[pollIndex]
            pollIndex = (pollIndex + 1) % pollCommands.count
        }
        pending = next
        sentAt = .now
        transport?.send(next)
        if let updated = readings.lastUpdate, Date().timeIntervalSince(updated) > 8 {
            status = "Sin lecturas recientes del motor"
        }
    }

    private func receive(_ fragment: String) {
        guard isConnected else { return }
        buffer += fragment
        if buffer.count > 16384 { buffer = String(buffer.suffix(1000)) }
        while let marker = buffer.firstIndex(of: ">") {
            let reply = String(buffer[..<marker])
            buffer = String(buffer[buffer.index(after: marker)...])
            guard let p = pending else { continue }
            if p.hasPrefix("01") {
                if readings.ingest(command: p, response: reply) {
                    status = "ELM conectado · datos reales"
                    maybePublishLive()
                } else if reply.uppercased().contains("NO DATA") {
                    log("\(p): NO DATA (PID no admitido)")
                }
            } else if reply.uppercased().contains("ERROR") {
                log("\(p): \(reply.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
            pending = nil
            tick()
        }
    }

    private func log(_ message: String) {
        messages.insert(message, at: 0)
        if messages.count > 35 { messages.removeLast() }
    }

    func disconnect() {
        timer?.invalidate()
        timer = nil
        transport?.stop()
        transport = nil
        ble = nil
        pending = nil
        buffer = ""
        isConnected = false
        demo = false
        devices = []
        status = "Desconectado"
    }

    func startLive() {
        guard isConnected && !demo else { liveStatus = "Conecta primero el ELM real"; return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            liveStatus = "Activa Actividades en directo para Golf Performance en Ajustes"
            return
        }
        Task {
            do {
                let attr = GolfPerformanceAttributes(name: "Golf 7.5 1.6 TDI")
                let content = ActivityContent(state: liveState(), staleDate: .now.addingTimeInterval(20))
                liveActivity = try Activity.request(attributes: attr, content: content, pushType: nil)
                liveEnabled = true
                lastLiveSend = .distantPast
                liveStatus = "Live Activity iniciada · CarPlay experimental"
                maybePublishLive()
            } catch {
                liveStatus = "No se pudo iniciar: \(error.localizedDescription)"
            }
        }
    }

    private func liveState() -> GolfPerformanceAttributes.ContentState {
        GolfPerformanceAttributes.ContentState(
            rpm: readings.rpm.map { Int($0.rounded()) },
            speedKmh: readings.speedKmh.map { Int($0.rounded()) },
            coolantC: readings.coolantC.map { Int($0.rounded()) },
            updated: readings.lastUpdate ?? .now
        )
    }

    private func maybePublishLive() {
        // El iPhone procesa OBD lo más rápido que puede; ActivityKit no es un HUD.
        // Intervalo solicitado de prueba (2–15 s): iOS puede retrasar o limitar su presentación.
        guard liveEnabled, let activity = liveActivity,
              Date().timeIntervalSince(lastLiveSend) >= Double(liveIntervalSeconds) else { return }
        lastLiveSend = .now
        let state = liveState()
        Task { await activity.update(ActivityContent(state: state, staleDate: .now.addingTimeInterval(20))) }
    }

    func stopLive() {
        liveEnabled = false
        let a = liveActivity
        liveActivity = nil
        liveStatus = "Live Activity detenida"
        Task { await a?.end(nil, dismissalPolicy: .immediate) }
    }
}
