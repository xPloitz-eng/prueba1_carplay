import Foundation

@main
struct ParserTests {
    static func main() {
        var reading = ELMReading()
        precondition(reading.ingest(command: "010C", response: "010C\r41 0C 1A F8\r"))
        precondition(reading.rpm == 1726)
        precondition(reading.ingest(command: "010D", response: "7E8 03 41 0D 64\r"))
        precondition(reading.speedKmh == 100)
        precondition(reading.ingest(command: "0105", response: "41057B"))
        precondition(reading.coolantC == 83)
        precondition(reading.ingest(command: "0104", response: "410480"))
        precondition(abs((reading.loadPercent ?? 0) - 50.196) < 0.01)
        precondition(reading.ingest(command: "010B", response: "41 0B 65"))
        precondition(reading.mapKPa == 101)
        precondition(!reading.ingest(command: "010C", response: "NO DATA"))
        precondition(!reading.ingest(command: "010C", response: "010C"))
        print("✅ 7 tests de respuestas ELM327 superados")
    }
}
