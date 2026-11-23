import Foundation

// Protocol PIDs OBD-II modo 01. Solo valores proporcionados por la ECU.
// No calcula consumo ni boost absoluto sin datos adicionales verificables.
struct ELMReading: Equatable {
    var rpm: Double?
    var speedKmh: Double?
    var coolantC: Double?
    var loadPercent: Double?
    var mapKPa: Double?
    var intakeC: Double?
    var barometricKPa: Double?
    var lastUpdate: Date?

    mutating func ingest(command: String, response: String, now: Date = .now) -> Bool {
        let pid = String(command.uppercased().suffix(2))
        guard let bytes = Self.responseBytes(pid: pid, text: response) else { return false }
        guard let a = bytes.first else { return false }
        switch pid {
        case "0C":
            guard bytes.count >= 2 else { return false }
            rpm = Double(a * 256 + bytes[1]) / 4.0
        case "0D": speedKmh = Double(a)
        case "05": coolantC = Double(a) - 40
        case "04": loadPercent = Double(a) * 100 / 255
        case "0B": mapKPa = Double(a)
        case "0F": intakeC = Double(a) - 40
        case "33": barometricKPa = Double(a)
        default: return false
        }
        lastUpdate = now
        return true
    }

    // Extrae 41 PID AA [BB] desde líneas ELM con o sin espacios / headers CAN.
    // No confundir una solicitud 01 PID con la respuesta 41 PID.
    static func responseBytes(pid: String, text: String) -> [Int]? {
        for rawLine in text.uppercased().components(separatedBy: .newlines) {
            let hex = rawLine.filter { $0.isHexDigit }
            let token = "41" + pid
            guard let range = hex.range(of: token) else { continue }
            let rest = String(hex[range.upperBound...])
            let pairCount = rest.count / 2
            guard pairCount > 0 else { continue }
            let chars = Array(rest)
            var result: [Int] = []
            for i in 0..<min(pairCount, 8) {
                let pair = String(chars[2 * i...2 * i + 1])
                guard let value = Int(pair, radix: 16) else { break }
                result.append(value)
            }
            if !result.isEmpty { return result }
        }
        return nil
    }
}
